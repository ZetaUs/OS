bits 32

FRAMEBUFFER_PTR equ 0x5000
SCREEN_WIDTH equ 1920
SCREEN_HEIGHT equ 1080
SCREEN_PITCH equ 7680
VIEWPORT_X equ 0
VIEWPORT_Y equ 0
VIEWPORT_WIDTH equ 320
VIEWPORT_HEIGHT equ 180
LOGICAL_SCALE equ 6

global _desktop_screen

section .text

_desktop_screen:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    cld

    mov dword [desktop_mouse_x], 960
    mov dword [desktop_mouse_y], 500
    mov byte [desktop_packet_stage], 0
    mov byte [desktop_mouse_buttons], 0
    mov byte [desktop_cursor_drawn], 0
    mov byte [desktop_window], 0
    mov byte [desktop_start_open], 0
    call desktop_draw_scene
    call desktop_draw_cursor

.desktop_input:
    in al, 0x64
    test al, 1
    jz .desktop_input
    mov ah, al
    in al, 0x60
    test ah, 0x20
    jz .desktop_keyboard

    mov bl, [rel desktop_packet_stage]
    cmp bl, 0
    je .desktop_first_byte
    cmp bl, 1
    je .desktop_x_byte
    mov [rel desktop_packet + 2], al
    mov byte [rel desktop_packet_stage], 0
    call desktop_update_mouse
    jmp .desktop_input

.desktop_first_byte:
    test al, 0x08
    jz .desktop_input
    mov [rel desktop_packet], al
    mov byte [rel desktop_packet_stage], 1
    jmp .desktop_input

.desktop_x_byte:
    mov [rel desktop_packet + 1], al
    mov byte [rel desktop_packet_stage], 2
    jmp .desktop_input

.desktop_keyboard:
    cmp al, 0x01
    jne .desktop_input
    mov byte [rel desktop_window], 0
    mov byte [rel desktop_start_open], 0
    call desktop_redraw
    jmp .desktop_input

desktop_draw_scene:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    cld

    mov edi, [FRAMEBUFFER_PTR]
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov eax, [desktop_vga_palette + 9 * 4]
    rep stosd

    ; Fill the full-screen logical desktop with a Windows-inspired blue field.
    push dword 9
    push dword VIEWPORT_HEIGHT
    push dword 320
    push dword 0
    push dword 0
    call draw_rect
    add esp, 20

    ; Layered blue panels create a subtle geometric glow behind the logo.
    push dword 1
    push dword 180
    push dword 120
    push dword 0
    push dword 0
    call draw_rect
    add esp, 20
    push dword 1
    push dword 110
    push dword 100
    push dword 0
    push dword 120
    call draw_rect
    add esp, 20
    push dword 1
    push dword 50
    push dword 100
    push dword 110
    push dword 220
    call draw_rect
    add esp, 20

    ; Reuse the Nova logo as the wallpaper mark.
    push dword 48
    push dword 48
    push dword 50
    push dword 204
    call desktop_draw_logo
    add esp, 16

    ; Compact desktop shortcuts aligned along the left edge.
    call desktop_draw_computer_icon
    push dword 15
    push dword computer_label
    push dword 82
    push dword 19
    call draw_text_small
    add esp, 16

    call desktop_draw_explorer_icon
    push dword 14
    push dword explorer_label
    push dword 177
    push dword 28
    call draw_text_small
    add esp, 16

    call desktop_draw_window
    call desktop_draw_start_menu

    ; Windows-style taskbar anchored to the bottom edge.
    push dword 8
    push dword 8
    push dword 320
    push dword 172
    push dword 0
    call draw_rect
    add esp, 20
    push dword 7
    push dword 1
    push dword 320
    push dword 171
    push dword 0
    call draw_rect
    add esp, 20

    ; Use the same Nova logo on the Start button.
    push dword 6
    push dword 6
    push dword 173
    push dword 1
    call desktop_draw_logo
    add esp, 16

    ; Clock area.
    push dword 8
    push dword 8
    push dword 42
    push dword 172
    push dword 278
    call draw_rect
    add esp, 20
    push dword 15
    push dword clock_text
    push dword 172
    push dword 279
    call draw_text
    add esp, 16

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

desktop_draw_computer_icon:
    push ebx
    push esi
    push edi
    xor esi, esi
