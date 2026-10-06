bits 32

; VGA framebuffer address
VGA_MEMORY equ 0xA0000
SCREEN_WIDTH equ 320
%include "mouse_data.inc"

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

    mov dword [g_mouse_x], 160
    mov dword [g_mouse_y], 98
    mov byte [mouse_packet_stage], 0
    mov byte [mouse_buttons], 0
    call mouse_init
    mov [mouse_available], al

    call draw_login_scene
    call draw_mouse_cursor

.input_loop:
    in al, 0x64
    test al, 1
    jz .input_loop
    mov ah, al
    in al, 0x60
    test ah, 0x20
    jnz .mouse_byte

    cmp al, 0x1C
    je .login_exit
    jmp .input_loop

.mouse_byte:
    cmp byte [mouse_available], 0
    je .input_loop
    mov bl, [mouse_packet_stage]
    cmp bl, 0
    je .mouse_first_byte
    cmp bl, 1
    je .mouse_x_byte

    mov [mouse_packet + 2], al
    mov byte [mouse_packet_stage], 0
    call update_mouse
    test eax, eax
    jnz .login_exit
    jmp .input_loop

.mouse_first_byte:
    test al, 0x08
    jz .input_loop
    mov [mouse_packet], al
    mov byte [mouse_packet_stage], 1
    jmp .input_loop

.mouse_x_byte:
    mov [mouse_packet + 1], al
    mov byte [mouse_packet_stage], 2
    jmp .input_loop

.login_exit:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

draw_login_scene:
    push eax
    push ecx
    push edi

    mov edi, VGA_MEMORY
    mov ecx, 320 * 200
    mov al, COLOR_BG
    rep stosb

    push COLOR_BORDER
    push 132
    push 180
    push 34
    push 70
    call draw_rect
    add esp, 20

    push COLOR_INNER
    push 124
    push 172
    push 38
    push 74
    call draw_rect
    add esp, 20

    push COLOR_BUTTON
    push 16
    push 100
    push 90
    push 110
    call draw_rect
    add esp, 20

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

    pop edi
    pop ecx
    pop eax
    ret

; Initialize the auxiliary PS/2 port for polled mouse input.
mouse_init:
    push ebx
    push ecx
    push edx

    call wait_input_empty
    jc .mouse_init_failed
    mov al, 0xA8
    out 0x64, al

    call wait_input_empty
    jc .mouse_init_failed
    mov al, 0x20
    out 0x64, al
    call wait_output_full
    jc .mouse_init_failed
    in al, 0x60
    and al, 0xDD
    mov bl, al

    call wait_input_empty
    jc .mouse_init_failed
    mov al, 0x60
    out 0x64, al
    call wait_input_empty
    jc .mouse_init_failed
    mov al, bl
    out 0x60, al

    mov al, 0xF4
    call mouse_send
    jc .mouse_init_failed
    mov al, 1
    jmp .mouse_init_done

.mouse_init_failed:
    xor al, al
.mouse_init_done:
    pop edx
    pop ecx
    pop ebx
    ret

wait_input_empty:
    mov ecx, 0x100000
.wait_input:
    in al, 0x64
    test al, 2
    jz .input_empty
    dec ecx
    jnz .wait_input
    stc
    ret
.input_empty:
    clc
    ret

wait_output_full:
    mov ecx, 0x100000
.wait_output:
    in al, 0x64
    test al, 1
    jnz .output_full
    dec ecx
    jnz .wait_output
    stc
    ret
.output_full:
    clc
    ret

mouse_send:
    push ebx
    mov bl, al
    call wait_input_empty
    jc .mouse_send_failed
    mov al, 0xD4
    out 0x64, al
    call wait_input_empty
    jc .mouse_send_failed
    mov al, bl
    out 0x60, al
    call wait_output_full
    jc .mouse_send_failed
    in al, 0x60
    cmp al, 0xFA
    jne .mouse_send_failed
    clc
    pop ebx
    ret
.mouse_send_failed:
    stc
    pop ebx
    ret

update_mouse:
    push ebx
    push ecx
    push esi
    mov bl, [mouse_packet]
    test bl, 0x40
    jnz .check_click
    movsx eax, byte [mouse_packet + 1]
    add eax, [g_mouse_x]
    test eax, eax
    jns .mouse_x_nonnegative
    xor eax, eax
.mouse_x_nonnegative:
    cmp eax, 307
    jle .mouse_x_store
    mov eax, 307
.mouse_x_store:
    mov [g_mouse_x], eax

    test bl, 0x80
    jnz .check_click
    movsx eax, byte [mouse_packet + 2]
    neg eax
    add eax, [g_mouse_y]
    test eax, eax
    jns .mouse_y_nonnegative
    xor eax, eax
.mouse_y_nonnegative:
    cmp eax, 184
    jle .mouse_y_store
    mov eax, 184
.mouse_y_store:
    mov [g_mouse_y], eax

.check_click:
    mov al, bl
    and al, 1
    mov cl, [mouse_buttons]
    mov [mouse_buttons], al
    test al, al
    jz .redraw_mouse
    test cl, 1
    jnz .redraw_mouse

    mov eax, [g_mouse_x]
    cmp eax, 110
    jl .redraw_mouse
    cmp eax, 210
    jg .redraw_mouse
    mov eax, [g_mouse_y]
    cmp eax, 90
    jl .redraw_mouse
    cmp eax, 106
    jl .login_clicked
    jmp .redraw_mouse

.login_clicked:
    mov eax, 1
    jmp .update_done

.redraw_mouse:
    call draw_login_scene
    call draw_mouse_cursor
    xor eax, eax

.update_done:
    pop esi
    pop ecx
    pop ebx
    ret

draw_mouse_cursor:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edi, [g_mouse_y]
    imul edi, SCREEN_WIDTH
    add edi, [g_mouse_x]
    add edi, VGA_MEMORY
    xor ebx, ebx
.cursor_row:
    mov ecx, MOUSE_WIDTH
    xor esi, esi
.cursor_column:
    mov eax, ebx
    imul eax, MOUSE_WIDTH
    add eax, esi
    mov al, [mouse_data + eax]
    test al, al
    je .cursor_skip
    mov [edi], al
.cursor_skip:
    inc edi
    inc esi
    dec ecx
    jnz .cursor_column
    add edi, SCREEN_WIDTH - MOUSE_WIDTH
    inc ebx
    cmp ebx, MOUSE_HEIGHT
    jl .cursor_row
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Stack: [ebp+8]=x, [ebp+12]=y, [ebp+16]=width,
; [ebp+20]=height, [ebp+24]=color
draw_rect:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    mov ecx, [ebp+16]
    mov edx, [ebp+20]
    movzx esi, byte [ebp+24]
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
.draw_rect_row:
    push ecx
    mov ecx, [ebp+16]
    mov eax, esi
.draw_rect_column:
    mov byte [edi], al
    inc edi
    dec ecx
    jnz .draw_rect_column
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, [ebp+16]
    dec edx
    jnz .draw_rect_row
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
    ; 登 expanded bitmap (12x12 = 144 bytes, 0 or 1)
    deng_expanded: db 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0
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
    mouse_packet resb 3
    mouse_packet_stage resb 1
    mouse_buttons resb 1
    mouse_available resb 1