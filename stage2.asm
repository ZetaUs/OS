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

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Try VBE mode 0x115 (800x600x16) - best quality supported in QEMU
    mov ax, 0x4F01
    mov cx, 0x0115
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne .try_next_mode
    
    ; Check if mode has linear framebuffer
    test word [vbe_mode_info], 0x0081
    jnz .mode_found

.try_next_mode:
    ; Try VBE mode 0x112 (640x480x16) as fallback
    mov ax, 0x4F01
    mov cx, 0x0112
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

    ; Display VBE success message
    mov si, vbe_ok_msg
    call print_string

    ; Load kernel from disk
    mov si, kernel_load_msg
    call print_string
    
    mov si, kernel_dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc kernel_load_error

    ; Display kernel loaded message
    mov si, kernel_loaded_msg
    call print_string

    cli
    lgdt [gdt_descriptor]
    
    ; Display protected mode message
    mov si, prot_mode_msg
    call print_string
    
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

; Print string function
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

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
boot_msg: db 'Nova OS Booting...', 13, 10, 0
vbe_ok_msg: db 'VBE Mode OK', 13, 10, 0
kernel_load_msg: db 'Loading kernel...', 13, 10, 0
kernel_loaded_msg: db 'Kernel loaded', 13, 10, 0
prot_mode_msg: db 'Entering protected mode...', 13, 10, 0
error_message: db 'Kernel load error', 0
vbe_error_message: db 'VBE mode error', 0
framebuffer_base: dd 0
vbe_width: dd 0
vbe_height: dd 0
vbe_bpp: db 0
vbe_pitch: dw 0
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

    ; Store VBE parameters for kernel
    mov eax, [framebuffer_base]
    mov [0x5000], eax
    mov eax, [vbe_width]
    mov [0x5004], eax
    mov eax, [vbe_height]
    mov [0x5008], eax
    movzx eax, word [vbe_pitch]
    mov [0x500C], eax
    movzx eax, byte [vbe_bpp]
    mov [0x5010], eax

continue_boot:
    ; Call the kernel (32-bit protected mode) with 5 parameters
    push dword [0x5010]  ; bpp
    push dword [0x500C]  ; pitch
    push dword [0x5008]  ; height
    push dword [0x5004]  ; width
    push dword [0x5000]  ; framebuffer_base
    call 0x10000
    add esp, 20

halt_kernel:
    cli
    hlt
    jmp halt_kernel

vbe_protected_error:
    cli
    hlt
    jmp vbe_protected_error