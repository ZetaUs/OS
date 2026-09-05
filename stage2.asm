bits 16
org 0x7E00

start:
    ; Set DS=ES=0x0000 since org 0x7E00 means labels are absolute offsets
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
    
    ; DS=ES=0x0000 already set
    ; Initialize palette
    call init_palette
    
    ; Load 8x8 font to 0x8000
    xor ax, ax
    mov ds, ax
    mov si, font_8x8
    mov es, ax
    mov di, 0x8000
    mov cx, 1024        ; 128 chars * 8 bytes = 1024 bytes
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
    
    ; Draw title "Nova OS"
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
    
    ; Skip loading animation for now - go directly to login screen
    jmp draw_login_screen
    
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
    
    ; Skip loading animation for now - go directly to login screen
    jmp draw_login_screen
    
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
    
    ; Skip loading animation for now - go directly to login screen
    jmp draw_login_screen
    
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
    
draw_login_screen:
    ; Draw login screen
    ; Clear screen with dark blue
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    ; Debug: Direct pixel write to VRAM - draw a yellow line at row 50
    mov ax, 0xA000
    mov es, ax
    mov di, 50 * 320  ; Row 50
    mov cx, 320
draw_debug_line:
    mov al, 14        ; Yellow
    stosb
    loop draw_debug_line
    
    ; Draw login box
    mov cx, 20
    mov dx, 20
    mov bx, 280
    mov si, 160
    mov al, 2
    call draw_rect
    
    ; Draw title "Welcome"
    mov si, welcome_msg
    mov bp, 110
    mov dx, 30
    call draw_string_8x8
    
    ; Draw "Username:"
    mov si, username_msg
    mov bp, 40
    mov dx, 65
    call draw_string_8x8
    
    ; Draw username input box
    mov cx, 100
    mov dx, 60
    mov bx, 160
    mov si, 16
    mov al, 3
    call draw_rect
    
    ; Draw "Password:"
    mov si, password_msg
    mov bp, 40
    mov dx, 115
    call draw_string_8x8
    
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
    
    ; Draw "Login" button text
    mov si, login_msg
    mov bp, 136
    mov dx, 162
    call draw_string_8x8
    
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
    
    ; Start writing from color index 0
    mov dx, 0x03C8
    mov al, 0
    out dx, al
    inc dx
    
    ; Color 0: Black (background)
    xor al, al
    out dx, al
    out dx, al
    out dx, al
    
    ; Color 1: Dark Blue (main background)
    mov al, 0
    out dx, al
    mov al, 0
    out dx, al
    mov al, 42
    out dx, al
    
    ; Color 2: Gray (login box)
    mov al, 32
    out dx, al
    mov al, 32
    out dx, al
    mov al, 32
    out dx, al
    
    ; Color 3: Light Gray (input boxes)
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
    
    ; Color 5: Dark Gray (progress bar bg)
    mov al, 21
    out dx, al
    mov al, 21
    out dx, al
    mov al, 21
    out dx, al
    
    ; Color 6: Green (progress bar fill)
    xor al, al
    out dx, al
    mov al, 63
    out dx, al
    xor al, al
    out dx, al
    
    ; Color 7: White (text)
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

; Draw 8 pixels from AL at VRAM position DI
; Input: AL = byte pattern, DI = VRAM offset, ES = 0xA000
draw_byte:
    push ax
    push cx
    push dx
    mov cx, 8
    mov dl, al
draw_byte_loop:
    test dl, 0x80
    jz draw_byte_skip
    mov al, 7          ; White
    stosb              ; DI auto-increments
    jmp draw_byte_next
draw_byte_skip:
    inc di             ; Skip this pixel
draw_byte_next:
    shl dl, 1
    loop draw_byte_loop
    pop dx
    pop cx
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
    push ds
    mov [char_x], bp
    mov [char_y], dx
    
    ; Calculate font data offset: font_8x8 + (char_code * 8)
    mov bl, al
    mov bh, 0
    shl bx, 3            ; BX = char_code * 8
    
    ; Read font data directly from stage2 code segment
    push cs
    pop ds
    mov si, font_8x8
    add si, bx           ; SI = font_8x8 + offset
    
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
    pop ds
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
test_msg:     db 'TEST', 0

; Login screen strings
welcome_msg:  db 'Welcome', 0
username_msg: db 'Username:', 0
password_msg: db 'Password:', 0
login_msg:    db 'Login', 0