.computer_row:
    xor edi, edi
.computer_column:
    mov eax, esi
    imul eax, COMPUTER_ICON_WIDTH
    add eax, edi
    cmp byte [computer_icon_data + eax], 0
    je .computer_next
    push dword 15
    push dword 1
    push dword 1
    mov eax, esi
    add eax, 8
    push eax
    mov eax, edi
    add eax, 8
    push eax
    call draw_rect
    add esp, 20
.computer_next:
    inc edi
    cmp edi, COMPUTER_ICON_WIDTH
    jl .computer_column
    inc esi
    cmp esi, COMPUTER_ICON_HEIGHT
    jl .computer_row
    pop edi
    pop esi
    pop ebx
    ret

desktop_draw_explorer_icon:
    push ebx
    push esi
    push edi
    xor esi, esi
.explorer_row:
    xor edi, edi
.explorer_column:
    mov eax, esi
    imul eax, EXPLORER_ICON_WIDTH
    add eax, edi
    movzx ebx, byte [explorer_icon_data + eax]
    test ebx, ebx
    jz .explorer_next
    push ebx
    push dword 1
    push dword 1
    mov eax, esi
    add eax, 34
    push eax
    mov eax, edi
    add eax, 8
    push eax
    call draw_rect
    add esp, 20
.explorer_next:
    inc edi
    cmp edi, EXPLORER_ICON_WIDTH
    jl .explorer_column
    inc esi
    cmp esi, EXPLORER_ICON_HEIGHT
    jl .explorer_row
    pop edi
    pop esi
    pop ebx
    ret

desktop_draw_logo:
    push ebp
    mov ebp, esp
    sub esp, 12
    push ebx
    push esi
    push edi
    mov dword [ebp-4], 0
.logo_row:
    mov dword [ebp-8], 0
.logo_column:
    mov eax, [ebp-4]
    imul eax, LOGO_HEIGHT
    xor edx, edx
    div dword [ebp+20]
    imul eax, LOGO_WIDTH
    mov [ebp-12], eax
    mov eax, [ebp-8]
    imul eax, LOGO_WIDTH
    xor edx, edx
    div dword [ebp+16]
    add eax, [ebp-12]
    cmp byte [logo_mask + eax], 0
    je .logo_next_column
    push dword 14
    push dword 1
    push dword 1
    mov eax, [ebp+12]
    add eax, [ebp-4]
    push eax
    mov eax, [ebp+8]
    add eax, [ebp-8]
    push eax
    call draw_rect
    add esp, 20
.logo_next_column:
    inc dword [ebp-8]
    mov eax, [ebp-8]
    cmp eax, [ebp+16]
    jl .logo_column
    inc dword [ebp-4]
    mov eax, [ebp-4]
    cmp eax, [ebp+20]
    jl .logo_row
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

desktop_redraw:
    mov byte [desktop_cursor_drawn], 0
    call desktop_draw_scene
    call desktop_draw_cursor
    ret

desktop_draw_window:
    cmp byte [desktop_window], 0
    je .window_done

    push dword 8
    push dword 110
    push dword 170
    push dword 65
    push dword 75
    call draw_rect
    add esp, 20
    push dword 1
    push dword 18
    push dword 162
    push dword 69
    push dword 79
    call draw_rect
    add esp, 20
    push dword 7
    push dword 92
    push dword 162
    push dword 87
    push dword 79
    call draw_rect
    add esp, 20
    push dword 15
    push dword close_text
    push dword 73
    push dword 222
    call draw_text
    add esp, 16

    cmp byte [desktop_window], 1
    jne .files_window
    push dword 15
    push dword pc_window_title
    push dword 74
    push dword 82
    call draw_text
    add esp, 16
    push dword 0
    push dword disk_label
    push dword 113
    push dword 94
    call draw_text
    add esp, 16
    jmp .window_done

.files_window:
    push dword 15
    push dword explorer_window_title
    push dword 74
    push dword 82
    call draw_text
    add esp, 16
    push dword 0
    push dword empty_folder_text
    push dword 113
    push dword 94
    call draw_text
    add esp, 16

.window_done:
    ret

