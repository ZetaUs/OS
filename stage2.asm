bits 16
org 0x7E00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    sti
    
    mov ax, 0x07E0
    mov ds, ax
    
    mov ax, 0x0013
    int 0x10
    
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    call init_palette
    
    mov cx, 40
    mov dx, 30
    mov bx, 240
    mov si, 140
    mov al, 2
    call draw_rect
    
    mov cx, 55
    mov dx, 80
    mov bx, 210
    mov si, 18
    mov al, 3
    call draw_rect
    
    mov cx, 55
    mov dx, 115
    mov bx, 210
    mov si, 18
    mov al, 3
    call draw_rect
    
    mov cx, 100
    mov dx, 142
    mov bx, 120
    mov si, 20
    mov al, 4
    call draw_rect
    
    ; Load HZK12 from disk
    call load_hzk12
    
    ; Draw title using HZK12
    mov si, title_str
    mov bp, 80
    mov dx, 8
    call draw_string_hz
    
    ; Draw "Welcome" using HZK12
    mov si, welcome_str
    mov bp, 90
    mov dx, 28
    call draw_string_hz
    
    ; Draw "Username:" using HZK12
    mov si, username_str
    mov bp, 55
    mov dx, 62
    call draw_string_hz
    
    ; Draw "Password:" using HZK12
    mov si, password_str
    mov bp, 55
    mov dx, 97
    call draw_string_hz
    
    ; Draw "Login" using HZK12
    mov si, login_str
    mov bp, 120
    mov dx, 144
    call draw_string_hz
    
    call init_mouse
    
    mov ax, [mouse_x]
    mov [mouse_prev_x], ax
    mov ax, [mouse_y]
    mov [mouse_prev_y], ax
    
main_loop:
    mov ax, [mouse_x]
    mov [mouse_prev_x], ax
    mov ax, [mouse_y]
    mov [mouse_prev_y], ax
    
    call read_mouse
    
    mov ax, [mouse_x]
    mov bx, [mouse_prev_x]
    cmp ax, bx
    jne mouse_moved
    mov ax, [mouse_y]
    mov bx, [mouse_prev_y]
    cmp ax, bx
    je main_loop
    
mouse_moved:
    call draw_mouse_cursor
    
    mov cx, 500
delay_loop:
    loop delay_loop
    
    jmp main_loop

halt_s2:
    hlt
    jmp halt_s2

; Load HZK12 from disk to memory at 0x1000:0x0000
load_hzk12:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    ; Use LBA read (int 0x13 ah=0x42)
    mov ah, 0x42
    mov dl, 0x80         ; First hard disk
    mov si, hzk_dap - start
    int 0x13
    jc hzk_load_error
    
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

hzk_load_error:
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 4
    rep stosb
    hlt
    jmp halt_s2

init_palette:
    push ax
    push bx
    push cx
    push dx
    
    mov dx, 0x03C8
    mov al, 0
    out dx, al
    inc dx
    
    ; Color 0: Black
    xor al, al
    out dx, al
    out dx, al
    out dx, al
    
    ; Color 1: Dark Blue
    mov al, 0
    out dx, al
    mov al, 0
    out dx, al
    mov al, 42
    out dx, al
    
    ; Color 2: Gray
    mov al, 32
    out dx, al
    mov al, 32
    out dx, al
    mov al, 32
    out dx, al
    
    ; Color 3: Light Gray
    mov al, 42
    out dx, al
    mov al, 42
    out dx, al
    mov al, 42
    out dx, al
    
    ; Color 4: Red
    mov al, 63
    out dx, al
    xor al, al
    out dx, al
    xor al, al
    out dx, al
    
    ; Color 5: Dark Gray
    mov al, 21
    out dx, al
    mov al, 21
    out dx, al
    mov al, 21
    out dx, al
    
    ; Color 6: Green
    xor al, al
    out dx, al
    mov al, 63
    out dx, al
    xor al, al
    out dx, al
    
    ; Color 7: White
    mov al, 63
    out dx, al
    mov al, 63
    out dx, al
    mov al, 63
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
    push cx
    mov ax, 320
    mul dx
    pop cx
    add ax, cx
    mov di, ax
    mov al, [rect_color]
    stosb
    pop dx
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

; Draw HZK12 character
; Input: AL = high byte (区号), AH = low byte (位号)
;        BP = X position, DX = Y position
draw_char_hz:
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    push ds
    
    mov [char_hz_x], bp
    mov [char_hz_y], dx
    
    ; Calculate HZK12 offset
    mov bl, al
    mov bh, ah
    sub bl, 0xA1
    sub bh, 0xA1
    
    mov al, bl
    mov ah, 0
    mov cx, 94
    mul cx
    mov bl, bh
    mov bh, 0
    add ax, bx
    
    ; HZK12: each char is 24 bytes (12 rows x 2 bytes)
    mov bx, 24
    mul bx
    
    ; DS = 0x1000 (HZK12 segment)
    mov dx, 0x1000
    mov ds, dx
    mov si, ax
    
    mov ax, 0xA000
    mov es, ax
    
    mov cx, 12
    mov [char_hz_row], cx
    xor bx, bx
    
