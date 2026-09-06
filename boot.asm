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
    
    ; DEBUG: Set VGA mode and draw green pixel to confirm boot sector runs
    mov ax, 0x0013
    int 0x10
    push es
    mov ax, 0xA000
    mov es, ax
    mov di, 100 * 320 + 150
    mov al, 2          ; Green pixel at center
    stosb
    pop es
    
    ; Use CHS read (int 0x13 ah=0x02) for floppy compatibility
    ; Read 64 sectors from cylinder 0, head 0, sector 2
    mov ah, 0x02
    mov al, 64         ; 64 sectors
    mov ch, 0          ; Cylinder 0
    mov cl, 2          ; Sector 2
    mov dh, 0          ; Head 0
    mov dl, [boot_drive]
    mov bx, 0x7E00     ; ES:BX = 0x0000:0x7E00
    int 0x13
    jc disk_error
    
    ; Draw second green pixel to confirm disk read succeeded
    push es
    mov ax, 0xA000
    mov es, ax
    mov di, 100 * 320 + 160
    mov al, 2          ; Green pixel
    stosb
    pop es
    
    ; Print "OK"
    mov si, msg_ok
    call print_string
    
    ; Draw third pixel before jump
    push es
    mov ax, 0xA000
    mov es, ax
    mov di, 100 * 320 + 165
    mov al, 2          ; Green pixel
    stosb
    pop es
    
    ; Jump to stage2
    jmp 0x0000:0x7E00

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
    mov si, msg_err
    call print_string
halt_loop:
    hlt
    jmp halt_loop

msg_ok: db 'OK', 0
msg_err: db 'ERR', 0
boot_drive: db 0

times 510-($-$$) db 0
dw 0xAA55