desktop_draw_start_menu:
    cmp byte [desktop_start_open], 0
    je .menu_done
    push dword 8
    push dword 112
    push dword 104
    push dword 60
    push dword 4
    call draw_rect
    add esp, 20
    push dword 1
    push dword 16
    push dword 100
    push dword 64
    push dword 6
    call draw_rect
    add esp, 20
    push dword 15
    push dword menu_title
    push dword 67
    push dword 10
    call draw_text
    add esp, 16
    push dword 15
    push dword explorer_menu_item
    push dword 84
    push dword 12
    call draw_text
    add esp, 16
    push dword 15
    push dword computer_menu_item
    push dword 102
    push dword 12
    call draw_text
    add esp, 16
    push dword 15
    push dword restart_menu_item
    push dword 120
    push dword 12
    call draw_text
    add esp, 16
    push dword 15
    push dword shutdown_menu_item
    push dword 138
    push dword 12
    call draw_text
    add esp, 16

.menu_done:
    ret

desktop_update_mouse:
    push ebx
    push ecx
    push edx
    mov bl, [desktop_packet]

    test bl, 0x40
    jnz .update_y
    movsx eax, byte [desktop_packet + 1]
    imul eax, 3
    add eax, [desktop_mouse_x]
    test eax, eax
    jns .mouse_x_nonnegative
    xor eax, eax
.mouse_x_nonnegative:
    cmp eax, SCREEN_WIDTH - MOUSE_WIDTH
    jle .mouse_x_store
    mov eax, SCREEN_WIDTH - MOUSE_WIDTH
.mouse_x_store:
    mov [desktop_mouse_x], eax

.update_y:
    test bl, 0x80
    jnz .check_button
    movsx eax, byte [desktop_packet + 2]
    neg eax
    imul eax, 3
    add eax, [desktop_mouse_y]
    test eax, eax
    jns .mouse_y_nonnegative
    xor eax, eax
.mouse_y_nonnegative:
    cmp eax, SCREEN_HEIGHT - MOUSE_HEIGHT
    jle .mouse_y_store
    mov eax, SCREEN_HEIGHT - MOUSE_HEIGHT
.mouse_y_store:
    mov [desktop_mouse_y], eax

.check_button:
    mov al, bl
    and al, 1
    mov cl, [desktop_mouse_buttons]
    mov [desktop_mouse_buttons], al
    test al, al
    jz .draw_cursor
    test cl, 1
    jnz .draw_cursor
    call desktop_hit_test
    test eax, eax
    jnz .redraw_scene

.draw_cursor:
    call desktop_draw_cursor
    jmp .update_done

.redraw_scene:
    call desktop_redraw

.update_done:
    pop edx
    pop ecx
    pop ebx
    ret

desktop_hit_test:
    cmp byte [desktop_start_open], 0
    je .check_start_button
    cmp dword [desktop_mouse_x], 24
    jl .close_menu_outside
    cmp dword [desktop_mouse_x], 648
    jg .close_menu_outside
    cmp dword [desktop_mouse_y], 486
    jl .close_menu_outside
    cmp dword [desktop_mouse_y], 594
    jle .open_files
    cmp dword [desktop_mouse_y], 702
    jle .open_pc
    cmp dword [desktop_mouse_y], 810
    jle .restart_action
    cmp dword [desktop_mouse_y], 918
    jle .shutdown_action
.close_menu_outside:
    mov byte [desktop_start_open], 0
    mov eax, 1
    ret

.restart_action:
    call desktop_restart
.shutdown_action:
    call desktop_shutdown

.check_start_button:
    cmp dword [desktop_mouse_x], 0
    jl .check_window
    cmp dword [desktop_mouse_x], 48
    jg .check_window
    cmp dword [desktop_mouse_y], 1032
    jl .check_window
    cmp dword [desktop_mouse_y], SCREEN_HEIGHT
    jg .check_window
    mov al, [desktop_start_open]
    xor al, 1
    mov [desktop_start_open], al
    mov eax, 1
    ret

.check_window:
    cmp byte [desktop_window], 0
    je .check_icons
    cmp dword [desktop_mouse_x], 1300
    jl .check_icons
    cmp dword [desktop_mouse_x], 1450
    jg .check_icons
    cmp dword [desktop_mouse_y], 410
    jl .check_icons
    cmp dword [desktop_mouse_y], 510
    jg .check_icons
    mov byte [desktop_window], 0
    mov eax, 1
    ret

