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
    
    ; Fill screen with blue background
    ; In planar mode, color 1 (blue) = plane 0 only
    mov ax, 0xA000
    mov es, ax
    
    ; Write 0xFF to plane 0 (blue bit)
    mov dx, 0x03C4
    mov al, 0x02      ; Map mask register
    mov ah, 0x01      ; Plane 0 only
    out dx, ax
    
    xor di, di
    mov cx, 38400     ; 640*480/8 bytes
    mov al, 0xFF      ; All pixels on in this plane
    rep stosb
    
    ; Write 0x00 to planes 1, 2, 3 (no red, green, intensity)
    mov dx, 0x03C4
    mov al, 0x02
    mov ah, 0x0E      ; Planes 1, 2, 3
    out dx, ax
    
    xor di, di
    mov cx, 38400
    xor al, al        ; 0x00
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

; Draw HZK12 character using BIOS interrupt (2x scaled for visibility)
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
    
    ; Calculate scaled position (2x)
    mov bx, [font_y]
    add bx, bp        ; BX = font_y + row
    shl bx, 1         ; BX = (font_y + row) * 2
    
    mov dx, di
    shl dx, 1         ; DX = col * 2
    
    ; Draw 2x2 block at (DX, BX)
    push bx
    push dx
    
    ; Pixel (0,0)
    mov cx, dx
    mov dx, bx
    mov ah, 0x0c
    mov al, 0x0F      ; White
    xor bh, bh
    int 0x10
    
    ; Pixel (1,0)
    inc cx
    mov ah, 0x0c
    mov al, 0x0F
    xor bh, bh
    int 0x10
    
    ; Pixel (0,1)
    mov cx, dx
    inc dx
    mov ah, 0x0c
    mov al, 0x0F
    xor bh, bh
    int 0x10
    
    ; Pixel (1,1)
    inc cx
    mov ah, 0x0c
    mov al, 0x0F
    xor bh, bh
    int 0x10
    
    pop dx
    pop bx
    
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
    
    add si, 24        ; Each character is 24 bytes (12 words)
    add word [font_x], 12  ; Move to next character position
    
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
    mov ax, 0x0000
    int 0x33
    test ax, ax
    jz mouse_not_present
    
    ; Show mouse cursor
    mov ax, 0x0001
    int 0x33
    
    ; Set mouse position to center
    mov ax, 0x0004
    mov cx, 320
    mov dx, 240
    int 0x33
    
    mov word [mouse_x], 320
    mov word [mouse_y], 240
    ret

mouse_not_present:
    mov word [mouse_x], 320
    mov word [mouse_y], 240
    ret

; Read mouse position
read_mouse:
    mov ax, 0x0003
    int 0x33
    mov [mouse_x], cx
    mov [mouse_y], dx
    ret

; Draw mouse cursor (simple arrow)
draw_mouse_cursor:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cx, [mouse_x]
    mov dx, [mouse_y]
    
    ; Draw cursor as a small white rectangle
    mov bx, 10
    mov si, 10
    mov al, 0x0F      ; White
    call draw_rect_fast
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data section
rect_x: dw 0
rect_y: dw 0
rect_width: dw 0
rect_height: dw 0
rect_color: db 0

font_x: dw 0
font_y: dw 0

mouse_x: dw 320
mouse_y: dw 240
mouse_prev_x: dw 0
mouse_prev_y: dw 0

; HZK12 font data for ASCII characters
; Each character: 12 rows x 2 bytes = 24 bytes
; Format: Each row is 16 bits, left 12 bits are visible

title_hz:
    ; 'N'
    dw 0xC030
    dw 0xC030
    dw 0xE030
    dw 0xF030
    dw 0xF830
    dw 0xFC30
    dw 0xDF30
    dw 0xCFB0
    dw 0xC7B0
    dw 0xC3B0
    dw 0xC1C0
    dw 0xC0E0
    
    ; 'o'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0xC0C0
    dw 0xC0C0
    dw 0xC0C0
    dw 0x6180
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'v'
    dw 0x0000
    dw 0x0000
    dw 0xC030
    dw 0xC030
    dw 0x6060
    dw 0x6060
    dw 0x30C0
    dw 0x30C0
    dw 0x1980
    dw 0x1980
    dw 0x0F00
    dw 0x0000
    
    ; 'a'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x3FC0
    dw 0x1F80
    
    ; ' '
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    
    ; 'O'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0xC0C0
    dw 0xC0C0
    dw 0xC0C0
    dw 0x6180
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'S'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x1F80
    dw 0x3FC0
    dw 0x0180
    dw 0x0180
    dw 0x3FC0
    dw 0x1F80
    
    ; Terminator
    dw 0x0000

welcome_hz:
    ; 'W'
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'e'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'l'
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    
    ; 'c'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'o'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0xC0C0
    dw 0xC0C0
    dw 0xC0C0
    dw 0x6180
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'm'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'e'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; Terminator
    dw 0x0000

username_hz:
    ; 'U'
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0x3FC0
    dw 0x1F80
    
    ; 's'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x1F80
    dw 0x3FC0
    dw 0x0180
    dw 0x0180
    dw 0x3FC0
    dw 0x1F80
    
    ; 'e'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'r'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'n'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'a'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x3FC0
    dw 0x1F80
    
    ; 'm'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'e'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; ':'
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0300
    dw 0x0300
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    
    ; Terminator
    dw 0x0000

password_hz:
    ; 'P'
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'a'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x6180
    dw 0x6180
    dw 0x7F80
    dw 0x3FC0
    dw 0x1F80
    
    ; 's'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x1F80
    dw 0x3FC0
    dw 0x0180
    dw 0x0180
    dw 0x3FC0
    dw 0x1F80
    
    ; 's'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x1F80
    dw 0x3FC0
    dw 0x0180
    dw 0x0180
    dw 0x3FC0
    dw 0x1F80
    
    ; 'w'
    dw 0x0000
    dw 0x0000
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'o'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0xC0C0
    dw 0xC0C0
    dw 0xC0C0
    dw 0x6180
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'r'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; 'd'
    dw 0x0000
    dw 0x0000
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0x3FC0
    dw 0x1F80
    
    ; ':'
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0300
    dw 0x0300
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    dw 0x0000
    
    ; Terminator
    dw 0x0000

login_hz:
    ; 'L'
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    
    ; 'o'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6180
    dw 0xC0C0
    dw 0xC0C0
    dw 0xC0C0
    dw 0x6180
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'g'
    dw 0x0000
    dw 0x0000
    dw 0x1F80
    dw 0x3FC0
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x6000
    dw 0x3FC0
    dw 0x1F80
    dw 0x0000
    
    ; 'i'
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    dw 0xC000
    
    ; 'n'
    dw 0x0000
    dw 0x0000
    dw 0x7F80
    dw 0x7F80
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    dw 0xC030
    
    ; Terminator
    dw 0x0000