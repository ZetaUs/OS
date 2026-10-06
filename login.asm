default rel
bits 64

; VGA framebuffer address
FRAMEBUFFER_PTR equ 0x5000
SCREEN_WIDTH equ 1920
SCREEN_HEIGHT equ 1080
SCREEN_PITCH equ 7680
LOGICAL_SCALE equ 6
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
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov dword [g_mouse_x], 960
    mov dword [g_mouse_y], 540
    mov byte [mouse_packet_stage], 0
    mov byte [mouse_buttons], 0
    mov byte [cursor_drawn], 0
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
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

draw_login_scene:
    push rax
    push rcx
    push rdi

    mov rdi, [rel FRAMEBUFFER_PTR]
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov eax, [rel login_vga_palette + COLOR_BG * 4]
    rep stosd

    push COLOR_BORDER
    push 132
    push 180
    push 34
    push 70
    call draw_rect
    add rsp, 40

    push COLOR_INNER
    push 124
    push 172
    push 38
    push 74
    call draw_rect
    add rsp, 40

    push COLOR_BUTTON
    push 16
    push 100
    push 90
    push 110
    call draw_rect
    add rsp, 40

    push COLOR_TEXT
    push 93
    push 148
    call draw_chinese_deng
    add rsp, 24
    
    ; 录: 12x12 at (160, 93), color=0
    push COLOR_TEXT
    push 93
    push 160
    call draw_chinese_lu
    add rsp, 24

    pop rdi
    pop rcx
    pop rax
    ret

; Initialize the auxiliary PS/2 port for polled mouse input.
mouse_init:
    push rbx
    push rcx
    push rdx

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
    pop rdx
    pop rcx
    pop rbx
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
    push rbx
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
    pop rbx
    ret
.mouse_send_failed:
    stc
    pop rbx
    ret

update_mouse:
    push rbx
    push rcx
    push rsi
    mov bl, [mouse_packet]
    test bl, 0x40
    jnz .check_click
    movsx rax, byte [mouse_packet + 1]
    imul rax, 3
    add rax, [rel g_mouse_x]
    test rax, rax
    jns .mouse_x_nonnegative
    xor rax, rax
.mouse_x_nonnegative:
    cmp rax, SCREEN_WIDTH - MOUSE_WIDTH
    jle .mouse_x_store
    mov rax, SCREEN_WIDTH - MOUSE_WIDTH
.mouse_x_store:
    mov [rel g_mouse_x], eax

    test bl, 0x80
    jnz .check_click
    movsx rax, byte [mouse_packet + 2]
    neg rax
    imul rax, 3
    add rax, [rel g_mouse_y]
    test rax, rax
    jns .mouse_y_nonnegative
    xor rax, rax
.mouse_y_nonnegative:
    cmp rax, SCREEN_HEIGHT - MOUSE_HEIGHT
    jle .mouse_y_store
    mov rax, SCREEN_HEIGHT - MOUSE_HEIGHT
.mouse_y_store:
    mov [rel g_mouse_y], eax

.check_click:
    mov al, bl
    and al, 1
    mov cl, [rel mouse_buttons]
    mov [rel mouse_buttons], al
    test al, al
    jz .redraw_mouse
    test cl, 1
    jnz .redraw_mouse

    mov eax, [rel g_mouse_x]
    cmp eax, 110 * LOGICAL_SCALE
    jl .redraw_mouse
    cmp eax, 210 * LOGICAL_SCALE
    jg .redraw_mouse
    mov eax, [rel g_mouse_y]
    cmp eax, 90 * LOGICAL_SCALE
    jl .redraw_mouse
    cmp eax, 106 * LOGICAL_SCALE
    jl .login_clicked
    jmp .redraw_mouse

.login_clicked:
    mov eax, 1
    jmp .update_done

.redraw_mouse:
    call draw_mouse_cursor
    xor eax, eax

.update_done:
    pop rsi
    pop rcx
    pop rbx
    ret

draw_mouse_cursor:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    cmp byte [rel cursor_drawn], 0
    je .draw_new_cursor

    mov rdi, [rel cursor_prev_y]
    imul rdi, SCREEN_WIDTH
    add rdi, [rel cursor_prev_x]
    shl rdi, 2
    add rdi, [rel FRAMEBUFFER_PTR]
    xor rbx, rbx
.restore_cursor_row:
    mov ecx, MOUSE_WIDTH
    xor esi, esi
.restore_cursor_column:
    mov rax, rbx
    imul rax, MOUSE_WIDTH
    add rax, rsi
    mov eax, [rel cursor_saved + rax * 4]
    mov [rdi], eax
    add rdi, 4
    inc rsi
    dec ecx
    jnz .restore_cursor_column
    add rdi, SCREEN_WIDTH * 4 - MOUSE_WIDTH * 4
    inc rbx
    cmp rbx, MOUSE_HEIGHT
    jl .restore_cursor_row

