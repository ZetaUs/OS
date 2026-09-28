bits 32

; VGA framebuffer address
VGA_MEMORY equ 0xA0000
SCREEN_WIDTH equ 320

; Colors
COLOR_BG equ 1
COLOR_BORDER equ 8
COLOR_INNER equ 0
COLOR_BUTTON equ 14
COLOR_TEXT equ 0
COLOR_MOUSE equ 15

global _login_screen

section .text

_login_screen:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Clear screen with blue background
    mov edi, VGA_MEMORY
    mov ecx, 320 * 200
    mov al, COLOR_BG
    rep stosb
    
    ; Draw login box border (x=80, y=40, w=160, h=120, color=8)
    push COLOR_BORDER
    push 120
    push 160
    push 40
    push 80
    call draw_rect
    add esp, 20
    
    ; Draw "登录" button (x=110, y=90, w=100, h=16, color=14)
    push COLOR_BUTTON
    push 16
    push 100
    push 90
    push 110
    call draw_rect
    add esp, 20
    
    ; Draw "Login" text on button (black color)
    ; L at (130, 94)
    push 0
    push 94
    push 130
    call draw_char_L
    add esp, 12
    
    ; o at (138, 94)
    push 0
    push 94
    push 138
    call draw_char_o
    add esp, 12
    
    ; g at (146, 94)
    push 0
    push 94
    push 146
    call draw_char_g
    add esp, 12
    
    ; i at (154, 94)
    push 0
    push 94
    push 154
    call draw_char_i
    add esp, 12
    
    ; n at (158, 94)
    push 0
    push 94
    push 158
    call draw_char_n
    add esp, 12
    
    ; Main loop: wait for Enter key
.wait_loop:
    ; Check keyboard input
    in al, 0x64
    test al, 1
    jz .wait_loop
    
    in al, 0x60
    cmp al, 0x1C    ; Enter key pressed
    je .login_exit
    cmp al, 0x9C    ; Enter key released
    je .login_exit
    
    jmp .wait_loop

; Simple 5x7 character drawing functions
; L
draw_char_L:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    movzx edx, byte [ebp+16]  ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, .L_bits
    mov ebx, 7
.L_row:
    mov ecx, 5
.L_col:
    lodsb
    test al, al
    jz .L_skip
    mov byte [edi], dl
.L_skip:
    inc edi
    dec ecx
    jnz .L_col
    add edi, SCREEN_WIDTH - 5
    dec ebx
    jnz .L_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
.L_bits:
    db 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0
    db 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1

; o
draw_char_o:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    movzx edx, byte [ebp+16]
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, .o_bits
    mov ebx, 7
.o_row:
    mov ecx, 5
.o_col:
    lodsb
    test al, al
    jz .o_skip
    mov byte [edi], dl
.o_skip:
    inc edi
    dec ecx
    jnz .o_col
    add edi, SCREEN_WIDTH - 5
    dec ebx
    jnz .o_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
.o_bits:
    db 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0
    db 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0

; g
draw_char_g:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    movzx edx, byte [ebp+16]
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, .g_bits
    mov ebx, 7
.g_row:
    mov ecx, 5
.g_col:
    lodsb
    test al, al
    jz .g_skip
    mov byte [edi], dl
.g_skip:
    inc edi
    dec ecx
    jnz .g_col
    add edi, SCREEN_WIDTH - 5
    dec ebx
    jnz .g_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
.g_bits:
    db 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0
    db 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0

; i
draw_char_i:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    movzx edx, byte [ebp+16]
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, .i_bits
    mov ebx, 7
.i_row:
    mov ecx, 3
.i_col:
    lodsb
    test al, al
    jz .i_skip
    mov byte [edi], dl
.i_skip:
    inc edi
    dec ecx
    jnz .i_col
    add edi, SCREEN_WIDTH - 3
    dec ebx
    jnz .i_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
.i_bits:
    db 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0
    db 1, 0, 0, 1, 0, 0, 1, 0, 0

; n
draw_char_n:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    movzx edx, byte [ebp+16]
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, .n_bits
    mov ebx, 7
.n_row:
    mov ecx, 5
.n_col:
    lodsb
    test al, al
    jz .n_skip
    mov byte [edi], dl
.n_skip:
    inc edi
    dec ecx
    jnz .n_col
    add edi, SCREEN_WIDTH - 5
    dec ebx
    jnz .n_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
.n_bits:
    db 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0
    db 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0

; Character bitmap data (from expand_chars.py)
.deng_bits:
    db 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0
    db 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0
    db 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0
    db 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0
    db 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0
    db 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1
    db 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0
    db 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0
    db 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0
    db 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0
    db 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0
    db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

.lu_bits:
    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0
    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0
    db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    db 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0
    db 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0
    db 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0
    db 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0
    db 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1
    db 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0
    db 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0

.login_exit:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Function: draw_rect
; Stack: [ebp+8]=x, [ebp+12]=y, [ebp+16]=width, [ebp+20]=height, [ebp+24]=color
draw_rect:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    mov ecx, [ebp+16]     ; width
    mov edx, [ebp+20]     ; height
    movzx esi, byte [ebp+24]  ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
.draw_row:
    push ecx
    mov ecx, [ebp+16]
    mov eax, esi
