bits 32

; VGA framebuffer address
VGA_MEMORY equ 0xA0000
SCREEN_WIDTH equ 320

; Colors
COLOR_BG equ 1        ; Blue background
COLOR_BORDER equ 8    ; Gray border
COLOR_TEXT equ 15     ; White text
COLOR_INPUT equ 0     ; Black input box
COLOR_BUTTON equ 14   ; Yellow button

global login_screen

section .text

login_screen:
    push ebp
    mov ebp, esp
    
    ; Clear screen with blue background
    mov edi, VGA_MEMORY
    mov ecx, 320 * 200
    mov al, COLOR_BG
    rep stosb
    
    ; Draw login box border
    mov eax, 80     ; x
    mov ebx, 40     ; y
    mov ecx, 160    ; width
    mov edx, 120    ; height
    mov esi, COLOR_BORDER
    call draw_rect
    
    ; Draw inner box
    mov eax, 84
    mov ebx, 44
    mov ecx, 152
    mov edx, 112
    mov esi, COLOR_INPUT
    call draw_rect
    
    ; Draw "LOGIN" title
    mov eax, 135    ; x (centered)
    mov ebx, 55     ; y
    mov esi, login_title
    mov edi, COLOR_TEXT
    call draw_text_simple
    
    ; Draw "Username:" label
    mov eax, 95
    mov ebx, 75
    mov esi, username_label
    mov edi, COLOR_TEXT
    call draw_text_simple
    
    ; Draw username input box
    mov eax, 90
    mov ebx, 85
    mov ecx, 140
    mov edx, 12
    mov esi, COLOR_BORDER
    call draw_rect
    
    ; Draw "Password:" label
    mov eax, 95
    mov ebx, 105
    mov esi, password_label
    mov edi, COLOR_TEXT
    call draw_text_simple
    
    ; Draw password input box
    mov eax, 90
    mov ebx, 115
    mov ecx, 140
    mov edx, 12
    mov esi, COLOR_BORDER
    call draw_rect
    
    ; Draw "LOGIN" button
    mov eax, 120
    mov ebx, 135
    mov ecx, 80
    mov edx, 16
    mov esi, COLOR_BUTTON
    call draw_rect
    
    ; Draw button text
    mov eax, 135
    mov ebx, 138
    mov esi, button_text
    mov edi, COLOR_INPUT
    call draw_text_simple
    
    ; Wait for user input
.wait_loop:
    in al, 0x64
    test al, 1
    jz .wait_loop
    
    in al, 0x60
    
    ; Check for Enter key (0x1C)
    cmp al, 0x1C
    je .login_success
    
    ; Check for Escape key (0x01)
    cmp al, 0x01
    je .login_exit
    
    jmp .wait_loop

.login_success:
    ; Draw "Welcome!" message
    mov eax, 125
    mov ebx, 90
    mov esi, welcome_msg
    mov edi, COLOR_TEXT
    call draw_text_simple
    
    ; Wait a moment
    mov ecx, 2000000
.delay:
    dec ecx
    jnz .delay
    
    jmp .login_exit

.login_exit:
    pop ebp
    ret

; Function: draw_rect
; Input: eax=x, ebx=y, ecx=width, edx=height, esi=color
draw_rect:
    push ebp
    mov ebp, esp
    push edi
    push ebx
    push ecx
    push edx
    
    mov edi, VGA_MEMORY
    imul edi, ebx, SCREEN_WIDTH
    add edi, eax
    
    movzx esi, si  ; Ensure esi is properly sized
    
    .row_loop:
        push ecx
        .col_loop:
            mov [edi], sil
            inc edi
            dec ecx
            jnz .col_loop
        pop ecx
        add edi, SCREEN_WIDTH
        sub edi, ecx
        dec edx
        jnz .row_loop
    
    pop edx
    pop ecx
    pop ebx
    pop edi
    pop ebp
    ret

; Function: draw_text_simple
; Input: eax=x, ebx=y, esi=text, edi=color
draw_text_simple:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    
    mov edx, VGA_MEMORY
    imul edx, ebx, SCREEN_WIDTH
    add edx, eax
    
    .char_loop:
        lodsb
        test al, al
        jz .done
        
        ; Draw simple character placeholder (8x8 block)
        mov ecx, 8
        .row:
            push ecx
            mov ecx, 8
            .col:
                mov [edx], dil
                inc edx
                dec ecx
                jnz .col
            pop ecx
            add edx, SCREEN_WIDTH
            sub edx, 8
            dec ecx
            jnz .row
        
        add edx, 8  ; space between characters
        jmp .char_loop
    
    .done:
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret

section .data
    login_title: db 'LOGIN', 0
    username_label: db 'Username:', 0
    password_label: db 'Password:', 0
    button_text: db 'LOGIN', 0
    welcome_msg: db 'Welcome!', 0