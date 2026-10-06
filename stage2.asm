bits 16
org 0x7E00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [boot_drive], dl
    sti

    ; Enable A20 line (fast method via keyboard controller)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Switch to VGA mode 0x13 for kernel
    mov ax, 0x0013
    int 0x10

    ; Query a VBE linear framebuffer mode for its physical base address.
    mov ax, 0x4F01
    mov cx, 0x0118
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne vbe_error
    test word [vbe_mode_info], 0x0081
    jz vbe_error
    mov eax, [vbe_mode_info + 40]
    test eax, eax
    jz vbe_error
    mov [framebuffer_base], eax

    ; Set VBE mode 118h with the linear framebuffer enabled.
    mov ax, 0x4F02
    mov bx, 0x4118
    int 0x10
    cmp ax, 0x004F
    jne vbe_error

    mov si, kernel_dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc kernel_load_error

    cli
    lgdt [gdt_descriptor]
    
    ; Disable interrupts and prepare for protected mode
    in al, 0x21
    or al, 0xFF
    out 0x21, al
    in al, 0xA1
    or al, 0xFF
    out 0xA1, al
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode_entry

vbe_error:
    mov si, vbe_error_message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

kernel_load_error:
    mov si, error_message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

align 8
gdt_start:
    dq 0
    ; 32-bit code segment
    dq 0x00CF9A000000FFFF
    ; 32-bit data segment
    dq 0x00CF92000000FFFF
    ; 64-bit code segment
    dq 0x00A09A000000FFFF
    ; 64-bit data segment
    dq 0x00A092000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

kernel_dap:
    db 0x10, 0
    dw 64
    dw 0
    dw 0x1000
    dd 9
    dd 0

hzk_dap:
    db 0x10, 0
    dw 288
    dw 0
    dw 0x2000
    dd 73
    dd 0

boot_drive: db 0
error_message: db 'Kernel load error', 0
vbe_error_message: db 'VBE mode error', 0
framebuffer_base: dd 0
align 4
vbe_mode_info: times 256 db 0

; Page tables for 64-bit long mode (identity mapping)
align 4096
pml4_table: times 4096 db 0
pdpt_table: times 4096 db 0
pd_table: times 4096 db 0

bits 32
protected_mode_entry:
    cld
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Configure Bochs/QEMU VBE for a 1920x1080x32 linear framebuffer.
    mov dx, 0x01CE
    xor ax, ax
    out dx, ax
    inc dx
    in ax, dx
    cmp ax, 0xB0C5
    jne vbe_protected_error

    mov dx, 0x01CE
    mov ax, 4
    out dx, ax
    inc dx
    xor ax, ax
    out dx, ax

    mov dx, 0x01CE
    mov ax, 1
    out dx, ax
    inc dx
    mov ax, 1920
    out dx, ax

    mov dx, 0x01CE
    mov ax, 2
    out dx, ax
    inc dx
    mov ax, 1080
    out dx, ax

    mov dx, 0x01CE
    mov ax, 3
    out dx, ax
    inc dx
    mov ax, 32
    out dx, ax

    mov dx, 0x01CE
    mov ax, 6
    out dx, ax
    inc dx
    mov ax, 1920
    out dx, ax

    mov dx, 0x01CE
    mov ax, 4
    out dx, ax
    inc dx
    mov ax, 0x0041
    out dx, ax

    mov eax, [framebuffer_base]
    mov [0x5000], eax
    mov dword [0x5004], 1920
    mov dword [0x5008], 1080
    mov dword [0x500C], 7680

    ; Set up page tables for 64-bit long mode
    ; PML4[0] -> PDPT
    mov eax, pdpt_table
    or eax, 0x03  ; Present + Write
    mov [pml4_table], eax

    ; PDPT[0] -> PD
    mov eax, pd_table
    or eax, 0x03
    mov [pdpt_table], eax

    ; PD[0-511] -> 2MB pages (identity mapping for first 1GB)
    mov ecx, 512
    xor edi, edi
    mov eax, 0x00000083  ; Present + Write + 2MB page
.setup_pd:
    mov [pd_table + edi * 8], eax
    inc edi
    add eax, 0x200000
    loop .setup_pd

    ; Load page table base into CR3
    mov eax, pml4_table
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or eax, 0x20  ; PAE bit
    mov cr4, eax

    ; Enable long mode
    mov ecx, 0xC0000080  ; EFER MSR
    rdmsr
    or eax, 0x100  ; LME bit
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 0x80000000  ; PG bit
    mov cr0, eax

    ; Jump to 64-bit mode
    jmp 0x18:long_mode_entry

halt_kernel:
    cli
    hlt
    jmp halt_kernel

vbe_protected_error:
    cli
    hlt
    jmp vbe_protected_error

bits 64
long_mode_entry:
    ; Set up 64-bit data segments
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Set up 64-bit stack
    mov rsp, 0x90000

    ; Pass framebuffer info to kernel (via memory)
    mov rax, [0x5000]
    mov [0x5000], rax
    mov dword [0x5008], 1920
    mov dword [0x500C], 1080
    mov dword [0x5010], 7680

    ; Call the kernel
    mov rax, 0x10000
    call rax

halt_64:
    cli
    hlt
    jmp halt_64