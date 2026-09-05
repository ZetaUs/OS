bits 16
org 0x7E00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Set VGA mode 0x13 (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10
    
    ; Enable chain-4 mode for linear pixel access
    mov dx, 0x03C4
    mov al, 0x00
    out dx, al
    inc dx
    mov al, 0x01
    out dx, al
    
    mov dx, 0x03C4
    mov al, 0x04
    out dx, al
    inc dx
    mov al, 0x0E
    out dx, al
    
    mov dx, 0x03CE
    mov al, 0x05
    out dx, al
    inc dx
    mov al, 0x40
    out dx, al
    
    mov dx, 0x03C4
    mov al, 0x00
    out dx, al
    inc dx
    mov al, 0x03
    out dx, al
    
    ; Clear all segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Initialize palette
    call init_palette
    
    ; Load 8x8 font to 0x8000
    xor ax, ax
    mov es, ax
    mov si, font_8x8
    mov di, 0x8000
    mov cx, 768
    cld
    rep movsb
    
    ; Reset segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; Draw loading screen background
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    ; Draw title
    mov si, title_msg
    mov bp, 120
    mov dx, 10
    call draw_string_8x8
    
    ; Draw progress bar background
    mov cx, 80
    mov dx, 160
    mov bx, 160
    mov si, 16
    mov al, 5
    call draw_rect
    
    ; Draw progress bar fill
    mov cx, 82
    mov dx, 162
    mov bx, 0
    mov si, 12
    mov al, 6
    call draw_rect
    
    ; Draw "Loading..." text
    mov si, loading_msg
    mov bp, 120
    mov dx, 182
    call draw_string_8x8
    
    ; Animate loading progress
    mov cx, 0
load_loop:
    push cx
    mov cx, 82
    mov dx, 162
    mov bx, 156
    mov si, 12
    mov al, 1
    call draw_rect
    pop cx
    push cx
    mov bx, cx
    mov cx, 82
    mov dx, 162
    mov si, 12
    mov al, 6
    call draw_rect
    pop cx
    add cx, 2
    cmp cx, 156
    jl load_loop
    
    ; Debug: BLUE - about to load HZK16 using CHS
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 19        ; Blue color
    rep stosb
    
    ; Load HZK16 using CHS addressing (int 0x13 ah=0x02)
    ; LBA 115 = C=0, H=1, S=53 (16 heads, 63 sectors/track)
    ; Read 523 sectors in chunks
    
    mov [sectors_left], word 523
    mov [current_cyl], byte 0
    mov [current_head], byte 1
    mov [current_sect], byte 53
    mov [buf_seg], word 0x1000
    mov [buf_off], word 0x0000
    
read_hzk_chs:
    cmp word [sectors_left], 0
    je hzk_chs_done
    
    ; Calculate sectors to read this time (max 18 per call)
    mov ax, [sectors_left]
    cmp ax, 18
    jle read_all_remaining
    mov ax, 18
read_all_remaining:
    mov [to_read], al
    
    ; Setup for int 0x13 ah=0x02
    mov ah, 0x02        ; Read sectors
    mov al, [to_read]   ; Number of sectors
    mov dl, [0x0500]    ; Boot drive
    mov dh, [current_head]
    mov ch, [current_cyl]
    mov cl, [current_sect]
    
    ; Buffer address
    mov es, [buf_seg]
    mov bx, [buf_off]
    
    int 0x13
    jc hzk_load_error
    
    ; Update sector count
    sub word [sectors_left], ax
    
    ; Update CHS position
    mov al, [current_sect]
    add al, [to_read]
    mov [current_sect], al
    
chs_check_sect:
    cmp byte [current_sect], 64
    jl chs_update_buf
    sub byte [current_sect], 63
    inc byte [current_head]
    
chs_check_head:
    cmp byte [current_head], 16
    jl chs_update_buf
    sub byte [current_head], 16
    inc byte [current_cyl]
    
chs_update_buf:
    ; Update buffer: add (to_read * 512) to ES:BX
    mov al, [to_read]
    mov ah, 0
    mov bx, 512
    mul bx              ; AX = to_read * 512
    add [buf_off], ax
    adc word [buf_seg], 0
    
    jmp read_hzk_chs

hzk_chs_done:
    ; HZK loaded successfully, now draw Chinese login screen
    ; Clear screen with dark blue
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    ; DEBUG: Test HZK16 data - copy first 32 bytes to screen center
    mov ax, 0x1000
    mov ds, ax
    mov si, 0          ; HZK16 start
    mov ax, 0xA000
    mov es, ax
    mov di, 320*90 + 100  ; Center of screen
    mov cx, 32         ; One character's data
    rep movsb
    
    ; Draw login box
    mov cx, 20
    mov dx, 20
    mov bx, 280
    mov si, 160
    mov al, 2
    call draw_rect
    
    ; Draw title "欢迎使用"
    mov si, welcome_msg
    mov bp, 100
    mov dx, 30
    call draw_string_16x16
    
    ; Draw "用户名:"
    mov si, username_msg
    mov bp, 40
    mov dx, 65
    call draw_string_16x16
    
    ; Draw username input box
    mov cx, 100
    mov dx, 60
    mov bx, 160
    mov si, 16
    mov al, 3
    call draw_rect
    
    ; Draw "密码:"
    mov si, password_msg
    mov bp, 40
    mov dx, 115
    call draw_string_16x16
    
    ; Draw password input box
    mov cx, 100
    mov dx, 110
    mov bx, 160
    mov si, 16
    mov al, 3
    call draw_rect
    
    ; Draw login button
    mov cx, 110
    mov dx, 155
    mov bx, 100
    mov si, 24
    mov al, 6
    call draw_rect
    
    ; Draw "登录" button text
    mov si, login_msg
    mov bp, 132
    mov dx, 162
    call draw_string_16x16
    
halt_s2:
    hlt
    jmp halt_s2

hzk_load_error:
    ; Show error - red screen
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 40
    rep stosb
    hlt
    jmp halt_s2

load_width: dw 0

init_palette:
    push ax
    push bx
    push cx
    push dx
    mov dx, 0x03C8
    mov al, 0
    out dx, al
    inc dx
    xor al, al
    out dx, al
    out dx, al
    out dx, al
    xor al, al
    out dx, al
    xor al, al
    out dx, al
    mov al, 42
    out dx, al
    mov al, 32
    out dx, al
    mov al, 32
    out dx, al
    mov al, 21
    out dx, al
    mov al, 42
    out dx, al
    mov al, 63
    out dx, al
    mov al, 21
    out dx, al
    out dx, al
    out dx, al
    mov al, 42
    out dx, al
    out dx, al
    out dx, al
    xor al, al
    out dx, al
    xor al, al
    out dx, al
    mov al, 63
    out dx, al
    mov al, 63
    out dx, al
    out dx, al
    out dx, al
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_rect:
    push bp
    push si
    push di
    push es
    mov [rect_x], cx
    mov [rect_y], dx
    mov [rect_width], bx
    mov [rect_height], si
    mov [rect_color], al
    mov ax, 0xA000
    mov es, ax
    mov dx, [rect_y]
draw_rect_row:
    mov cx, [rect_x]
    mov bx, [rect_width]
draw_rect_col:
    push dx
    mov ax, 320
    mul dx
    pop dx
    add ax, cx
    mov di, ax
    mov al, [rect_color]
    stosb
    inc cx
    dec bx
    jnz draw_rect_col
    inc dx
    dec word [rect_height]
    jnz draw_rect_row
    pop es
    pop di
    pop si
    pop bp
    ret

draw_string_8x8:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    mov [str_x], bp
    mov [str_y], dx
draw_str_loop:
    lodsb
    test al, al
    jz draw_str_done
    push ax
    push si
    mov bp, [str_x]
    mov dx, [str_y]
    call draw_char_8x8
    pop si
    pop ax
    add word [str_x], 8
    jmp draw_str_loop
draw_str_done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_char_8x8:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    mov [char_x], bp
    mov [char_y], dx
    mov bl, al
    mov bh, 0
    shl bx, 3
    add bx, 0x8000
    mov si, bx
    mov ax, 0xA000
    mov es, ax
    mov cx, 8
    mov [char_row], cx
    xor bx, bx
draw_char_row:
    mov al, [si]
    inc si
    mov dx, [char_y]
    add dx, bx
    mov bp, dx
    mov ax, 320
    mul bp
    mov di, ax
    add di, [char_x]
    mov cx, 8
    mov dl, al
draw_char_pixel:
    test dl, 0x80
    jz skip_pixel
    mov al, 7
    stosb
    jmp next_pixel
skip_pixel:
    inc di
next_pixel:
    shl dl, 1
    loop draw_char_pixel
    inc bx
    dec word [char_row]
    jnz draw_char_row
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw 16x16 Chinese character from HZK16
; Input: AL = high byte (区号), AH = low byte (位号)
;        BP = X position
;        DX = Y position
draw_char_16x16:
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    push ds
    
    ; Save X and Y
    mov [char16_x], bp
    mov [char16_y], dx
    
    ; Calculate HZK16 offset from GB2312 code (AL=high/区号, AH=low/位号)
    ; Save original values
    mov bl, al           ; BL = 区号
    mov bh, ah           ; BH = 位号
    
    sub bl, 0xA1         ; 区号 - 0xA1
    sub bh, 0xA1         ; 位号 - 0xA1
    
    mov al, bl           ; AL = 区号
    mov ah, 0
    mov cx, 94
    mul cx               ; AX = 区号 * 94
    mov bl, bh           ; BL = 位号
    mov bh, 0
    add ax, bx           ; AX = 区号 * 94 + 位号
    
    shl ax, 5            ; AX = offset in HZK16 (each char is 32 bytes)
    
    ; Set DS to HZK16 segment
    mov dx, 0x1000
    mov ds, dx
    mov si, ax
    
    ; Set ES to VRAM
    mov ax, 0xA000
    mov es, ax
    
    ; Draw 16 rows
    mov cx, 16
    mov [char16_row], cx
    xor bx, bx           ; Row counter
draw_char16_row:
    ; Read 2 bytes from HZK16
    mov al, [si]
    mov ah, [si+1]
    add si, 2
    
    ; Calculate VRAM offset for this row
    mov dx, [char16_y]
    add dx, bx
    
    mov bp, dx
    mov ax, 320
    mul bp               ; DX:AX = 320 * Y, but we only need AX for 320x200 screen
    mov di, ax           ; DI = low 16 bits of result (offset in VRAM)
    add di, [char16_x]   ; Add X offset
    
    ; Draw first byte (8 pixels)
    mov cx, 8
    mov dl, al
draw_char16_pixel1:
    test dl, 0x80
    jz skip_pixel1
    mov al, 7            ; White
    stosb
    jmp next_pixel1
skip_pixel1:
    inc di
next_pixel1:
    shl dl, 1
    loop draw_char16_pixel1
    
    ; Draw second byte (8 pixels)
    mov cx, 8
    mov dl, ah
draw_char16_pixel2:
    test dl, 0x80
    jz skip_pixel2
    mov al, 7            ; White
    stosb
    jmp next_pixel2
skip_pixel2:
    inc di
next_pixel2:
    shl dl, 1
    loop draw_char16_pixel2
    
    inc bx
    dec word [char16_row]
    jnz draw_char16_row
    
    pop ds
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Draw 16x16 Chinese string
; Input: SI = pointer to GB2312 encoded string
;        BP = X position
;        DX = Y position
draw_string_16x16:
    push bx
    push cx
    push dx
    push di
    push bp
    push es
    mov [str16_x], bp
    mov [str16_y], dx
draw_str16_loop:
    lodsb
    test al, al
    jz draw_str16_done
    mov ah, [si]         ; Get second byte
    inc si               ; Advance past second byte
    ; AL = high byte, AH = low byte - ready for draw_char_16x16
    push si              ; Save string pointer
    mov bp, [str16_x]
    mov dx, [str16_y]
    call draw_char_16x16
    pop si               ; Restore string pointer
    add word [str16_x], 16
    jmp draw_str16_loop
draw_str16_done:
    pop es
    pop bp
    pop di
    pop dx
    pop cx
    pop bx
    ret

; Variables
rect_x: dw 0
rect_y: dw 0
rect_width: dw 0
rect_height: dw 0
rect_color: db 0
str_x: dw 0
str_y: dw 0
char_x: dw 0
char_y: dw 0
char_row: dw 0
char16_x: dw 0
char16_y: dw 0
char16_row: dw 0
str16_x: dw 0
str16_y: dw 0

; CHS reading variables
sectors_left: dw 0
current_cyl: db 0
current_head: db 0
current_sect: db 0
buf_seg: dw 0
buf_off: dw 0
to_read: db 0

; DAP structure for HZK16 loading
hzk_dap:
    db 0x10        ; DAP size (16 bytes)
    db 0           ; Reserved
    dw 523         ; Sector count
    dw 0x0000      ; Buffer offset
    dw 0x1000      ; Buffer segment
    dd 115         ; LBA low
    dd 0           ; LBA high

; ASCII strings
title_msg:    db 'Nova OS', 0
loading_msg:  db 'Loading...', 0

; GB2312 encoded Chinese strings
; 欢迎使用 = BB B6 D3 AD CA B9 D3 C3
welcome_msg: db 0xBB, 0xB6, 0xD3, 0xAD, 0xCA, 0xB9, 0xD3, 0xC3, 0
; 用户名: = D3 C3 BB A7 C3 FB 3A
username_msg: db 0xD3, 0xC3, 0xBB, 0xA7, 0xC3, 0xFB, 0x3A, 0
; 密码: = C3 DC C2 EB 3A
password_msg: db 0xC3, 0xDC, 0xC2, 0xEB, 0x3A, 0
; 登录 = B5 C7 C2 BC
login_msg: db 0xB5, 0xC7, 0xC2, 0xBC, 0

; 8x8 font data (partial)
font_8x8:
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x18,0x3C,0x3C,0x18,0x00,0x00
    db 0x00,0x18,0x18,0x7E,0x7E,0x18,0x18,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x00