.draw_new_cursor:
    mov eax, [rel g_mouse_x]
    mov [rel cursor_prev_x], eax
    mov eax, [rel g_mouse_y]
    mov [rel cursor_prev_y], eax
    mov rdi, [rel g_mouse_y]
    imul rdi, SCREEN_WIDTH
    add rdi, [rel g_mouse_x]
    shl rdi, 2
    add rdi, [rel FRAMEBUFFER_PTR]
    xor rbx, rbx
.cursor_row:
    mov ecx, MOUSE_WIDTH
    xor esi, esi
.cursor_column:
    mov eax, [rdi]
    mov edx, ebx
    imul rdx, MOUSE_WIDTH
    add rdx, rsi
    mov [rel cursor_saved + rdx * 4], eax
    mov rax, rbx
    imul rax, MOUSE_WIDTH
    add rax, rsi
    movzx eax, byte [rel mouse_data + rax]
    test al, al
    je .cursor_skip
    mov eax, [rel login_vga_palette + rax * 4]
    mov [rdi], eax
.cursor_skip:
    add rdi, 4
    inc rsi
    dec ecx
    jnz .cursor_column
    add rdi, SCREEN_WIDTH * 4 - MOUSE_WIDTH * 4
    inc rbx
    cmp rbx, MOUSE_HEIGHT
    jl .cursor_row
    mov byte [rel cursor_drawn], 1
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Stack: [rsp+8]=x, [rsp+16]=y, [rsp+24]=width,
; [rsp+32]=height, [rsp+40]=color
draw_rect:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov eax, [rbp+16]
    imul rax, LOGICAL_SCALE
    mov rbx, [rbp+24]
    imul rbx, LOGICAL_SCALE
    mov rcx, [rbp+32]
    imul rcx, LOGICAL_SCALE
    mov rdx, [rbp+40]
    imul rdx, LOGICAL_SCALE
    mov rsi, [rbp+48]
    and rsi, 0x0F
    mov esi, [rel login_vga_palette + rsi * 4]
    cmp eax, SCREEN_WIDTH
    jae .rect_done
    cmp ebx, SCREEN_HEIGHT
    jae .rect_done
    mov rdi, SCREEN_WIDTH
    sub rdi, rax
    cmp rcx, rdi
    jbe .rect_width_ok
    mov rcx, rdi
.rect_width_ok:
    mov rdi, SCREEN_HEIGHT
    sub rdi, rbx
    cmp rdx, rdi
    jbe .rect_height_ok
    mov rdx, rdi
.rect_height_ok:
    imul rbx, SCREEN_WIDTH
    add rbx, rax
    shl rbx, 2
    add rbx, [rel FRAMEBUFFER_PTR]
.draw_rect_row:
    push rcx
    mov rax, rsi
    mov rdi, rbx
.draw_rect_column:
    stosd
    dec rcx
    jnz .draw_rect_column
    pop rcx
    add rbx, SCREEN_WIDTH * 4
    dec rdx
    jnz .draw_rect_row
.rect_done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

draw_chinese_deng:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    mov rdi, deng_expanded
    mov rsi, [rbp+16]
    mov edx, [rbp+24]
    mov ecx, [rbp+32]
    call draw_glyph_12
    pop rsi
    pop rdi
    pop rbp
    ret

draw_chinese_lu:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    mov rdi, lu_expanded
    mov rsi, [rbp+16]
    mov edx, [rbp+24]
    mov ecx, [rbp+32]
    call draw_glyph_12
    pop rsi
    pop rdi
    pop rbp
    ret

draw_glyph_12:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    xor rbx, rbx
.glyph_row:
    xor ecx, ecx
.glyph_column:
    mov rax, rbx
    imul rax, 12
    add rax, rcx
    mov rsi, rdi
    cmp byte [rsi+rax], 0
    je .glyph_next
    push rbx
    push rcx
    push rsi
    push rdx
    mov eax, ecx
    add eax, [rbp+24]
    push rax
    mov eax, ebx
    add eax, edx
    push rax
    call draw_logical_pixel
    add rsp, 48
    pop rcx
    pop rbx
.glyph_next:
    inc rcx
    cmp rcx, 12
    jl .glyph_column
    inc rbx
    cmp rbx, 12
    jl .glyph_row
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

draw_logical_pixel:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rax, [rbp+16]
    imul rax, LOGICAL_SCALE
    mov rbx, [rbp+24]
    imul rbx, LOGICAL_SCALE
    imul rbx, SCREEN_WIDTH
    add rbx, rax
    shl rbx, 2
    add rbx, [rel FRAMEBUFFER_PTR]
    mov eax, [rbp+32]
    and eax, 0x0F
    mov esi, [rel login_vga_palette + rax * 4]
    mov edx, LOGICAL_SCALE
.logical_pixel_row:
    mov rdi, rbx
    mov ecx, LOGICAL_SCALE
    mov eax, esi
    rep stosd
    add rbx, SCREEN_WIDTH * 4
    dec rdx
    jnz .logical_pixel_row
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
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
    cursor_prev_x resd 1
    cursor_prev_y resd 1
    mouse_packet resb 3
    mouse_packet_stage resb 1
    mouse_buttons resb 1
    mouse_available resb 1
    cursor_drawn resb 1
    cursor_saved resd MOUSE_WIDTH * MOUSE_HEIGHT