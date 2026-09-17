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
    
    ; Switch to VGA mode 0x12 (640x480, 16 colors)
    mov ax, 0x0012
    int 0x10
    
    ; Fill screen with blue background using BIOS scroll
    mov ax, 0x0600
    mov bh, 0x01      ; Blue attribute
    mov cx, 0x0000    ; Upper left: row 0, col 0
    mov dx, 0x184F    ; Lower right: row 24, col 79
    int 0x10
    
    ; Also fill with pixel method for graphics mode
    ; Set write mode for all planes
    mov dx, 0x03CE
    mov al, 0x05      ; Mode register
    mov ah, 0x00      ; Write mode 0
    out dx, ax
    
    mov dx, 0x03C4
    mov al, 0x02      ; Map mask
    mov ah, 0x0F      ; All 4 planes
    out dx, ax
    
    ; Fill VRAM with blue (color 1 = 0001b, so plane 0 = 1, others = 0)
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 38400     ; 640*480/8 bytes per plane
    mov al, 0x01      ; Plane 0 = 1 (blue bit)
    rep stosb
    
    ; Draw login box (gray)
    mov cx, 120
    mov dx, 80
    mov bx, 400
    mov si, 320
    mov al, 7          ; White/Light gray
    call draw_rect_fast
    
    ; Draw input fields (darker gray)
    mov cx, 140
    mov dx, 160
    mov bx, 360
    mov si, 30
    mov al, 8          ; Dark gray
    call draw_rect_fast
    
    mov cx, 140
    mov dx, 220
    mov bx, 360
    mov si, 30
    mov al, 8
    call draw_rect_fast
    
    ; Draw login button (red)
    mov cx, 220
    mov dx, 280
    mov bx, 200
    mov si, 40
    mov al, 4          ; Red
    call draw_rect_fast
    
    ; Draw "Nova OS" title using HZK12
    mov si, title_hz
    mov word [font_x], 250
    mov word [font_y], 100
    call draw_hz_string
    
    ; Draw "Welcome" using HZK12
    mov si, welcome_hz
    mov word [font_x], 260
    mov word [font_y], 130
    call draw_hz_string
    
    ; Draw "Username:" using HZK12
    mov si, username_hz
    mov word [font_x], 150
    mov word [font_y], 165
    call draw_hz_string
    
    ; Draw "Password:" using HZK12
    mov si, password_hz
    mov word [font_x], 150
    mov word [font_y], 225
    call draw_hz_string
    
    ; Draw "Login" using HZK12
    mov si, login_hz
    mov word [font_x], 280
    mov word [font_y], 290
    call draw_hz_string
    
    ; Initialize mouse
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

; Fast rectangle drawing using BIOS interrupt
; Input: CX=X, DX=Y, BX=Width, SI=Height, AL=Color
draw_rect_fast:
    push bp
    push si
    push di
    push es
    push ax
    push bx
    push cx
    push dx
    
    mov [rect_x], cx
    mov [rect_y], dx
    mov [rect_width], bx
    mov [rect_height], si
    mov [rect_color], al
    
draw_rect_fast_row:
    mov cx, [rect_x]
    mov bx, [rect_width]
    mov dx, [rect_y]
    
draw_rect_fast_col:
    mov ah, 0x0c
    mov al, [rect_color]
    xor bh, bh
    int 0x10
    inc cx
    dec bx
    jnz draw_rect_fast_col
    
    inc word [rect_y]
    dec word [rect_height]
    jnz draw_rect_fast_row
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop di
    pop si
    pop bp
    ret

; Draw HZK12 character using 1x1 pixels
; Input: SI = pointer to HZK12 data (12 words, 24 bytes)
;        [font_x], [font_y] = starting position (will NOT be modified)
draw_hz_char:
    push bp
    push si
    push di
    push bx
    push cx
    push dx
    
    xor bp, bp        ; BP = current row (0-11)

hzk_draw_row:
    cmp bp, 12
    jae hzk_draw_done
    
    mov ax, [si]
    add si, 2
    mov cx, 12        ; CX = column counter (12 columns for HZK12)
    mov di, [font_x]  ; DI = current X position