.check_icons:
    cmp dword [desktop_mouse_x], 24
    jl .check_files_icon
    cmp dword [desktop_mouse_x], 165
    jg .check_files_icon
    cmp dword [desktop_mouse_y], 40
    jl .check_files_icon
    cmp dword [desktop_mouse_y], 186
    jg .check_files_icon
.open_pc:
    mov byte [desktop_window], 1
    mov byte [desktop_start_open], 0
    mov eax, 1
    ret

.check_files_icon:
    cmp dword [desktop_mouse_x], 48
    jl .check_files_label
    cmp dword [desktop_mouse_x], 192
    jg .check_files_label
    cmp dword [desktop_mouse_y], 204
    jl .check_files_label
    cmp dword [desktop_mouse_y], 348
    jg .check_files_label
    jmp .open_files

.check_files_label:
    cmp dword [desktop_mouse_x], 56
    jl .no_action
    cmp dword [desktop_mouse_x], 184
    jg .no_action
    cmp dword [desktop_mouse_y], 348
    jl .no_action
    cmp dword [desktop_mouse_y], 382
    jg .no_action
.open_files:
    mov byte [desktop_window], 2
    mov byte [desktop_start_open], 0
    mov eax, 1
    ret

.no_action:
    xor eax, eax
    ret

desktop_restart:
    cli
    mov ecx, 0x10000
.restart_wait:
    in al, 0x64
    test al, 2
    jz .restart_send
    dec ecx
    jnz .restart_wait
.restart_send:
    mov al, 0xFE
    out 0x64, al
    lidt [desktop_empty_idtr]
    int3
.restart_halt:
    hlt
    jmp .restart_halt

desktop_shutdown:
    cli
    mov dx, 0x0604
    mov ax, 0x2000
    out dx, ax
    mov dx, 0xB004
    out dx, ax
.shutdown_halt:
    hlt
    jmp .shutdown_halt

desktop_draw_cursor:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    cmp byte [desktop_cursor_drawn], 0
    je .draw_current_cursor
    mov edi, [desktop_cursor_y]
    imul edi, SCREEN_WIDTH
    add edi, [desktop_cursor_x]
    shl edi, 2
    add edi, [FRAMEBUFFER_PTR]
    xor ebx, ebx
.restore_row:
    mov ecx, MOUSE_WIDTH
    xor esi, esi
.restore_column:
    mov edx, ebx
    imul edx, MOUSE_WIDTH
    add edx, esi
    mov eax, [desktop_cursor_saved + edx * 4]
    mov [edi], eax
    add edi, 4
    inc esi
    dec ecx
    jnz .restore_column
    add edi, SCREEN_WIDTH * 4 - MOUSE_WIDTH * 4
    inc ebx
    cmp ebx, MOUSE_HEIGHT
    jl .restore_row

.draw_current_cursor:
    mov eax, [desktop_mouse_x]
    mov [desktop_cursor_x], eax
    mov eax, [desktop_mouse_y]
    mov [desktop_cursor_y], eax
    mov edi, [desktop_mouse_y]
    imul edi, SCREEN_WIDTH
    add edi, [desktop_mouse_x]
    shl edi, 2
    add edi, [FRAMEBUFFER_PTR]
    xor ebx, ebx
.cursor_row:
    mov ecx, MOUSE_WIDTH
    xor esi, esi