.draw_col:
    mov byte [edi], al
    inc edi
    dec ecx
    jnz .draw_col
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, [ebp+16]
    dec edx
    jnz .draw_row
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Function: mouse_init
; Initialize PS/2 mouse
mouse_init:
    push eax
    
    ; Enable mouse port
    mov al, 0xA8
    out 0x64, al
    
    ; Get current command byte
    mov al, 0x20
    out 0x64, al
    in al, 0x60
    or al, 0x02
    mov al, 0x60
    out 0x64, al
    mov al, 0x02
    out 0x60, al
    
    ; Enable mouse
    mov al, 0xD4
    out 0x64, al
    mov al, 0xF4
    out 0x60, al
    in al, 0x60
    
    pop eax
    ret

; Function: mouse_update
; Read mouse movement and update position
; Returns: eax=1 if moved, eax=0 if no data
mouse_update:
    push ebx
    push ecx
    
    ; Check if data available
    in al, 0x64
    test al, 1
    jz .no_data
    
    in al, 0x60
    
    ; Check sync bit
    test al, 0x08
    jz .no_data
    
    ; Read X movement
    in al, 0x64
    test al, 1
    jz .no_data
    in al, 0x60
    movsx ecx, al
    
    ; Read Y movement
    in al, 0x64
    test al, 1
    jz .no_data
    in al, 0x60
    movsx ebx, al
    
    ; Update position
    mov eax, [g_mouse_x]
    add eax, ecx
    cmp eax, 0
    jl .clamp_x
    cmp eax, 307
    jg .clamp_x_max
    mov [g_mouse_x], eax
    jmp .update_y
    
.clamp_x:
    mov eax, 0
    mov [g_mouse_x], eax
    jmp .update_y
    
.clamp_x_max:
    mov eax, 307
    mov [g_mouse_x], eax
    
.update_y:
    mov eax, [g_mouse_y]
    sub eax, ebx
    cmp eax, 0
    jl .clamp_y
    cmp eax, 184
    jg .clamp_y_max
    mov [g_mouse_y], eax
    jmp .moved
    
.clamp_y:
    mov eax, 0
    mov [g_mouse_y], eax
    jmp .moved
    
.clamp_y_max:
    mov eax, 184
    mov [g_mouse_y], eax
    
.moved:
    mov eax, 1
    pop ecx
    pop ebx
    ret
    
.no_data:
    xor eax, eax
    pop ecx
    pop ebx
    ret

; Function: draw_mouse_cursor
; Stack: [ebp+8]=x, [ebp+12]=y, [ebp+16]=color
draw_mouse_cursor:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    movzx edx, byte [ebp+16]  ; color (in dl)
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; Save current position
    mov [prev_mouse_x], eax
    mov [prev_mouse_y], ebx
    
    ; Draw mouse (13x16)
    mov ecx, 16           ; height
    xor ebx, ebx          ; row index
    
.row_loop_mouse:
    push ecx
    mov ecx, 13           ; width
    xor esi, esi          ; col index
    
.col_loop_mouse:
    mov eax, ebx
    imul eax, 13
    add eax, esi
    movzx eax, byte [mouse_data + eax]
    cmp eax, 14
    jne .skip_pixel
    
    mov byte [edi], dl
    
.skip_pixel:
    inc edi
    inc esi
    dec ecx
    jnz .col_loop_mouse
    
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, 13
    inc ebx
    dec ecx
    jnz .row_loop_mouse
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Chinese character "登" (12x12) - index 117
draw_chinese_deng:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    movzx edx, byte [ebp+16]  ; color (in dl)
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; 登 bitmap data (12x12 = 144 bytes, 0 or 1)
    mov esi, deng_expanded
    mov ebx, 12  ; row counter
.deng_row:
    mov ecx, 12  ; col counter
.deng_col:
    movzx eax, byte [esi]
    test eax, eax
    jz .deng_skip
    mov byte [edi], dl
.deng_skip:
    inc edi
    inc esi
    dec ecx
    jnz .deng_col
    add edi, SCREEN_WIDTH - 12  ; move to next row
    dec ebx
    jnz .deng_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Chinese character "录" (12x12) - index 118
draw_chinese_lu:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    movzx edx, byte [ebp+16]  ; color (in dl)
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; 录 bitmap data (12x12 = 144 bytes, 0 or 1)
    mov esi, lu_expanded
    mov ebx, 12  ; row counter
.lu_row:
    mov ecx, 12  ; col counter
.lu_col:
    movzx eax, byte [esi]
    test eax, eax
    jz .lu_skip
    mov byte [edi], dl
.lu_skip:
    inc edi
    inc esi
    dec ecx
    jnz .lu_col
    add edi, SCREEN_WIDTH - 12  ; move to next row
    dec ebx
    jnz .lu_row
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

section .data
    ; Include mouse cursor data
    %include "mouse_data.inc"
    
    ; 登 expanded bitmap (12x12 = 144 bytes, 0 or 1)
    deng_expanded: db 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0
                   db 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0
                   db 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0
                   db 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0
                   db 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
                   db 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0
                   db 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0
                   db 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
                   db 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
                   db 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0
                   db 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1
                   db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    
    ; 录 expanded bitmap (12x12 = 144 bytes, 0 or 1)
    lu_expanded: db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
                 db 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0
                 db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
                 db 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0
                 db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                 db 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0
                 db 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0
                 db 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0
                 db 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0
                 db 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1
                 db 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0
                 db 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0

section .bss
    g_mouse_x resd 1
    g_mouse_y resd 1
    prev_mouse_x resd 1
    prev_mouse_y resd 1