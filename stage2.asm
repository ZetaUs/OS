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

    ; Switch to VGA mode 0x13 temporarily
    mov ax, 0x0013
    int 0x10

    ; Display a message to show we're alive
    mov si, boot_msg
    call print_string

    ; Try VBE mode 0x118 (800x600x24) - most compatible
    mov ax, 0x4F01
    mov cx, 0x0118
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne .try_next_mode
    
    ; Check if mode has linear framebuffer
    test word [vbe_mode_info], 0x0081
    jnz .mode_found

.try_next_mode:
    ; Try VBE mode 0x101 (640x480x8) as fallback
    mov ax, 0x4F01
    mov cx, 0x0101
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne vbe_error
    
    test word [vbe_mode_info], 0x0081
    jz vbe_error

.mode_found:
    ; Get framebuffer physical address
    mov eax, [vbe_mode_info + 40]
    test eax, eax
    jz vbe_error
    mov [framebuffer_base], eax
    
    ; Get width, height, bpp
    movzx eax, word [vbe_mode_info + 18]
    mov [vbe_width], eax
    movzx eax, word [vbe_mode_info + 20]
    mov [vbe_height], eax
    movzx eax, byte [vbe_mode_info + 25]
    mov [vbe_bpp], eax
    movzx eax, word [vbe_mode_info + 16]
    mov [vbe_pitch], eax

    ; Set VBE mode with linear framebuffer bit (0x4000)
    mov ax, 0x4F02
    mov bx, cx
    or bx, 0x4000
    int 0x10
    cmp ax, 0x004F
    jne vbe_error

    ; Display success message
    mov si, vbe_ok_msg
    call print_string
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16

    ; Display success message
    mov si, vbe_ok_msg
    call print_string
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16

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

    ; Configure VBE for 1920x1080x32 using Bochs VBE extension (optional)
    mov dx, 0x01CE
    xor ax, ax
    out dx, ax
    inc dx
    in ax, dx
    cmp ax, 0xB0C5
    jne skip_bochs_vbe

    ; Index 4: Enable LFB
    mov dx, 0x01CE
    mov ax, 4
    out dx, ax
    inc dx
    mov ax, 0x0041
    out dx, ax

    ; Index 1: Width = 1920
    mov dx, 0x01CE
    mov ax, 1
    out dx, ax
    inc dx
    mov ax, 1920
    out dx, ax

    ; Index 2: Height = 1080
    mov dx, 0x01CE
    mov ax, 2
    out dx, ax
    inc dx
    mov ax, 1080
    out dx, ax

    ; Index 3: BPP = 32
    mov dx, 0x01CE
    mov ax, 3
    out dx, ax
    inc dx
    mov ax, 32
    out dx, ax

    ; Index 6: Pitch (bytes per line) = 1920 * 4 = 7680
    mov dx, 0x01CE
    mov ax, 6
    out dx, ax
    inc dx
    mov ax, 7680
    out dx, ax

skip_bochs_vbe:

    mov eax, [framebuffer_base]
    mov [0x5000], eax
    mov eax, [vbe_width]
    mov [0x5004], eax
    mov eax, [vbe_height]
    mov [0x5008], eax
    mov eax, [vbe_pitch]
    mov [0x500C], eax

continue_boot:

    ; Call the kernel (32-bit protected mode) with 4 parameters
    push dword [0x500C]  ; pitch
    push dword [0x5008]  ; height
    push dword [0x5004]  ; width
    push dword [0x5000]  ; framebuffer_base
    call 0x10000
    add esp, 16

halt_kernel:
    cli
    hlt
    jmp halt_kernel

vbe_protected_error:
    cli
    hlt
    jmp vbe_protected_error