bits 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Save boot drive number
    mov [0x0500], dl
    
    ; Set DS to CS for accessing boot sector data (org 0x7C00)
    push cs
    pop ds
    
    ; Use LBA extended read (int 0x13 ah=0x42)
    mov si, dap
    mov ah, 0x42
    mov dl, [0x0500]
    int 0x13
    jc disk_error
    
    ; Print "LS2!"
    mov si, msg_ok
    call print_string
    
    ; Print "J"
    mov ah, 0x0E
    mov al, 'J'
    int 0x10
    
    ; Jump to stage2 using far jump
    ; CS=0x07E0, IP=0x0000 -> Physical address = 0x07E0*16 + 0x0000 = 0x7E00
    jmp dword 0x07E0:0x0000

print_string:
    mov ah, 0x0E
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
.done:
    ret

disk_error:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
halt_loop:
    hlt
    jmp halt_loop

msg_ok: db 'LS2!', 0
boot_drive: db 0

; Disk Address Packet for LBA read
dap:
    db 0x10        ; Size (16 bytes)
    db 0           ; Reserved
    dw 64          ; Sector count (64 sectors = 32KB for stage2)
    dw 0x7E00      ; Buffer offset
    dw 0x0000      ; Buffer segment
    dd 1           ; LBA start (low 32 bits)
    dd 0           ; LBA start (high 32 bits)

times 510-($-$$) db 0
dw 0xAA55