bits 32

; VGA framebuffer address
FRAMEBUFFER_PTR equ 0x5000
SCREEN_WIDTH equ 1920
SCREEN_HEIGHT equ 1080
LOGICAL_SCALE equ 6
%include "vga_palette.inc"
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

    mov dword [g_mouse_x], 960
    mov dword [g_mouse_y], 540
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

    mov edi, [FRAMEBUFFER_PTR]
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov eax, [vga_palette + COLOR_BG * 4]
    rep stosd

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
    imul eax, 3
    add eax, [g_mouse_x]
    test eax, eax
    jns .mouse_x_nonnegative
    xor eax, eax
.mouse_x_nonnegative:
    cmp eax, SCREEN_WIDTH - MOUSE_WIDTH
    jle .mouse_x_store
    mov eax, SCREEN_WIDTH - MOUSE_WIDTH
.mouse_x_store:
    mov [g_mouse_x], eax

    test bl, 0x80
    jnz .check_click
    movsx eax, byte [mouse_packet + 2]
    neg eax
    imul eax, 3
    add eax, [g_mouse_y]
    test eax, eax
    jns .mouse_y_nonnegative
    xor eax, eax
.mouse_y_nonnegative:
    cmp eax, SCREEN_HEIGHT - MOUSE_HEIGHT
    jle .mouse_y_store
    mov eax, SCREEN_HEIGHT - MOUSE_HEIGHT
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
    cmp eax, 110 * LOGICAL_SCALE
    jl .redraw_mouse
    cmp eax, 210 * LOGICAL_SCALE
    jg .redraw_mouse
    mov eax, [g_mouse_y]
    cmp eax, 90 * LOGICAL_SCALE
    jl .redraw_mouse
    cmp eax, 106 * LOGICAL_SCALE
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
    shl edi, 2
    add edi, [FRAMEBUFFER_PTR]
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
    movzx eax, al
    mov eax, [vga_palette + eax * 4]
    mov [edi], eax
.cursor_skip:
    add edi, 4
    inc esi
    dec ecx
    jnz .cursor_column
    add edi, SCREEN_WIDTH * 4 - MOUSE_WIDTH * 4
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
    imul eax, LOGICAL_SCALE
    mov ebx, [ebp+12]
    imul ebx, LOGICAL_SCALE
    mov ecx, [ebp+16]
    imul ecx, LOGICAL_SCALE
    mov edx, [ebp+20]
    imul edx, LOGICAL_SCALE
    mov esi, [ebp+24]
    and esi, 0x0F
    mov esi, [login_vga_palette + esi * 4]
    cmp eax, SCREEN_WIDTH
    jae .rect_done
    cmp ebx, SCREEN_HEIGHT
    jae .rect_done
    mov edi, SCREEN_WIDTH
    sub edi, eax
    cmp ecx, edi
    jbe .rect_width_ok
    mov ecx, edi
.rect_width_ok:
    mov edi, SCREEN_HEIGHT
    sub edi, ebx
    cmp edx, edi
    jbe .rect_height_ok
    mov edx, edi
.rect_height_ok:
    imul ebx, SCREEN_WIDTH
    add ebx, eax
    shl ebx, 2
    add ebx, [FRAMEBUFFER_PTR]
.draw_rect_row:
    push ecx
    mov eax, esi
    mov edi, ebx
.draw_rect_column:
    stosd
    dec ecx
    jnz .draw_rect_column
    pop ecx
    add ebx, SCREEN_WIDTH * 4
    dec edx
    jnz .draw_rect_row
.rect_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

draw_chinese_deng:
    push ebp
    mov ebp, esp
    push dword deng_expanded
    push dword [ebp+16]
    push dword [ebp+12]
    push dword [ebp+8]
    call draw_glyph_12
    add esp, 16
    pop ebp
    ret

draw_chinese_lu:
    push ebp
    mov ebp, esp
    push dword lu_expanded
    push dword [ebp+16]
    push dword [ebp+12]
    push dword [ebp+8]
    call draw_glyph_12
    add esp, 16
    pop ebp
    ret

draw_glyph_12:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push esi
    xor ebx, ebx
.glyph_row:
    xor ecx, ecx
.glyph_column:
    mov eax, ebx
    imul eax, 12
    add eax, ecx
    mov esi, [ebp+20]
    cmp byte [esi+eax], 0
    je .glyph_next
    push ebx
    push ecx
    push dword [ebp+16]
    mov eax, [ebp+12]
    add eax, ebx
    push eax
    mov eax, [ebp+8]
    add eax, ecx
    push eax
    call draw_logical_pixel
    add esp, 12
    pop ecx
    pop ebx
.glyph_next:
    inc ecx
    cmp ecx, 12
    jl .glyph_column
    inc ebx
    cmp ebx, 12
    jl .glyph_row
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

draw_logical_pixel:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov eax, [ebp+8]
    imul eax, LOGICAL_SCALE
    mov ebx, [ebp+12]
    imul ebx, LOGICAL_SCALE
    imul ebx, SCREEN_WIDTH
    add ebx, eax
    shl ebx, 2
    add ebx, [FRAMEBUFFER_PTR]
    mov eax, [ebp+16]
    and eax, 0x0F
    mov esi, [login_vga_palette + eax * 4]
    mov edx, LOGICAL_SCALE
.logical_pixel_row:
    mov edi, ebx
    mov ecx, LOGICAL_SCALE
    mov eax, esi
    rep stosd
    add ebx, SCREEN_WIDTH * 4
    dec edx
    jnz .logical_pixel_row
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

section .data
    %include "vga_palette.inc"
    VGA_PALETTE_TABLE login_vga_palette

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