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
    mov [boot_drive], dl
    
    ; Set VGA mode 0x13 (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10
    
    ; Read stage2 using LBA (int 0x13 ah=0x42)
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc disk_error
    
    ; Debug: Draw green pixel at (10,10) to confirm disk read succeeded
    mov ax, 0xA000
    mov es, ax
    mov di, 10 * 320 + 10
    mov al, 2          ; Green pixel
    stosb
    
    ; Jump to stage2
    jmp 0x07E0:0x0000

disk_error:
    mov si, msg_err
    call print_string
halt_loop:
    hlt
    jmp halt_loop

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

; Disk Address Packet for LBA read (16 bytes)
dap:
    db 0x10          ; [0] Packet size = 16 bytes
    db 0x00          ; [1] Reserved
    dw 8             ; [2-3] Number of sectors to read = 8 (4KB)
    dw 0x0000        ; [4-5] Buffer offset = 0x0000
    dw 0x07E0        ; [6-7] Buffer segment = 0x07E0 (physical 0x7E00)
    dd 1             ; [8-11] Starting LBA = 1
    dd 0             ; [12-15] LBA high = 0

msg_err: db 'ERR', 0
boot_drive: db 0

times 510-($-$$) db 0
dw 0xAA55