hzk_draw_col:
    test ax, 0x8000
    jz hzk_draw_skip
    
    push ax
    push cx
    push si
    push bp
    push di
    
    mov bx, [font_y]
    add bx, bp        ; BX = Y = font_y + row
    
    ; Draw 1x1 pixel at (DI, BX)
    mov cx, di
    mov dx, bx
    mov ah, 0x0c
    mov al, 0x0F      ; White
    xor bh, bh
    int 0x10
    
    pop di
    pop bp
    pop si
    pop cx
    pop ax

hzk_draw_skip:
    shl ax, 1
    inc di            ; X += 1 (next column)
    loop hzk_draw_col
    
    inc bp            ; Next row
    jmp hzk_draw_row

hzk_draw_done:
    pop dx
    pop cx
    pop bx
    pop di
    pop si
    pop bp
    ret

; Draw 10x10 rectangle for HZK12 pixel
; Input: DI=X, BX=Y, CX=Width, DX=Height
draw_rect_12h:
    mov [rect_x], di
    mov [rect_y], bx
    mov [rect_width], cx
    mov bp, dx

rect_12h_row:
    mov si, [rect_width]
    mov di, [rect_x]
    mov dx, [rect_y]

rect_12h_pixel:
    mov cx, di
    mov ah, 0x0c
    mov al, 0x0F      ; White
    xor bh, bh
    int 0x10
    inc di
    dec si
    jnz rect_12h_pixel
    
    inc word [rect_y]
    dec bp
    jnz rect_12h_row
    ret

; Draw HZK12 string
; Input: SI = pointer to string (each char is 24 bytes)
;        Terminated by 0x0000
draw_hz_string:
    push bx
    push cx
    push dx
    push si
    push di
    push bp

draw_hz_str_loop:
    mov ax, [si]
    test ax, ax
    jz draw_hz_str_done
    
    push si
    call draw_hz_char
    pop si
    add si, 24
    add word [font_x], 24    ; 12 pixels width + 12 pixels spacing
    jmp draw_hz_str_loop

draw_hz_str_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Initialize mouse
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
    mov dx, 639
    int 0x33
    
    mov ax, 8
    mov cx, 0
    mov dx, 479
    int 0x33
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Read mouse position
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

; Draw mouse cursor
draw_mouse_cursor:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov si, [mouse_y]
    mov di, [mouse_x]
    
    ; Draw cross cursor (5x5)
    push si
    push di
    sub di, 2
    call draw_cursor_pixel
    inc di
    call draw_cursor_pixel
    inc di
    call draw_cursor_pixel
    inc di
    call draw_cursor_pixel
    inc di
    call draw_cursor_pixel
    pop di
    pop si
    
    push si
    push di
    sub si, 2
    call draw_cursor_pixel
    inc si
    call draw_cursor_pixel
    inc si
    call draw_cursor_pixel
    inc si
    call draw_cursor_pixel
    inc si
    call draw_cursor_pixel
    pop di
    pop si
    
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_cursor_pixel:
    push ax
    push bx
    push cx
    push dx
    
    mov dx, si
    mov cx, di
    
    cmp dx, 479
    ja draw_cursor_done
    cmp cx, 639
    ja draw_cursor_done
    
    mov ah, 0x0c
    mov al, 15         ; White
    xor bh, bh
    int 0x10
    
draw_cursor_done:
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
font_x: dw 0
font_y: dw 0
char_row: dw 0

mouse_x: dw 320
mouse_y: dw 240
mouse_buttons: db 0
mouse_prev_x: dw 0
mouse_prev_y: dw 0

; HZK12 font data for "Nova OS"
; Each character: 16 rows x 2 bytes = 32 bytes
; Format: Each row is 16 bits, left 12 bits are visible