draw_hz_row:
    mov al, [si]
    mov ah, [si+1]
    add si, 2
    
    mov dx, [char_hz_y]
    add dx, bx
    
    mov bp, dx
    mov dx, 320
    mul dx
    mov di, ax
    add di, [char_hz_x]
    
    ; Draw first byte (8 pixels)
    mov cx, 8
    mov dl, al
draw_hz_p1:
    test dl, 0x80
    jz skip_hz_p1
    mov al, 7
    stosb
    jmp next_hz_p1
skip_hz_p1:
    inc di
next_hz_p1:
    shl dl, 1
    loop draw_hz_p1
    
    ; Draw second byte (4 pixels for 12-width)
    mov cx, 4
    mov dl, ah
draw_hz_p2:
    test dl, 0x80
    jz skip_hz_p2
    mov al, 7
    stosb
    jmp next_hz_p2
skip_hz_p2:
    inc di
next_hz_p2:
    shl dl, 1
    loop draw_hz_p2
    
    inc bx
    dec word [char_hz_row]
    jnz draw_hz_row
    
    pop ds
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Draw HZK12 string
; Input: SI = pointer to GB2312 string
;        BP = X, DX = Y
draw_string_hz:
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    push es
    push ds
    mov [str_hz_x], bp
    mov [str_hz_y], dx
draw_str_hz_loop:
    lodsb
    test al, al
    jz draw_str_hz_done
    mov ah, [si]
    inc si
    push si
    mov bp, [str_hz_x]
    mov dx, [str_hz_y]
    call draw_char_hz
    pop si
    add word [str_hz_x], 12
    jmp draw_str_hz_loop
draw_str_hz_done:
    pop ds
    pop es
    pop bp
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

init_mouse:
    push ax
    push bx
    push cx
    push dx
    
    mov ax, 0
    int 0x33
    
    mov ax, 1
    int 0x33
    
    mov ax, 7
    mov cx, 0
    mov dx, 319
    int 0x33
    
    mov ax, 8
    mov cx, 0
    mov dx, 199
    int 0x33
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

read_mouse:
    push ax
    push bx
    push cx
    push dx
    
    mov ax, 3
    int 0x33
    
    mov [mouse_x], cx
    mov [mouse_y], dx
    mov [mouse_buttons], bl
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_mouse_cursor:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    push si
    
    mov ax, 0xA000
    mov es, ax
    
    mov si, [mouse_y]
    mov di, [mouse_x]
    
    push si
    push di
    sub di, 2
    call draw_cursor_pixel_at
    inc di
    call draw_cursor_pixel_at
    inc di
    call draw_cursor_pixel_at
    inc di
    call draw_cursor_pixel_at
    inc di
    call draw_cursor_pixel_at
    pop di
    pop si
    
    push si
    push di
    sub si, 2
    call draw_cursor_pixel_at
    inc si
    call draw_cursor_pixel_at
    inc si
    call draw_cursor_pixel_at
    inc si
    call draw_cursor_pixel_at
    inc si
    call draw_cursor_pixel_at
    pop di
    pop si
    
    pop si
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_cursor_pixel_at:
    push ax
    push bx
    push cx
    push dx
    
    mov dx, si
    mov cx, di
    
    cmp dx, 199
    ja draw_cursor_pixel_at_done
    cmp cx, 319
    ja draw_cursor_pixel_at_done
    
    mov ax, 320
    mul dx
    add ax, cx
    mov bx, ax
    
    mov di, bx
    mov al, 7
    stosb
    
draw_cursor_pixel_at_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Variables
rect_x: dw 0
rect_y: dw 0
rect_width: dw 0
rect_height: dw 0
rect_color: db 0

char_hz_x: dw 0
char_hz_y: dw 0
char_hz_row: dw 0
str_hz_x: dw 0
str_hz_y: dw 0

mouse_x: dw 160
mouse_y: dw 100
mouse_buttons: db 0
mouse_prev_x: dw 0
mouse_prev_y: dw 0
mouse_hidden: db 0

; HZK12 DAP (copy from boot sector)
hzk_dap:
    db 0x10
    db 0
    dw 384
    dw 0x0000
    dw 0x1000
    dd 65
    dd 0

; Boot drive (at offset 0x200, set by boot sector)
boot_drive: db 0

; GB2312 encoded strings
; "Nova OS" - N(0x4E6F), o(0x6F76), v(0x7661), a(0x6120), 空格, O(0x4F53), S(0x5300)
; Actually let's use ASCII for English text with HZK12
; HZK12 supports ASCII too (区号0xA1-0xA3 for ASCII)

; For simplicity, let's use Chinese characters
; "欢迎" = 欢迎 (Welcome)
title_str:    db 0xBB,0xB6, 0xD3,0xAD, 0x00    ; 欢迎
welcome_str:  db 0xBB,0xB6, 0xD3,0xAD, 0xCA,0xB9, 0xD3,0xC3, 0x00  ; 欢迎使用
username_str: db 0xD3,0xC3, 0xBB,0xA7, 0xC3,0xFB, 0x3A, 0x00  ; 用户名:
password_str: db 0xC3,0xDC, 0xC2,0xEB, 0x3A, 0x00  ; 密码:
login_str:    db 0xB5,0xC7, 0xC2,0xBC, 0x00  ; 登录