.cursor_column:
    mov eax, [edi]
    mov edx, ebx
    imul edx, MOUSE_WIDTH
    add edx, esi
    mov [desktop_cursor_saved + edx * 4], eax
    mov edx, ebx
    imul edx, MOUSE_WIDTH
    add edx, esi
    movzx eax, byte [mouse_data + edx]
    test al, al
    jz .cursor_skip
    mov eax, [desktop_vga_palette + eax * 4]
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
    mov byte [desktop_cursor_drawn], 1

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; draw_rect(x, y, width, height, color)
draw_rect:
    push ebp
    mov ebp, esp
    sub esp, 8
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, [ebp+8]
    imul eax, [desktop_rect_scale]
    add eax, VIEWPORT_X
    mov [ebp-4], eax
    mov ebx, [ebp+12]
    imul ebx, [desktop_rect_scale]
    add ebx, VIEWPORT_Y
    mov [ebp-8], ebx
    mov ecx, [ebp+8]
    add ecx, [ebp+16]
    imul ecx, [desktop_rect_scale]
    add ecx, VIEWPORT_X
    sub ecx, eax
    mov edx, [ebp+12]
    add edx, [ebp+20]
    imul edx, [desktop_rect_scale]
    add edx, VIEWPORT_Y
    sub edx, ebx
    mov esi, [ebp+24]
    and esi, 0x0F
    mov esi, [desktop_vga_palette + esi * 4]
    test ecx, ecx
    jz .rect_done
    test edx, edx
    jz .rect_done
    cmp dword [ebp-4], SCREEN_WIDTH
    jae .rect_done
    cmp dword [ebp-8], SCREEN_HEIGHT
    jae .rect_done
    mov edi, SCREEN_WIDTH
    sub edi, [ebp-4]
    cmp ecx, edi
    jbe .rect_width_ok
    mov ecx, edi
.rect_width_ok:
    mov edi, SCREEN_HEIGHT
    sub edi, [ebp-8]
    cmp edx, edi
    jbe .rect_height_ok
    mov edx, edi
.rect_height_ok:
    mov ebx, [ebp-8]
    imul ebx, SCREEN_WIDTH
    add ebx, [ebp-4]
    shl ebx, 2
    add ebx, [FRAMEBUFFER_PTR]
.rect_row:
    push ecx
    mov edi, ebx
    mov eax, esi
    rep stosd
    pop ecx
    add ebx, SCREEN_WIDTH * 4
    dec edx
    jnz .rect_row

.rect_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    add esp, 8
    pop ebp
    ret

; draw_text(x, y, text, color), using the 8x8 uppercase font below.
draw_text:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push esi
    mov ebx, [ebp+8]
    mov esi, [ebp+16]
.text_next:
    movzx eax, byte [esi]
    test al, al
    jz .text_done
    push dword [ebp+20]
    push eax
    push dword [ebp+12]
    push ebx
    call draw_char
    add esp, 16
    add ebx, 8
    inc esi
    jmp .text_next
.text_done:
    pop esi
    pop ebx
    pop eax
    pop ebp
    ret

; Draw compact shortcut labels with 2x2-pixel glyph pixels.
draw_text_small:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push edx
    push esi
    mov dword [desktop_rect_scale], 2
    mov ebx, [ebp+8]
    mov edx, [ebp+12]
    mov esi, [ebp+16]
.small_text_next:
    movzx eax, byte [esi]
    test al, al
    jz .small_text_done
    push dword [ebp+20]
    push eax
    push edx
    push ebx
    call draw_char
    add esp, 16
    add ebx, 8
    inc esi
    jmp .small_text_next
.small_text_done:
    mov dword [desktop_rect_scale], LOGICAL_SCALE
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ebp
    ret

; draw_char(x, y, character, color)
draw_char:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    movzx eax, byte [ebp+16]
    cmp al, 'A'
    jb .char_check_lower
    cmp al, 'Z'
    jbe .char_upper
.char_check_lower:
    cmp al, 'a'
    jb .char_check_digit
    cmp al, 'z'
    ja .char_check_digit
    sub al, 'a'
    movzx ebx, al
    shl ebx, 3
    add ebx, lowercase_font_data
    jmp .char_draw
.char_upper:
    sub al, 'A'
    movzx ebx, al
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_check_digit:
    cmp al, '0'
    jb .char_check_space
    cmp al, '9'
    ja .char_check_space
    sub al, '0'
    add al, 27
    movzx ebx, al
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_check_space:
    cmp al, ' '
    jne .char_colon
    mov ebx, 26
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_colon:
    cmp al, ':'
    jne .char_blank
    mov ebx, 37
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_blank:
    mov ebx, blank_glyph
.char_draw:
    xor edi, edi
.char_row:
    mov al, [ebx]
    xor esi, esi
.char_column:
    test al, 0x80
    jz .char_skip_pixel
    push eax
    push esi
    push edi
    push dword [ebp+20]
    push dword 1
    push dword 1
    mov eax, [ebp+12]
    add eax, edi
    push eax
    mov eax, [ebp+8]
    add eax, esi
    push eax
    call draw_rect
    add esp, 20
    pop edi
    pop esi
    pop eax
