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

    ; Switch to VGA mode 0x13 (320x200x8)
    mov ax, 0x0013
    int 0x10

    ; Load kernel from disk
    mov si, kernel_dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc kernel_load_error

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
    ; Far jump to protected mode entry using retf
    push 0x08
    push word protected_mode_entry
    retf

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
    ; 32-bit code segment (base=0, limit=4GB)
    dw 0xFFFF        ; Limit (15:0)
    dw 0x0000        ; Base (15:0)
    db 0x00          ; Base (23:16)
    db 0x9A          ; Access (present, ring 0, code, readable)
    db 0xCF          ; Flags (G=1, D=1) + Limit (19:16)
    db 0x00          ; Base (31:24)
    ; 32-bit data segment (base=0, limit=4GB)
    dw 0xFFFF        ; Limit (15:0)
    dw 0x0000        ; Base (15:0)
    db 0x00          ; Base (23:16)
    db 0x92          ; Access (present, ring 0, data, writable)
    db 0xCF          ; Flags (G=1, D=1) + Limit (19:16)
    db 0x00          ; Base (31:24)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

kernel_dap:
    db 0x10, 0
    dw 128
    dw 0
    dw 0x1000
    dd 18
    dd 0

boot_drive: db 0
prot_mode_msg: db 'Entering protected mode...', 13, 10, 0
error_message: db 'Kernel load error', 0

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
    ; Call the kernel (32-bit protected mode) with 5 parameters
    push dword 8
    push dword 320
    push dword 200
    push dword 320
    push dword 0xA0000
    call 0x10000
    add esp, 20

halt_kernel:
    cli
    hlt
    jmp halt_kernel