; 8x8 font data - complete table for ASCII 0-127
; Each character is 8 bytes
font_8x8:
    ; ASCII 0-63: empty
    times 64*8 db 0
    
    ; ASCII 64-95
    ; '@' (64)
    db 0x3C,0x42,0x99,0xA5,0xA5,0x99,0x42,0x3C
    ; 'A' (65)
    db 0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00
    ; 'B' (66)
    db 0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00
    ; 'C' (67)
    db 0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00
    ; 'D' (68)
    db 0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00
    ; 'E' (69)
    db 0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0x00
    ; 'F' (70)
    db 0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00
    ; 'G' (71)
    db 0x3C,0x66,0x60,0x6E,0x66,0x66,0x3C,0x00
    ; 'H' (72)
    db 0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00
    ; 'I' (73)
    db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    ; 'J' (74)
    db 0x1E,0x0C,0x0C,0x0C,0x0C,0x6C,0x38,0x00
    ; 'K' (75)
    db 0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00
    ; 'L' (76)
    db 0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00
    ; 'M' (77)
    db 0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00
    ; 'N' (78)
    db 0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00
    ; 'O' (79)
    db 0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00
    ; 'P' (80)
    db 0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00
    ; 'Q' (81)
    db 0x3C,0x66,0x66,0x66,0x6A,0x6C,0x36,0x00
    ; 'R' (82)
    db 0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00
    ; 'S' (83)
    db 0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00
    ; 'T' (84)
    db 0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00
    ; 'U' (85)
    db 0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00
    ; 'V' (86)
    db 0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00
    ; 'W' (87)
    db 0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00
    ; 'X' (88)
    db 0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00
    ; 'Y' (89)
    db 0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00
    ; 'Z' (90)
    db 0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00
    ; '[' (91)
    db 0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00
    ; '\' (92)
    db 0x00,0x60,0x30,0x18,0x0C,0x06,0x00,0x00
    ; ']' (93)
    db 0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00
    ; '^' (94)
    db 0x18,0x3C,0x66,0x00,0x00,0x00,0x00,0x00
    ; '_' (95)
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x7E,0x00
    
    ; ASCII 96-127
    ; '`' (96)
    db 0x30,0x18,0x00,0x00,0x00,0x00,0x00,0x00
    ; 'a' (97)
    db 0x00,0x00,0x3C,0x06,0x3E,0x66,0x3E,0x00
    ; 'b' (98)
    db 0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00
    ; 'c' (99)
    db 0x00,0x00,0x3C,0x60,0x60,0x60,0x3C,0x00
    ; 'd' (100)
    db 0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00
    ; 'e' (101)
    db 0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00
    ; 'f' (102)
    db 0x1C,0x06,0x06,0x3E,0x06,0x06,0x06,0x00
    ; 'g' (103)
    db 0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x3C
    ; 'h' (104)
    db 0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00
    ; 'i' (105)
    db 0x18,0x00,0x18,0x18,0x18,0x18,0x3C,0x00
    ; 'j' (106)
    db 0x0C,0x00,0x0C,0x0C,0x0C,0x0C,0x6C,0x38
    ; 'k' (107)
    db 0x60,0x60,0x6C,0x78,0x78,0x6C,0x66,0x00
    ; 'l' (108)
    db 0x18,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    ; 'm' (109)
    db 0x00,0x00,0x66,0x7F,0x7F,0x6B,0x63,0x00
    ; 'n' (110)
    db 0x00,0x00,0x7C,0x66,0x66,0x66,0x66,0x00
    ; 'o' (111)
    db 0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00
    ; 'p' (112)
    db 0x00,0x00,0x7C,0x66,0x66,0x7C,0x60,0x60
    ; 'q' (113)
    db 0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x06
    ; 'r' (114)
    db 0x00,0x00,0x7C,0x66,0x60,0x60,0x60,0x00
    ; 's' (115)
    db 0x00,0x00,0x3E,0x60,0x3C,0x06,0x7C,0x00
    ; 't' (116)
    db 0x06,0x06,0x3E,0x06,0x06,0x06,0x1C,0x00
    ; 'u' (117)
    db 0x00,0x00,0x66,0x66,0x66,0x66,0x3E,0x00
    ; 'v' (118)
    db 0x00,0x00,0x66,0x66,0x66,0x3C,0x18,0x00
    ; 'w' (119)
    db 0x00,0x00,0x63,0x6B,0x7F,0x7F,0x36,0x00
    ; 'x' (120)
    db 0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00
    ; 'y' (121)
    db 0x00,0x00,0x66,0x66,0x66,0x3E,0x06,0x3C
    ; 'z' (122)
    db 0x00,0x00,0x7E,0x0C,0x18,0x30,0x7E,0x00
    ; '{' (123)
    db 0x1C,0x06,0x06,0x06,0x06,0x06,0x1C,0x00
    ; '|' (124)
    db 0x18,0x18,0x18,0x00,0x18,0x18,0x18,0x00
    ; '}' (125)
    db 0xE0,0x60,0x60,0x60,0x60,0x60,0xE0,0x00
    ; '~' (126)
    db 0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00
    ; DEL (127)
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00