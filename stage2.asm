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

    ; Set DS to 0x07E0 so that [label] addresses resolve to 0x7E00+offset
    mov ax, 0x07E0
    mov ds, ax
    mov es, ax

    ; Enable A20 line
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Use simple VGA mode 0x13 (320x200x8) for testing
    mov ax, 0x0013
    int 0x10
    
    ; Store framebuffer info for protected mode
    ; VGA mode 0x13 framebuffer is at 0xA0000
    mov dword [0x5000], 0xA0000
    mov dword [0x5004], 320
    mov dword [0x5008], 200
    mov word [0x500C], 320
    mov byte [0x5010], 8

    ; Display mode set message
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

    mov si, kernel_loaded_msg
    call print_string

    cli
    
    ; Build GDT descriptor
    mov ax, 0x0000
    mov es, ax
    mov word [es:0x4000], gdt_end - gdt_start - 1
    mov eax, gdt_start
    mov [es:0x4000 + 2], eax
    
    lgdt [es:0x4000]
    
    mov si, prot_mode_msg
    call print_string
    
    ; Disable PIC
    in al, 0x21
    or al, 0xFF
    out 0x21, al
    in al, 0xA1
    or al, 0xFF
    out 0xA1, al
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    push 0x08
    push word protected_mode_entry
    retf

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
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00
gdt_end:

kernel_dap:
    db 0x10, 0
    dw 128
    dw 0
    dw 0x1000
    dd 20
    dd 0

boot_drive: db 0
boot_msg: db 'Nova OS Booting...', 13, 10, 0
vbe_ok_msg: db 'Mode OK', 13, 10, 0
kernel_load_msg: db 'Loading kernel...', 13, 10, 0
kernel_loaded_msg: db 'Kernel loaded', 13, 10, 0
prot_mode_msg: db 'Entering protected mode...', 13, 10, 0
error_message: db 'Kernel load error', 0
vbe_error_message: db 'VBE mode error', 0

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

continue_boot:
    ; Fill VGA framebuffer (0xA0000) with blue (color index 1 in mode 0x13)
    mov edi, 0xA0000
    mov ecx, 320 * 200
    mov al, 1  ; Blue in VGA palette
.fill_loop:
    mov [edi], al
    inc edi
    dec ecx
    jnz .fill_loop

.halt:
    cli
    hlt
    jmp .halt