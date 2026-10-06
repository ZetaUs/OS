bits 32

FRAMEBUFFER_PTR equ 0x5000
SCREEN_WIDTH equ 1920
SCREEN_HEIGHT equ 1080
VIEWPORT_X equ 560
VIEWPORT_Y equ 240
VIEWPORT_WIDTH equ 800
VIEWPORT_HEIGHT equ 600

global _desktop_screen

section .text

_desktop_screen:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    cld

    mov edi, [FRAMEBUFFER_PTR]
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov eax, [desktop_vga_palette + 4]
    rep stosd

    ; Draw an 800x600 desktop centered in the 1920x1080 framebuffer.
    push dword 1
    push dword 240
    push dword 320
    push dword 0
    push dword 0
    call draw_rect
    add esp, 20

    push dword 9
    push dword 72
    push dword 320
    push dword 168
    push dword 0
    call draw_rect
    add esp, 20

    push dword 1
    push dword 49
    push dword 320
    push dword 191
    push dword 0
    call draw_rect
    add esp, 20

    push dword 3
    push dword 96
    push dword 320
    push dword 96
    push dword 0
    call draw_rect
    add esp, 20

    ; Header.
    push dword 15
    push dword title_text
    push dword 11
    push dword 8
    call draw_text
    add esp, 16

    push dword 11
    push dword subtitle_text
    push dword 11
    push dword 216
    call draw_text
    add esp, 16

    ; Computer icon.
    push dword 15
    push dword 35
    push dword 40
    push dword 28
    push dword 16
    call draw_rect
    add esp, 20
    push dword 9
    push dword 29
    push dword 29
    push dword 31
    push dword 21
    call draw_rect
    add esp, 20
    push dword 7
    push dword 4
    push dword 13
    push dword 35
    push dword 29
    call draw_rect
    add esp, 20
    push dword 15
    push dword 3
    push dword 21
    push dword 41
    push dword 24
    call draw_rect
    add esp, 20

    push dword 15
    push dword computer_label
    push dword 79
    push dword 12
    call draw_text
    add esp, 16

    ; Folder icon.
    push dword 14
    push dword 8
    push dword 36
    push dword 123
    push dword 19
    call draw_rect
    add esp, 20
    push dword 6
    push dword 32
    push dword 39
    push dword 128
    push dword 16
    call draw_rect
    add esp, 20
    push dword 14
    push dword folder_label
    push dword 165
    push dword 12
    call draw_text
    add esp, 16

    ; A small centered welcome panel.
    push dword 8
    push dword 80
    push dword 170
    push dword 121
    push dword 74
    call draw_rect
    add esp, 20
    push dword 15
    push dword welcome_text
    push dword 129
    push dword 131
    call draw_text
    add esp, 16
    push dword 11
    push dword ready_text
    push dword 147
    push dword 107
    call draw_text
    add esp, 16

    ; Taskbar.
    push dword 8
    push dword 27
    push dword 320
    push dword 213
    push dword 0
    call draw_rect
    add esp, 20
    push dword 15
    push dword 2
    push dword 320
    push dword 213
    push dword 0
    call draw_rect
    add esp, 20

    ; Start button.
    push dword 1
    push dword 21
    push dword 58
    push dword 217
    push dword 5
    call draw_rect
    add esp, 20
    push dword 15
    push dword start_text
    push dword 221
    push dword 14
    call draw_text
    add esp, 16

    push dword 15
    push dword taskbar_text
    push dword 221
    push dword 76
    call draw_text
    add esp, 16

    push dword 7
    push dword 21
    push dword 49
    push dword 219
    push dword 265
    call draw_rect
    add esp, 20
    push dword 15
    push dword clock_text
    push dword 224
    push dword 270
    call draw_text
    add esp, 16

    pop edi
    pop esi
    pop ebx
    pop ebp
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
    imul eax, 5
    shr eax, 1
    add eax, VIEWPORT_X
    mov [ebp-4], eax
    mov ebx, [ebp+12]
    imul ebx, 5
    shr ebx, 1
    add ebx, VIEWPORT_Y
    mov [ebp-8], ebx
    mov ecx, [ebp+8]
    add ecx, [ebp+16]
    imul ecx, 5
    shr ecx, 1
    add ecx, VIEWPORT_X
    sub ecx, eax
    mov edx, [ebp+12]
    add edx, [ebp+20]
    imul edx, 5
    shr edx, 1
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
    sub al, 'a' - 'A'
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
    %include "vga_palette.inc"
    VGA_PALETTE_TABLE desktop_vga_palette
    title_text: db 'NOVA DESKTOP', 0
    subtitle_text: db 'WELCOME', 0
    computer_label: db 'MY PC', 0
    folder_label: db 'FILES', 0
    welcome_text: db 'NOVA OS', 0
    ready_text: db 'DESKTOP READY', 0
    start_text: db 'START', 0
    taskbar_text: db 'NOVA OS', 0
    clock_text: db '08:00', 0
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