.char_skip_pixel:
    shl al, 1
    inc esi
    cmp esi, 8
    jl .char_column
    inc ebx
    inc edi
    cmp edi, 8
    jl .char_row

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

section .data
    desktop_rect_scale: dd LOGICAL_SCALE
    desktop_vga_palette:
        dd 0x000000, 0x06294F, 0x168A44, 0x1599E8
        dd 0xD9534F, 0x8E44AD, 0xB86B22, 0xD4D9DE
        dd 0x252B33, 0x0876C9, 0x2E9B57, 0x63C4FF
        dd 0xE66B64, 0xAA72CC, 0xFFD34D, 0xFFFFFF
    %include "mouse_data.inc"
    %include "computer_data.inc"
    %include "explorer_data.inc"
    %include "logo_data.inc"
    computer_label: db 'Computer', 0
    explorer_label: db 'Explorer', 0
    clock_text: db '08:00', 0
    close_text: db 'X', 0
    pc_window_title: db 'COMPUTER', 0
    explorer_window_title: db 'EXPLORER', 0
    disk_label: db 'LOCAL DISK C', 0
    empty_folder_text: db 'NO FILES YET', 0
    menu_title: db 'NOVA OS', 0
    computer_menu_item: db 'COMPUTER', 0
    explorer_menu_item: db 'EXPLORER', 0
    restart_menu_item: db 'RESTART', 0
    shutdown_menu_item: db 'SHUTDOWN', 0
    desktop_empty_idtr: dw 0
                          dd 0
    blank_glyph: times 8 db 0

    ; 5x7-style bitmaps stored as 8x8 rows.
    font_data:
        db 0x18,0x24,0x42,0x42,0x7E,0x42,0x42,0x00 ; A
        db 0x7C,0x42,0x42,0x7C,0x42,0x42,0x7C,0x00 ; B
        db 0x3C,0x42,0x40,0x40,0x40,0x42,0x3C,0x00 ; C
        db 0x78,0x44,0x42,0x42,0x42,0x44,0x78,0x00 ; D
        db 0x7E,0x40,0x40,0x7C,0x40,0x40,0x7E,0x00 ; E
        db 0x7E,0x40,0x40,0x7C,0x40,0x40,0x40,0x00 ; F
        db 0x3C,0x42,0x40,0x4E,0x42,0x42,0x3C,0x00 ; G
        db 0x42,0x42,0x42,0x7E,0x42,0x42,0x42,0x00 ; H
        db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00 ; I
        db 0x1E,0x0C,0x0C,0x0C,0x4C,0x4C,0x38,0x00 ; J
        db 0x42,0x44,0x48,0x70,0x48,0x44,0x42,0x00 ; K
        db 0x40,0x40,0x40,0x40,0x40,0x40,0x7E,0x00 ; L
        db 0x42,0x66,0x5A,0x5A,0x42,0x42,0x42,0x00 ; M
        db 0x42,0x62,0x52,0x4A,0x46,0x42,0x42,0x00 ; N
        db 0x3C,0x42,0x42,0x42,0x42,0x42,0x3C,0x00 ; O
        db 0x7C,0x42,0x42,0x7C,0x40,0x40,0x40,0x00 ; P
        db 0x3C,0x42,0x42,0x42,0x4A,0x44,0x3A,0x00 ; Q
        db 0x7C,0x42,0x42,0x7C,0x48,0x44,0x42,0x00 ; R
        db 0x3C,0x42,0x40,0x3C,0x02,0x42,0x3C,0x00 ; S
        db 0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00 ; T
        db 0x42,0x42,0x42,0x42,0x42,0x42,0x3C,0x00 ; U
        db 0x42,0x42,0x42,0x42,0x24,0x24,0x18,0x00 ; V
        db 0x42,0x42,0x42,0x5A,0x5A,0x66,0x42,0x00 ; W
        db 0x42,0x24,0x18,0x18,0x18,0x24,0x42,0x00 ; X
        db 0x42,0x24,0x18,0x18,0x18,0x18,0x18,0x00 ; Y
        db 0x7E,0x02,0x04,0x18,0x20,0x40,0x7E,0x00 ; Z
        times 8 db 0                                      ; space
        db 0x3C,0x42,0x46,0x4A,0x52,0x62,0x3C,0x00 ; 0
        db 0x18,0x28,0x48,0x08,0x08,0x08,0x7E,0x00 ; 1
        db 0x3C,0x42,0x02,0x0C,0x30,0x40,0x7E,0x00 ; 2
        db 0x3C,0x42,0x02,0x1C,0x02,0x42,0x3C,0x00 ; 3
        db 0x08,0x18,0x28,0x48,0x7E,0x08,0x08,0x00 ; 4
        db 0x7E,0x40,0x7C,0x02,0x02,0x42,0x3C,0x00 ; 5
        db 0x1C,0x20,0x40,0x7C,0x42,0x42,0x3C,0x00 ; 6
        db 0x7E,0x02,0x04,0x08,0x10,0x10,0x10,0x00 ; 7
        db 0x3C,0x42,0x42,0x3C,0x42,0x42,0x3C,0x00 ; 8
        db 0x3C,0x42,0x42,0x3E,0x02,0x04,0x38,0x00 ; 9
        db 0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00 ; :

        lowercase_font_data:
            db 0x00,0x00,0x3C,0x02,0x3E,0x42,0x3E,0x00 ; a
            db 0x40,0x40,0x5C,0x62,0x42,0x62,0x5C,0x00 ; b
            db 0x00,0x00,0x3C,0x42,0x40,0x42,0x3C,0x00 ; c
            db 0x02,0x02,0x3A,0x46,0x42,0x46,0x3A,0x00 ; d
            db 0x00,0x00,0x3C,0x42,0x7E,0x40,0x3C,0x00 ; e
            db 0x0C,0x12,0x10,0x7C,0x10,0x10,0x10,0x00 ; f
            db 0x00,0x00,0x3A,0x46,0x42,0x3E,0x02,0x3C ; g
            db 0x40,0x40,0x5C,0x62,0x42,0x42,0x42,0x00 ; h
            db 0x10,0x00,0x30,0x10,0x10,0x10,0x38,0x00 ; i
            db 0x04,0x00,0x0C,0x04,0x04,0x44,0x44,0x38 ; j
            db 0x40,0x40,0x44,0x48,0x70,0x48,0x44,0x00 ; k
            db 0x30,0x10,0x10,0x10,0x10,0x10,0x38,0x00 ; l
            db 0x00,0x00,0x6C,0x52,0x52,0x52,0x52,0x00 ; m
            db 0x00,0x00,0x5C,0x62,0x42,0x42,0x42,0x00 ; n
            db 0x00,0x00,0x3C,0x42,0x42,0x42,0x3C,0x00 ; o
            db 0x00,0x00,0x5C,0x62,0x62,0x5C,0x40,0x40 ; p
            db 0x00,0x00,0x3A,0x46,0x46,0x3A,0x02,0x02 ; q
            db 0x00,0x00,0x5C,0x62,0x40,0x40,0x40,0x00 ; r
            db 0x00,0x00,0x3E,0x40,0x3C,0x02,0x7C,0x00 ; s
            db 0x20,0x20,0x7C,0x20,0x20,0x22,0x1C,0x00 ; t
            db 0x00,0x00,0x42,0x42,0x42,0x46,0x3A,0x00 ; u
            db 0x00,0x00,0x42,0x42,0x24,0x24,0x18,0x00 ; v
            db 0x00,0x00,0x42,0x42,0x5A,0x5A,0x24,0x00 ; w
            db 0x00,0x00,0x42,0x24,0x18,0x24,0x42,0x00 ; x
            db 0x00,0x00,0x42,0x42,0x46,0x3A,0x02,0x3C ; y
            db 0x00,0x00,0x7E,0x04,0x18,0x20,0x7E,0x00 ; z

section .bss
    desktop_mouse_x resd 1
    desktop_mouse_y resd 1
    desktop_cursor_x resd 1
    desktop_cursor_y resd 1
    desktop_packet resb 3
    desktop_packet_stage resb 1
    desktop_mouse_buttons resb 1
    desktop_cursor_drawn resb 1
    desktop_window resb 1
    desktop_start_open resb 1
    desktop_cursor_saved resd MOUSE_WIDTH * MOUSE_HEIGHT