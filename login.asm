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
    push COLOR_BORDER
    push 120    ; height
    push 160    ; width
    push 40     ; y
    push 80     ; x
    call draw_rect
    add esp, 20
    
    ; Draw inner box
    push COLOR_INPUT
    push 112    ; height
    push 152    ; width
    push 44     ; y
    push 84     ; x
    call draw_rect
    add esp, 20
    
    ; Draw username input box
    push COLOR_BORDER
    push 12     ; height
    push 140    ; width
    push 85     ; y
    push 90     ; x
    call draw_rect
    add esp, 20
    
    ; Draw password input box
    push COLOR_BORDER
    push 12     ; height
    push 140    ; width
    push 115    ; y
    push 90     ; x
    call draw_rect
    add esp, 20
    
    ; Draw "LOGIN" button
    push COLOR_BUTTON
    push 16     ; height
    push 80     ; width
    push 135    ; y
    push 120    ; x
    call draw_rect
    add esp, 20
    
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
    mov edi, VGA_MEMORY
    mov eax, 90
    mov ebx, 160
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
    mov esi, welcome_msg
    mov ecx, 8
    mov edx, COLOR_TEXT
.welcome_loop:
    lodsb
    test al, al
    jz .welcome_done
    
    push ecx
    mov ecx, 8
.welcome_row:
    push ecx
    mov ecx, 8
.welcome_col:
    mov [edi], edx
    inc edi
    dec ecx
    jnz .welcome_col
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, 8
    dec ecx
    jnz .welcome_row
    pop ecx
    add edi, 8
    jmp .welcome_loop
.welcome_done:
    
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
; Stack: [ebp+8]=x, [ebp+12]=y, [ebp+16]=width, [ebp+20]=height, [ebp+24]=color
draw_rect:
    push ebp
    mov ebp, esp
    
    mov eax, [ebp+8]      ; x
    mov ebx, [ebp+12]     ; y
    mov ecx, [ebp+16]     ; width
    mov edx, [ebp+20]     ; height
    movzx esi, byte [ebp+24]  ; color (zero-extend to 32-bit)
    
    mov edi, VGA_MEMORY
    imul ebx, SCREEN_WIDTH
    add edi, ebx
    add edi, eax
    
.row_loop:
    push ecx
.col_loop:
    mov [edi], sil
    inc edi
    dec ecx
    jnz .col_loop
    pop ecx
    add edi, SCREEN_WIDTH
    sub edi, [ebp+16]
    dec edx
    jnz .row_loop
    
    pop ebp
    ret

section .data
    welcome_msg: db 'Welcome!', 0