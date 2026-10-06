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

    in al, 0x92
    or al, 2
    out 0x92, al

    mov ax, 0x0013
    int 0x10

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
    jmp print_error

kernel_load_error:
    mov si, kernel_error_message

print_error:
    mov ah, 0x0E
.print_next:
    lodsb
    test al, al
    jz .halt
    int 0x10
    jmp .print_next
.halt:
    cli
    hlt
    jmp .halt

align 8
gdt_start:
    dq 0
    dq 0x00CF9A000000FFFF
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

boot_drive: db 0
vbe_error_message: db 'VBE mode error', 0
kernel_error_message: db 'Kernel load error', 0
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

    mov dx, 0x01CE
    xor ax, ax
    out dx, ax
    inc dx
    in ax, dx
    cmp ax, 0xB0C5
    jne vbe_protected_halt

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

    mov eax, 0x10000
    push dword [0x5000]
    call eax
    add esp, 4

kernel_halt:
    cli
    hlt
    jmp kernel_halt

vbe_protected_halt:
    cli
    hlt
    jmp vbe_protected_halt
