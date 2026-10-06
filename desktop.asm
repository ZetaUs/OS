bits 32

VGA_MEMORY equ 0xA0000
SCREEN_WIDTH equ 320

global _desktop_screen

section .text

_desktop_screen:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; Blue wallpaper with a layered horizon.
    push dword 1
    push dword 200
    push dword 320
    push dword 0
    push dword 0
    call draw_rect
    add esp, 20

    push dword 9
    push dword 52
    push dword 320
    push dword 126
    push dword 0
    call draw_rect
    add esp, 20

    push dword 1
    push dword 35
    push dword 320
    push dword 143
    push dword 0
    call draw_rect
    add esp, 20

    push dword 3
    push dword 120
    push dword 320
    push dword 80
    push dword 0
    call draw_rect
    add esp, 20

    ; Header.
    push dword 15
    push dword title_text
    push dword 8
    push dword 8
    call draw_text
    add esp, 16

    push dword 11
    push dword subtitle_text
    push dword 20
    push dword 8
    call draw_text
    add esp, 16

    ; Computer icon.
    push dword 15
    push dword 26
    push dword 30
    push dword 21
    push dword 12
    call draw_rect
    add esp, 20
    push dword 9
    push dword 22
    push dword 22
    push dword 23
    push dword 16
    call draw_rect
    add esp, 20
    push dword 7
    push dword 3
    push dword 10
    push dword 26
    push dword 22
    call draw_rect
    add esp, 20
    push dword 15
    push dword 2
    push dword 16
    push dword 31
    push dword 19
    call draw_rect
    add esp, 20

    push dword 15
    push dword computer_label
    push dword 59
    push dword 12
    call draw_text
    add esp, 16

    ; Folder icon.
    push dword 14
    push dword 6
    push dword 27
    push dword 92
    push dword 14
    call draw_rect
    add esp, 20
    push dword 6
    push dword 24
    push dword 29
    push dword 96
    push dword 12
    call draw_rect
    add esp, 20
    push dword 14
    push dword folder_label
    push dword 124
    push dword 12
    call draw_text
    add esp, 16

    ; A small centered welcome panel.
    push dword 8
    push dword 60
    push dword 170
    push dword 91
    push dword 74
    call draw_rect
    add esp, 20
    push dword 15
    push dword welcome_text
    push dword 91
    push dword 82
    call draw_text
    add esp, 16
    push dword 11
    push dword ready_text
    push dword 108
    push dword 82
    call draw_text
    add esp, 16

    ; Taskbar.
    push dword 8
    push dword 22
    push dword 320
    push dword 178
    push dword 0
    call draw_rect
    add esp, 20
    push dword 15
    push dword 1
    push dword 320
    push dword 178
    push dword 0
    call draw_rect
    add esp, 20

    ; Start button.
    push dword 1
    push dword 16
    push dword 58
    push dword 181
    push dword 5
    call draw_rect
    add esp, 20
    push dword 15
    push dword start_text
    push dword 186
    push dword 14
    call draw_text
    add esp, 16

    push dword 15
    push dword taskbar_text
    push dword 186
    push dword 76
    call draw_text
    add esp, 16

    push dword 7
    push dword 16
    push dword 49
    push dword 184
    push dword 265
    call draw_rect
    add esp, 20
    push dword 15
    push dword clock_text
    push dword 188
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
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    mov ecx, [ebp+16]
    mov edx, [ebp+20]
    mov esi, [ebp+24]
    test ecx, ecx
    jz .rect_done
    test edx, edx
    jz .rect_done
    cmp eax, SCREEN_WIDTH
    jae .rect_done
    cmp ebx, 200
    jae .rect_done
    mov edi, SCREEN_WIDTH
    sub edi, eax
    cmp ecx, edi
    jbe .rect_width_ok
    mov ecx, edi
.rect_width_ok:
    mov edi, 200
    sub edi, ebx
    cmp edx, edi
    jbe .rect_height_ok
    mov edx, edi
.rect_height_ok:
    imul ebx, SCREEN_WIDTH
    add ebx, eax
    add ebx, VGA_MEMORY
.rect_row:
    push ecx
    mov edi, ebx
    mov eax, esi
    rep stosb
    pop ecx
    add ebx, SCREEN_WIDTH
    dec edx
    jnz .rect_row

.rect_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
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
    jb .char_space
    cmp al, 'z'
    ja .char_space
    sub al, 'a' - 'A'
.char_upper:
    sub al, 'A'
    movzx ebx, al
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_space:
    cmp al, ' '
    jne .char_blank
    add al, 26
    movzx ebx, al
    shl ebx, 3
    add ebx, font_data
    jmp .char_draw
.char_blank:
    mov ebx, blank_glyph
.char_draw:
    mov eax, [ebp+8]
    mov edx, [ebp+12]
    imul edx, SCREEN_WIDTH
    add eax, edx
    add eax, VGA_MEMORY
    mov edi, eax
    mov edx, [ebp+20]
    mov ecx, 8
.char_row:
    push ecx
    mov al, [ebx]
    mov ecx, 8
.char_column:
    test al, 0x80
    jz .char_skip_pixel
    mov [edi], dl
.char_skip_pixel:
    shl al, 1
    inc edi
    loop .char_column
    pop ecx
    add edi, SCREEN_WIDTH - 8
    inc ebx
    loop .char_row

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

section .data
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
