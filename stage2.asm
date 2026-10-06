bits 16
org 0x7E00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [boot_drive], dl
    sti

    ; Set DS to 0x07E0 so that [label] addresses resolve to 0x7E00+offset
    ; This is critical for lgdt and other memory accesses
    mov ax, 0x07E0
    mov ds, ax
    mov es, ax

    ; Enable A20 line (fast method via keyboard controller)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Switch to VGA mode 0x13 temporarily
    mov ax, 0x0013
    int 0x10

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Try VBE mode 0x115 (800x600x16) - best quality supported in QEMU
    mov ax, 0x4F01
    mov cx, 0x0115
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne .try_next_mode
    
    ; Check if mode has linear framebuffer
    test word [vbe_mode_info], 0x0081
    jnz .mode_found

.try_next_mode:
    ; Try VBE mode 0x112 (640x480x16) as fallback
    mov ax, 0x4F01
    mov cx, 0x0112
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004F
    jne vbe_error
    
    test word [vbe_mode_info], 0x0081
    jz vbe_error

.mode_found:
    ; Get framebuffer physical address
    mov eax, [vbe_mode_info + 40]
    test eax, eax
    jz vbe_error
    mov [framebuffer_base], eax
    
    ; Get width, height, bpp
    movzx eax, word [vbe_mode_info + 18]
    mov [vbe_width], eax
    movzx eax, word [vbe_mode_info + 20]
    mov [vbe_height], eax
    movzx eax, byte [vbe_mode_info + 25]
    mov [vbe_bpp], eax
    movzx eax, word [vbe_mode_info + 16]
    mov [vbe_pitch], eax

    ; Set VBE mode with linear framebuffer bit (0x4000)
    mov ax, 0x4F02
    mov bx, cx
    or bx, 0x4000
    int 0x10
    cmp ax, 0x004F
    jne vbe_error

    ; Display VBE success message
    mov si, vbe_ok_msg
    call print_string

    ; Load kernel from disk
    mov si, kernel_load_msg
    call print_string
    
    mov si, kernel_dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc kernel_load_error

    ; Display kernel loaded message
    mov si, kernel_loaded_msg
    call print_string

    cli
    lgdt [gdt_descriptor]
    
    ; Copy VBE parameters to fixed address 0x5000 before entering protected mode
    ; This is necessary because in protected mode with GDT base=0, 
    ; variable addresses would be wrong
    mov eax, [framebuffer_base]
    mov [0x5000], eax
    mov eax, [vbe_width]
    mov [0x5004], eax
    mov eax, [vbe_height]
    mov [0x5008], eax
    movzx eax, word [vbe_pitch]
    mov [0x500C], eax
    movzx eax, byte [vbe_bpp]
    mov [0x5010], eax
    
    ; Display protected mode message
    mov si, prot_mode_msg
    call print_string
    
    ; Disable interrupts and prepare for protected mode
    in al, 0x21
    or al, 0xFF
    out 0x21, al
    in al, 0xA1
    or al, 0xFF
    out 0xA1, al
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; Far jump to protected mode entry using retf
    ; Push 16-bit values for 16-bit retf
    push 0x08
    push word protected_mode_entry
    retf

vbe_error:
    mov si, vbe_error_message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

kernel_load_error:
    mov si, error_message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

; Print string function
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; Print 32-bit hex value in EAX to VGA text mode at ESI
print_hex:
    push ecx
    push edx
    push ebx
    mov ecx, 8
.hex_loop:
    rol eax, 4
    mov edx, eax
    and edx, 0xF
    cmp dl, 10
    jl .hex_digit
    add dl, 7
.hex_digit:
    add dl, '0'
    mov [esi], dl
    add esi, 2
    dec ecx
    jnz .hex_loop
    pop ebx
    pop edx
    pop ecx
    ret

align 8
gdt_start:
    dq 0
    ; 32-bit code segment (base=0, limit=4GB)
    dw 0xFFFF        ; Limit (15:0)
    dw 0x0000        ; Base (15:0)
    db 0x00          ; Base (23:16)
    db 0x9A          ; Access (present, ring 0, code, readable)
    db 0xCF          ; Flags (G=1, D=1) + Limit (19:16)
    db 0x00          ; Base (31:24)
    ; 32-bit data segment (base=0, limit=4GB)
    dw 0xFFFF        ; Limit (15:0)
    dw 0x0000        ; Base (15:0)
    db 0x00          ; Base (23:16)
    db 0x92          ; Access (present, ring 0, data, writable)
    db 0xCF          ; Flags (G=1, D=1) + Limit (19:16)
    db 0x00          ; Base (31:24)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

kernel_dap:
    db 0x10, 0
    dw 128
    dw 0
    dw 0x1000
    dd 20
    dd 0

hzk_dap:
    db 0x10, 0
    dw 288
    dw 0
    dw 0x2000
    dd 73
    dd 0

