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
    
    ; Draw background (blue)
    mov cx, 0
    mov dx, 0
    mov bx, 640
    mov si, 480
    mov al, 1          ; Blue
    call draw_rect
    
    ; Draw login box (gray)
    mov cx, 120
    mov dx, 80
    mov bx, 400
    mov si, 320
    mov al, 7          ; White/Light gray
    call draw_rect
    
    ; Draw input fields (darker gray)
    mov cx, 140
    mov dx, 160
    mov bx, 360
    mov si, 30
    mov al, 8          ; Dark gray
    call draw_rect
    
    mov cx, 140
    mov dx, 220
    mov bx, 360
    mov si, 30
    mov al, 8
    call draw_rect
    
    ; Draw login button (red)
    mov cx, 220
    mov dx, 280
    mov bx, 200
    mov si, 40
    mov al, 4          ; Red
    call draw_rect
    
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

; Draw rectangle using BIOS int 0x10
; Input: CX=X, DX=Y, BX=Width, SI=Height, AL=Color
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
    
draw_rect_row:
    mov cx, [rect_x]
    mov bx, [rect_width]
draw_rect_col:
    push dx
    push cx
    mov di, cx
    mov bx, [rect_y]
    mov cx, 1
    mov dx, 1
    mov ah, 0x0c
    mov al, [rect_color]
    xor bh, bh
    int 0x10
    pop cx
    pop dx
    inc cx
    dec word [rect_width]
    jnz draw_rect_col
    inc word [rect_y]
    dec word [rect_height]
    jnz draw_rect_row
    
    pop es
    pop di
    pop si
    pop bp
    ret

; Draw HZK12 character
; Input: SI = pointer to HZK12 data (16 words, 32 bytes)
;        [font_x], [font_y] = position
draw_hz_char:
    push bp
    push si
    push di
    push bx
    push cx
    push dx
    
    mov word [char_row], 0

hzk_draw_row:
    cmp word [char_row], 16
    jae hzk_draw_done
    
    mov ax, [si]
    add si, 2
    mov cx, 16
    mov dx, [font_x]

hzk_draw_col:
    test ax, 0x8000
    jz hzk_draw_skip
    
    push ax
    push cx
    push si
    push bp
    push dx
    
    mov di, dx
    mov bx, [font_y]
    add bx, [char_row]
    mov cx, 1
    mov dx, 1
    mov ah, 0x0c
    mov al, 0          ; Black
    xor bh, bh
    int 0x10
    
    pop dx
    pop bp
    pop si
    pop cx
    pop ax

hzk_draw_skip:
    shl ax, 1
    add dx, 12
    loop hzk_draw_col
    
    inc word [char_row]
    jmp hzk_draw_row

hzk_draw_done:
    pop dx
    pop cx
    pop bx
    pop di
    pop si
    pop bp
    ret

; Draw HZK12 string
; Input: SI = pointer to string (each char is 32 bytes)
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
    add si, 32
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

; HZK12 font data for "Nova OS" (simplified ASCII representation)
; Each character: 16 rows x 2 bytes = 32 bytes
; Using simple patterns for demonstration

title_hz:
    ; 'N' - 16x12 bitmap
    dw 0x8001, 0x8001
    dw 0xC003, 0xC003
    dw 0xE007, 0xE007
    dw 0xF00F, 0xF00F
    dw 0xF81F, 0xF81F
    dw 0xFC3F, 0xFC3F
    dw 0xFE7F, 0xFE7F
    dw 0xFFFF, 0xFFFF
    dw 0xFFFF, 0xFFFF
    dw 0xFF7F, 0xFF7F
    dw 0xFE3F, 0xFE3F
    dw 0xFC1F, 0xFC1F
    dw 0xF80F, 0xF80F
    dw 0xF007, 0xF007
    dw 0xE003, 0xE003
    dw 0xC001, 0xC001
    
    ; 'o' - 16x12 bitmap
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x3FFC, 0x3FFC
    dw 0x7FFE, 0x7FFE
    dw 0xE007, 0xE007
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xE007, 0xE007
    dw 0x7FFE, 0x7FFE
    dw 0x3FFC, 0x3FFC
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; 'v' - 16x12 bitmap
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0x6006, 0x6006
    dw 0x6006, 0x6006
    dw 0x300C, 0x300C
    dw 0x300C, 0x300C
    dw 0x1818, 0x1818
    dw 0x1818, 0x1818
    dw 0x0FF0, 0x0FF0
    dw 0x0FF0, 0x0FF0
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; 'a' - 16x12 bitmap
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0FF0, 0x0FF0
    dw 0x1FF8, 0x1FF8
    dw 0x300C, 0x300C
    dw 0x300C, 0x300C
    dw 0x3FFC, 0x3FFC
    dw 0x3FFC, 0x3FFC
    dw 0x300C, 0x300C
    dw 0x300C, 0x300C
    dw 0x300C, 0x300C
    dw 0x3FFC, 0x3FFC
    dw 0x1FF8, 0x1FF8
    dw 0x0FF0, 0x0FF0
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; ' ' - space
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; 'O' - 16x12 bitmap
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x3FFC, 0x3FFC
    dw 0x7FFE, 0x7FFE
    dw 0xE007, 0xE007
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0xE007, 0xE007
    dw 0x7FFE, 0x7FFE
    dw 0x3FFC, 0x3FFC
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; 'S' - 16x12 bitmap
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x3FFC, 0x3FFC
    dw 0x7FFE, 0x7FFE
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0x3FFC, 0x3FFC
    dw 0x7FFE, 0x7FFE
    dw 0xE007, 0xE007
    dw 0xC003, 0xC003
    dw 0xC003, 0xC003
    dw 0x7FFE, 0x7FFE
    dw 0x3FFC, 0x3FFC
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    dw 0x0000, 0x0000
    
    ; Terminator
    dw 0x0000, 0x0000

welcome_hz:
    ; 'W' - 16x12 bitmap
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8001
    dw 0x8001, 0x8