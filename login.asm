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

; Mouse data (13x16 arrow cursor, value 14 = visible)
%include "mouse_data.inc"

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
    
    ; Draw inner box (x=82, y=42, w=152, h=116, color=0)
    push COLOR_INNER
    push 116
    push 152
    push 42
    push 82
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
    
    ; Draw Chinese characters "登录" (simplified: draw as dots for now)
    ; 登: 12x12 at (148, 93), color=0
    push COLOR_TEXT
    push 93
    push 148
    call draw_chinese_deng
    add esp, 12
    
    ; 录: 12x12 at (160, 93), color=0
    push COLOR_TEXT
    push 93
    push 160
    call draw_chinese_lu
    add esp, 12
    
    ; Initialize PS/2 mouse
    call mouse_init
    
    ; Draw initial mouse cursor at (160, 100)
    push COLOR_MOUSE
    push 100
    push 160
    call draw_mouse_cursor
    add esp, 12
    
    ; Main loop: wait for Enter key or mouse click on button
.wait_loop:
    ; Check keyboard
    in al, 0x64
    test al, 1
    jz .check_mouse
    
    in al, 0x60
    cmp al, 0x1C
    je .login_exit
    cmp al, 0x9C
    je .login_exit
    
.check_mouse:
    ; Read mouse data
    call mouse_update
    cmp eax, 0
    je .no_mouse_move
    
    ; Redraw: clear old cursor, draw new cursor
    push COLOR_BG
    push [prev_mouse_y]
    push [prev_mouse_x]
    call draw_mouse_cursor
    add esp, 12
    
    push COLOR_MOUSE
    push [g_mouse_y]
    push [g_mouse_x]
    call draw_mouse_cursor
    add esp, 12
    
    ; Check if mouse is on button (x:110-210, y:90-106)
    mov eax, [g_mouse_x]
    cmp eax, 110
    jl .no_click
    cmp eax, 210
    jg .no_click
    mov eax, [g_mouse_y]
    cmp eax, 90
    jl .no_click
    cmp eax, 106
    jg .no_click
    
    ; Mouse is on button, check for left click
    in al, 0x64
    test al, 1
    jz .no_click
    in al, 0x60
    test al, 1
    jnz .login_exit
    
.no_click:
.no_mouse_move:
    ; HLT to reduce CPU usage
    hlt
    jmp .wait_loop

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
    mov esi, [ebp+24]     ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    and esi, 0xFF
    
.row_loop:
    push ecx
.col_loop:
    mov byte [edi], sil
    inc edi
    dec ecx
    jnz .col_loop
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, [ebp+16]
    dec edx
    jnz .row_loop
    
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
    push esi
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    mov esi, [ebp+16]     ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; Save current position
    mov [prev_mouse_x], eax
    mov [prev_mouse_y], ebx
    
    ; Draw mouse (13x16)
    mov ecx, 16           ; height
    xor edx, edx          ; row index
    
.row_loop_mouse:
    push ecx
    mov ecx, 13           ; width
    xor esi, esi          ; col index
    
.col_loop_mouse:
    movzx eax, byte [mouse_data + edx * 13 + esi]
    cmp eax, 14
    jne .skip_pixel
    
    mov byte [edi], sil
    
.skip_pixel:
    inc edi
    inc esi
    dec ecx
    jnz .col_loop_mouse
    
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, 13
    inc edx
    dec ecx
    jnz .row_loop_mouse
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Chinese character "登" (12x12)
draw_chinese_deng:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    mov esi, [ebp+16]     ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; Simplified "登" pattern (12x12)
    mov ecx, 12
.deng_row:
    push ecx
    mov ecx, 12
.deng_col:
    ; Simple pattern for demo
    mov byte [edi], sil
    inc edi
    dec ecx
    jnz .deng_col
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, 12
    dec ecx
    jnz .deng_row
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; Chinese character "录" (12x12)
draw_chinese_lu:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    mov esi, [ebp+16]     ; color
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    ; Simplified "录" pattern (12x12)
    mov ecx, 12
.lu_row:
    push ecx
    mov ecx, 12
.lu_col:
    mov byte [edi], sil
    inc edi
    dec ecx
    jnz .lu_col
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, 12
    dec ecx
    jnz .lu_row
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

section .bss
    g_mouse_x resd 1
    g_mouse_y resd 1
    prev_mouse_x resd 1
    prev_mouse_y resd 1