boot_drive: db 0
boot_msg: db 'Nova OS Booting...', 13, 10, 0
vbe_ok_msg: db 'VBE Mode OK', 13, 10, 0
kernel_load_msg: db 'Loading kernel...', 13, 10, 0
kernel_loaded_msg: db 'Kernel loaded', 13, 10, 0
prot_mode_msg: db 'Entering protected mode...', 13, 10, 0
error_message: db 'Kernel load error', 0
vbe_error_message: db 'VBE mode error', 0
framebuffer_base: dd 0
vbe_width: dd 0
vbe_height: dd 0
vbe_bpp: db 0
vbe_pitch: dw 0
align 4
vbe_mode_info: times 256 db 0

bits 32
protected_mode_entry:
    cld
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Write "PM OK" to VGA text mode to confirm protected mode works
    mov edi, 0xB8000
    mov word [edi], 0x0E50  ; 'P' in yellow
    mov word [edi+2], 0x0E4D ; 'M' in yellow
    mov word [edi+4], 0x0E20 ; ' ' in yellow
    mov word [edi+6], 0x0E4F ; 'O' in yellow
    mov word [edi+8], 0x0E4B ; 'K' in yellow

    ; VBE parameters are already at 0x5000-0x5010 from real mode
    ; No need to copy again

continue_boot:
    ; Test: Fill framebuffer with blue directly from stage2
    ; Get framebuffer address from 0x5000
    mov eax, [0x5000]        ; framebuffer_base
    mov ebx, [0x5004]        ; width
    mov ecx, [0x5008]        ; height
    mov edx, [0x500C]        ; pitch
    movzx esi, byte [0x5010] ; bpp
    
    ; Debug: Show framebuffer info in VGA text mode
    mov edi, 0xB8000
    
    ; Show "FB="
    mov word [edi], 0x0E46   ; 'F'
    mov word [edi+2], 0x0E42 ; 'B'
    mov word [edi+4], 0x0E3D ; '='
    
    ; Show framebuffer address in hex (simplified)
    ; Just show first 4 hex digits of the address
    mov eax, [0x5000]
    shr eax, 16              ; Get upper 16 bits
    mov ecx, 4
    mov esi, edi + 10
.addr_loop:
    rol eax, 4
    mov edx, eax
    and edx, 0xF
    cmp dl, 10
    jl .digit
    add dl, 7
.digit:
    add dl, '0'
    mov [esi], dl
    add esi, 2
    dec ecx
    jnz .addr_loop
    
    ; Show "W=" and width
    mov word [edi+20], 0x0E57 ; 'W'
    mov word [edi+22], 0x0E3D ; '='
    mov eax, [0x5004]
    mov esi, edi + 26
    call print_hex
    
    ; Show "H=" and height
    mov word [edi+40], 0x0E48 ; 'H'
    mov word [edi+42], 0x0E3D ; '='
    mov eax, [0x5008]
    mov esi, edi + 46
    call print_hex
    
    ; Show "BPP=" and bpp
    mov word [edi+60], 0x0E42 ; 'B'
    mov word [edi+62], 0x0E50 ; 'P'
    mov word [edi+64], 0x0E50 ; 'P'
    mov word [edi+66], 0x0E3D ; '='
    movzx eax, byte [0x5010]
    mov esi, edi + 70
    call print_hex
    
    ; If framebuffer is 0, halt immediately
    cmp dword [0x5000], 0
    je .halt
    
    ; Fill framebuffer with blue (0x0000AA in 24-bit, or RGB565 blue in 16-bit)
    mov edi, [0x5000]        ; edi = framebuffer address
    mov eax, [0x5004]        ; eax = width
    mul dword [0x5008]       ; eax = width * height (total pixels)
    mov ecx, eax             ; ecx = pixel count
    movzx esi, byte [0x5010] ; bpp
    
.fill_loop:
    cmp esi, 16
    je .write16
    cmp esi, 24
    je .write24
    cmp esi, 32
    je .write32
    jmp .skip_write

.write16:
    ; 16-bit RGB565 blue = 0x001F
    mov word [edi], 0x001F
    add edi, 2
    jmp .next_pixel

.write24:
    ; 24-bit BGR blue = 0xAA0000
    mov byte [edi], 0xAA     ; Blue
    mov byte [edi+1], 0x00   ; Green
    mov byte [edi+2], 0x00   ; Red
    add edi, 3
    jmp .next_pixel

.write32:
    ; 32-bit BGRA blue = 0xAA0000FF
    mov byte [edi], 0xAA     ; Blue
    mov byte [edi+1], 0x00   ; Green
    mov byte [edi+2], 0x00   ; Red
    mov byte [edi+3], 0xFF   ; Alpha
    add edi, 4
    jmp .next_pixel

.next_pixel:
    dec ecx
    jnz .fill_loop

.skip_write:
    ; Show "DONE" after filling
    mov edi, 0xB8000 + 160
    mov word [edi], 0x0C44   ; 'D'
    mov word [edi+2], 0x0C4F ; 'O'
    mov word [edi+4], 0x0C4E ; 'N'
    mov word [edi+6], 0x0C45 ; 'E'

.halt:
    ; Halt after filling framebuffer
    cli
    hlt
    jmp .halt

halt_kernel:
    cli
    hlt
    jmp halt_kernel

vbe_protected_error:
    cli
    hlt
    jmp vbe_protected_error