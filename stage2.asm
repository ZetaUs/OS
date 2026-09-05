bits 16
org 0x7E00

start:
    ; Initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Set video mode 0x13 (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10
    
    ; === Enable VGA Chain-4 Mode ===
    ; Step 1: Reset Sequencer
    mov dx, 0x03C4
    mov al, 0x00
    out dx, al
    inc dx
    mov al, 0x01
    out dx, al
    
    ; Step 2: Enable Chain-4 in Sequencer Memory Mode
    mov dx, 0x03C4
    mov al, 0x04
    out dx, al
    inc dx
    mov al, 0x0E
    out dx, al
    
    ; Step 3: Enable Chain-4 in Graphics Controller Mode
    mov dx, 0x03CE
    mov al, 0x05
    out dx, al
    inc dx
    mov al, 0x40
    out dx, al
    
    ; Step 4: Clear Sequencer Reset
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
    
    ; Fill entire screen with dark blue (color 1)
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    ; Initialize VGA palette
    call init_palette
    
    ; === Load HZK16 from disk ===
    ; HZK16 is at LBA 115, 523 sectors (267616 bytes)
    ; Load to memory at 0x10000 (ES:BX = 0x1000:0x0000)
    mov si, hzk_dap
    mov word [si+2], 523       ; Sector count
    mov word [si+4], 0x0000    ; Buffer offset
    mov word [si+6], 0x1000    ; Buffer segment
    mov dword [si+8], 115      ; LBA low
    mov dword [si+12], 0       ; LBA high
    
    mov ah, 0x42               ; LBA extended read
    mov dl, [0x0500]           ; Boot drive
    int 0x13
    jc hzk_load_error
    
    ; HZK16 loaded successfully at 0x10000
    ; DS=0x1000 for accessing HZK16
    mov ax, 0x1000
    mov ds, ax
    
    ; === Draw Loading Interface ===
    
    ; Draw title "Nova OS" at top center (using 8x8 font for English)
    ; First copy 8x8 font to 0x8000
    xor ax, ax
    mov es, ax
    mov si, font_8x8
    mov di, 0x8000
    mov cx, 768
    cld
    rep movsb
    
    ; Reset DS to 0x0000 for font access
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; Draw "Nova OS" title
    mov si, title_msg
    mov bp, 120
    mov dx, 10
    call draw_string_8x8
    
    ; Draw "欢迎使用" (Welcome) below title
    ; Reset DS to HZK segment
    mov ax, 0x1000
    mov ds, ax
    
    mov si, welcome_msg
    mov bp, 104
    mov dx, 28
    call draw_string_16x16
    
    ; Draw loading bar background (gray rectangle)
    xor ax, ax
    mov ds, ax
    mov cx, 60
    mov dx, 165
    mov bx, 200
    mov si, 14
    mov al, 2
    call draw_rect
    
    ; Animate loading bar (light blue filling)
    mov bx, 0
load_loop:
    push bx
    xor ax, ax
    mov ds, ax
    mov cx, 60
    mov dx, 165
    mov bx, [load_width]
    mov si, 14
    mov al, 3
    call draw_rect
    add word [load_width], 4
    pop bx
    cmp word [load_width], 200
    jb load_loop
    
    ; Draw "加载中..." text
    mov ax, 0x1000
    mov ds, ax
    mov si, loading_msg
    mov bp, 112
    mov dx, 182
    call draw_string_16x16
    
    ; === Draw Login Interface ===
    
    ; Draw login box background (dark gray)
    xor ax, ax
    mov ds, ax
    mov cx, 30
    mov dx, 55
    mov bx, 260
    mov si, 120
    mov al, 4
    call draw_rect
    
    ; Draw username label "用户名:"
    mov ax, 0x1000
    mov ds, ax
    mov si, username_msg
    mov bp, 40
    mov dx, 65
    call draw_string_16x16
    
    ; Draw username input box (light gray)
    xor ax, ax
    mov ds, ax
    mov cx, 40
    mov dx, 85
    mov bx, 240
    mov si, 20
    mov al, 5
    call draw_rect
    
    ; Draw password label "密码:"
    mov ax, 0x1000
    mov ds, ax
    mov si, password_msg
    mov bp, 48
    mov dx, 115
    call draw_string_16x16
    
    ; Draw password input box (light gray)
    xor ax, ax
    mov ds, ax
    mov cx, 40
    mov dx, 135
    mov bx, 240
    mov si, 20
    mov al, 5
    call draw_rect
    
    ; Draw login button (blue)
    mov cx, 110
    mov dx, 165
    mov bx, 100
    mov si, 24
    mov al, 6
    call draw_rect
    
    ; Draw "登录" text on button
    mov ax, 0x1000
    mov ds, ax
    mov si, login_msg
    mov bp, 142
    mov dx, 170
    call draw_string_16x16
    
    ; Infinite loop
halt_s2:
    hlt
    jmp halt_s2

hzk_load_error:
    ; If HZK16 load fails, just halt
    hlt
    jmp halt_s2

load_width: dw 0

; ============================================================
; VGA Palette Initialization
; ============================================================
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
    
    ; Color 1: Dark Blue (background)
    xor al, al
    out dx, al
    xor al, al
    out dx, al
    mov al, 42
    out dx, al
    
    ; Color 2: Gray (loading bar background)
    mov al, 32
    out dx, al
    out dx, al
    out dx, al
    
    ; Color 3: Light Blue (loading bar)
    mov al, 21
    out dx, al
    mov al, 42
    out dx, al
    mov al, 63
    out dx, al
    
    ; Color 4: Dark Gray (login box)
    mov al, 21
    out dx, al
    out dx, al
    out dx, al
    
    ; Color 5: Light Gray (input boxes)
    mov al, 42
    out dx, al
    out dx, al
    out dx, al
    
    ; Color 6: Blue (login button)
    xor al, al
    out dx, al
    xor al, al
    out dx, al
    mov al, 63
    out dx, al
    
    ; Color 7: White (text)
    mov al, 63
    out dx, al
    out dx, al
    out dx, al
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; Draw a filled rectangle
; Input: CX=X, DX=Y, BX=Width, SI=Height, AL=Color
; ============================================================
draw_rect:
    push bp
    push si
    push di
    push es
    
    ; Save parameters to memory variables
    mov [rect_x], cx
    mov [rect_y], dx
    mov [rect_width], bx
    mov [rect_height], si
    mov [rect_color], al
    
    ; Set ES to VRAM
    mov ax, 0xA000
    mov es, ax
    
    ; Initialize row counter
    mov bp, dx           ; BP = current Y
    mov si, [rect_height] ; SI = height counter
    
draw_rect_row:
    ; Calculate VRAM offset: Y * 320 + X
    mov ax, bp           ; AX = Y
    mov bx, 320
    mul bx               ; DX:AX = Y * 320
    add ax, [rect_x]     ; AX = Y * 320 + X
    mov di, ax
    
    ; Draw one row using rep stosb
    mov cx, [rect_width]
    mov al, [rect_color]
    rep stosb
    
    inc bp               ; Y++
    dec si               ; height--
    jnz draw_rect_row
    
    pop es
    pop di
    pop si
    pop bp
    ret

; Rectangle parameters storage
rect_x: dw 0
rect_y: dw 0
rect_width: dw 0
rect_height: dw 0
rect_color: db 0

; ============================================================
; Draw a 16x16 Chinese character from HZK16
; Input: DS:SI -> GB2312 string, BP=X, DX=Y
; DS should be 0x1000 (HZK16 segment)
; ============================================================
draw_char_16x16:
    push ax
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
    
    ; Calculate HZK16 offset from GB2312 code
    ; GB2312: high byte = 区号 + 0xA0, low byte = 位号 + 0xA0
    ; Offset = ((区号 - 1) * 94 + (位号 - 1)) * 32
    ; Simplified: ((high - 0xA1) * 94 + (low - 0xA1)) * 32
    
    mov al, [si]         ; High byte (区号)
    mov ah, [si+1]       ; Low byte (位号)
    
    sub al, 0xA1         ; 区号 - 1
    sub ah, 0xA1         ; 位号 - 1
    
    ; Calculate offset: (al * 94 + ah) * 32
    mov bl, al
    mov bh, 0
    mov ax, bx
    mov bx, 94
    mul bx               ; AX = al * 94
    add ax, bx           ; Wait, need to add ah
    ; Let me redo this properly
    mov bl, al
    mov bh, 0
    mov cx, 94
    mul cx               ; DX:AX = al * 94
    add ax, [si+1]       ; Add low byte
    sub ax, 0xA1         ; Subtract 0xA1
    ; AX = (al - 0xA1) * 94 + (ah - 0xA1)
    
    ; Multiply by 32 (shift left 5)
    shl ax, 5            ; AX = offset in HZK16
    
    ; DS is already 0x1000 (HZK16 segment)
    ; SI = offset in HZK16
    mov si, ax
    
    ; Set ES to VRAM
    mov ax, 0xA000
    mov es, ax
    
    ; Draw 16 rows
    mov cx, 16
    mov [char16_row], cx
    xor bx, bx           ; Row counter
    
draw_char16_row:
    ; Get 2 bytes for this row (16 bits)
    mov al, [si]
    mov ah, [si+1]
    add si, 2
    
    ; Calculate Y position
    mov dx, [char16_y]
    add dx, bx
    
    ; Calculate VRAM offset: Y * 320 + X
    mov bp, dx
    mov ax, 320
    mul bp
    mov di, ax
    add di, [char16_x]
    
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
    pop ax
    ret

char16_x: dw 0
char16_y: dw 0
char16_row: dw 0

; ============================================================
; Draw a string of 16x16 Chinese characters
; Input: DS:SI -> GB2312 string, BP=X, DX=Y
; ============================================================
draw_string_16x16:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    
draw_str16_loop:
    lodsb
    test al, al
    jz draw_str16_done
    
    ; Check if it's a GB2312 character (high byte >= 0xA0)
    cmp al, 0xA0
    jb draw_str16_ascii
    
    ; GB2312 character, get next byte
    mov ah, [si-1]       ; Actually we need the byte we just read
    ; Let me fix this
    dec si               ; Go back
    lodsb                ; Read high byte into AL
    mov bl, al           ; Save high byte
    lodsb                ; Read low byte into AL
    mov bh, al           ; Save low byte
    
    ; Now draw the character
    ; DS:SI-2 points to the character
    push bp
    push dx
    mov si, bp           ; We need to pass the character pointer
    ; This is getting complicated, let me simplify
    
    ; Actually, let me just use the original SI
    ; SI now points after the character
    ; Character is at SI-2
    push si
    sub si, 2
    
    call draw_char_16x16
    
    pop si
    pop dx
    pop bp
    add bp, 16           ; Move to next character
    jmp draw_str16_loop
    
draw_str16_ascii:
    ; ASCII character (for now, just skip)
    add bp, 8
    jmp draw_str16_loop
    
draw_str16_done:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; Draw an 8x8 character using embedded font
; Input: AL=Character, BP=X, DX=Y
; ============================================================
draw_char_8x8:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
    
    ; DS=0x0000 for font access
    xor ax, ax
    mov ds, ax
    
    ; Save original X and Y
    mov [char_x], bp
    mov [char_y], dx
    
    ; Calculate font offset: (char - 0x20) * 8
    sub al, 0x20
    mov ah, 0
    mov bx, ax
    shl bx, 3            ; BX = (char - 0x20) * 8
    
    ; SI = 0x8000 + offset
    mov si, 0x8000
    add si, bx
    
    ; Set ES to VRAM
    mov ax, 0xA000
    mov es, ax
    
    ; Draw 8 rows
    mov cx, 8
    mov [char_row], cx
draw_char_row:
    mov al, [si]
    inc si
    
    mov dx, [char_y]
    mov ax, 8
    sub ax, [char_row]
    add dx, ax
    
    mov bp, dx
    mov ax, 320
    mul bp
    mov di, ax
    add di, [char_x]
    
    mov cx, 8
draw_char_pixel:
    push cx
    push ax
    
    test al, 0x80
    jz skip_pixel
    
    mov al, 7
    stosb
    jmp next_pixel
    
skip_pixel:
    inc di
    
next_pixel:
    pop ax
    pop cx
    
    shl al, 1
    loop draw_char_pixel
    
    dec word [char_row]
    jnz draw_char_row
    
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

char_x: dw 0
char_y: dw 0
char_row: dw 0

; ============================================================
; Draw a string using 8x8 font
; Input: SI=String pointer, BP=X, DX=Y
; ============================================================
draw_string_8x8:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    
    ; DS=0x0000 for font access
    xor ax, ax
    mov ds, ax
    
draw_str_loop:
    lodsb
    test al, al
    jz draw_str_done
    
    push si
    push bp
    push dx
    
    call draw_char_8x8
    
    pop dx
    pop bp
    add bp, 8
    pop si
    
    jmp draw_str_loop
    
draw_str_done:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================
; 8x8 Font Data
; ============================================================
font_8x8:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
    db 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x24, 0x7E, 0x24, 0x24, 0x7E, 0x24, 0x00
    db 0x18, 0x3E, 0x40, 0x3C, 0x06, 0x7C, 0x18, 0x00
    db 0x00, 0x62, 0x64, 0x08, 0x10, 0x26, 0x46, 0x00
    db 0x1C, 0x22, 0x22, 0x1C, 0x2A, 0x44, 0x3A, 0x00
    db 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x0C, 0x18, 0x30, 0x30, 0x30, 0x18, 0x0C, 0x00
    db 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x18, 0x30, 0x00
    db 0x00, 0x08, 0x3E, 0x1C, 0x1C, 0x3E, 0x08, 0x00
    db 0x00, 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x08, 0x00
    db 0x00, 0x00, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00
    db 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x40, 0x00
    db 0x1C, 0x22, 0x26, 0x2A, 0x32, 0x22, 0x1C, 0x00
    db 0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00
    db 0x1C, 0x22, 0x04, 0x08, 0x10, 0x20, 0x3E, 0x00
    db 0x3C, 0x06, 0x0C, 0x08, 0x0C, 0x06, 0x3C, 0x00
    db 0x08, 0x18, 0x28, 0x48, 0x7E, 0x08, 0x08, 0x00
    db 0x3E, 0x20, 0x3C, 0x06, 0x06, 0x26, 0x1C, 0x00
    db 0x1C, 0x20, 0x3C, 0x26, 0x26, 0x26, 0x1C, 0x00
    db 0x3E, 0x04, 0x08, 0x10, 0x10, 0x10, 0x10, 0x00
    db 0x1C, 0x26, 0x26, 0x1C, 0x26, 0x26, 0x1C, 0x00
    db 0x1C, 0x26, 0x26, 0x1E, 0x06, 0x0C, 0x18, 0x00
    db 0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00
    db 0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x08, 0x00
    db 0x04, 0x08, 0x10, 0x20, 0x10, 0x08, 0x04, 0x00
    db 0x00, 0x00, 0x3E, 0x00, 0x3E, 0x00, 0x00, 0x00
    db 0x20, 0x10, 0x08, 0x04, 0x08, 0x10, 0x20, 0x00
    db 0x1C, 0x26, 0x06, 0x0C, 0x18, 0x00, 0x18, 0x00
    db 0x1C, 0x26, 0x26, 0x2E, 0x2A, 0x20, 0x1C, 0x00
    db 0x18, 0x24, 0x24, 0x3C, 0x42, 0x42, 0x42, 0x00
    db 0x3C, 0x22, 0x22, 0x3C, 0x22, 0x22, 0x3C, 0x00
    db 0x1C, 0x26, 0x40, 0x40, 0x40, 0x26, 0x1C, 0x00
    db 0x38, 0x24, 0x22, 0x22, 0x22, 0x24, 0x38, 0x00
    db 0x3E, 0x20, 0x20, 0x38, 0x20, 0x20, 0x3E, 0x00
    db 0x3E, 0x20, 0x20, 0x38, 0x20, 0x20, 0x20, 0x00
    db 0x1C, 0x26, 0x40, 0x40, 0x4E, 0x26, 0x1E, 0x00
    db 0x42, 0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00
    db 0x3C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00
    db 0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x4C, 0x38, 0x00
    db 0x44, 0x48, 0x50, 0x60, 0x50, 0x48, 0x44, 0x00
    db 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3E, 0x00
    db 0x42, 0x66, 0x5A, 0x5A, 0x42, 0x42, 0x42, 0x00
    db 0x42, 0x62, 0x52, 0x4A, 0x46, 0x42, 0x42, 0x00
    db 0x1C, 0x26, 0x42, 0x42, 0x42, 0x26, 0x1C, 0x00
    db 0x3C, 0x22, 0x22, 0x3C, 0x20, 0x20, 0x20, 0x00
    db 0x1C, 0x26, 0x42, 0x42, 0x4A, 0x2C, 0x16, 0x00
    db 0x3C, 0x22, 0x22, 0x3C, 0x28, 0x24, 0x42, 0x00
    db 0x1E, 0x20, 0x20, 0x1C, 0x06, 0x06, 0x3C, 0x00
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00
    db 0x42, 0x42, 0x42, 0x42, 0x42, 0x26, 0x1C, 0x00
    db 0x42, 0x42, 0x42, 0x24, 0x24, 0x18, 0x18, 0x00
    db 0x42, 0x42, 0x42, 0x5A, 0x5A, 0x66, 0x42, 0x00
    db 0x42, 0x24, 0x18, 0x18, 0x18, 0x24, 0x42, 0x00
    db 0x42, 0x24, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00
    db 0x3E, 0x04, 0x08, 0x10, 0x20, 0x40, 0x3E, 0x00
    db 0x3C, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3C, 0x00
    db 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x02, 0x00
    db 0x3C, 0x04, 0x04, 0x04, 0x04, 0x04, 0x3C, 0x00
    db 0x18, 0x24, 0x42, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF
    db 0x18, 0x0C, 0x00, 0x00, 0