title_hz:
    ; 'N' - 12x12 bitmap
    dw 0xE007
    dw 0xF00F
    dw 0xF81F
    dw 0xFC3F
    dw 0xFE7F
    dw 0xFFFF
    dw 0xFFFF
    dw 0xFF7F
    dw 0xFE3F
    dw 0xFC1F
    dw 0xF80F
    dw 0xF007
    
    ; 'o' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 'v' - 12x12 bitmap
    dw 0x8001
    dw 0x8001
    dw 0xC003
    dw 0xC003
    dw 0x6006
    dw 0x6006
    dw 0x300C
    dw 0x300C
    dw 0x1818
    dw 0x1818
    dw 0x0FF0
    dw 0x0FF0
    
    ; 'a' - 12x12 bitmap
    dw 0x0FF0
    dw 0x1FF8
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x3FFC
    dw 0x300C
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x1FF8
    dw 0x0FF0
    
    ; ' ' - space
    times 12 dw 0x0000
    
    ; 'O' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 'S' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC003
    dw 0xC003
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    
    ; Terminator
    dw 0x0000

welcome_hz:
    ; 'W' - 12x12 bitmap
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    
    ; 'e' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC003
    dw 0xFFFF
    dw 0xFFFF
    dw 0xC000
    dw 0xC000
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    dw 0x0000
    
    ; 'l' - 12x12 bitmap
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    
    ; 'c' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    
    ; 'o' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 'm' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; 'e' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC003
    dw 0xFFFF
    dw 0xFFFF
    dw 0xC000
    dw 0xC000
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    dw 0x0000
    
    ; Terminator
    dw 0x0000

username_hz:
    ; 'U' - 12x12 bitmap
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 's' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    
    ; 'e' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC003
    dw 0xFFFF
    dw 0xFFFF
    dw 0xC000
    dw 0xC000
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    dw 0x0000
    
    ; 'r' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; 'n' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; 'a' - 12x12 bitmap
    dw 0x0FF0
    dw 0x1FF8
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x3FFC
    dw 0x300C
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x1FF8
    dw 0x0FF0
    
    ; 'm' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; 'e' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC003
    dw 0xFFFF
    dw 0xFFFF
    dw 0xC000
    dw 0xC000
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    dw 0x0000
    
    ; ':' - 12x12 bitmap
    dw 0x0000
    dw 0x0000
    dw 0x1800
    dw 0x1800
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x1800
    dw 0x1800
    dw 0x0000
    dw 0x0000
    
    ; Terminator
    dw 0x0000

password_hz:
    ; 'P' - 12x12 bitmap
    dw 0x8E00
    dw 0x8E00
    dw 0x8E00
    dw 0x8E00
    dw 0x8E00
    dw 0xFC00
    dw 0xF800
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    
    ; 'a' - 12x12 bitmap
    dw 0x0FF0
    dw 0x1FF8
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x3FFC
    dw 0x300C
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x1FF8
    dw 0x0FF0
    
    ; 's' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    
    ; 's' - 12x12 bitmap
    dw 0x0000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xC000
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0x7FFE
    dw 0x3FFC
    dw 0x0000
    
    ; 'w' - 12x12 bitmap
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    dw 0x8001
    
    ; 'o' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 'r' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; 'd' - 12x12 bitmap
    dw 0x0000
    dw 0x0FF0
    dw 0x1FF8
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x3FFC
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x1FF8
    dw 0x0FF0
    
    ; ':' - 12x12 bitmap
    dw 0x0000
    dw 0x0000
    dw 0x1800
    dw 0x1800
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x1800
    dw 0x1800
    dw 0x0000
    dw 0x0000
    
    ; Terminator
    dw 0x0000

login_hz:
    ; 'L' - 12x12 bitmap
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0xFFFF
    dw 0xFFFF
    dw 0x0000
    
    ; 'o' - 12x12 bitmap
    dw 0x3FFC
    dw 0x7FFE
    dw 0xE007
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xC003
    dw 0xE007
    dw 0x7FFE
    dw 0x3FFC
    
    ; 'g' - 12x12 bitmap
    dw 0x0000
    dw 0x0FF0
    dw 0x1FF8
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x3FFC
    dw 0x300C
    dw 0x300C
    dw 0x3FFC
    dw 0x1FF8
    dw 0x0FF0
    
    ; 'i' - 12x12 bitmap
    dw 0x1800
    dw 0x1800
    dw 0x0000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    dw 0x8000
    
    ; 'n' - 12x12 bitmap
    dw 0x0000
    dw 0xF81F
    dw 0xFC3F
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    dw 0x8E71
    
    ; Terminator
    dw 0x0000