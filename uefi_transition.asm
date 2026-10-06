bits 64

global enter_kernel

section .text
enter_kernel:
    mov esi, ecx
    mov edi, edx
    cli
    lgdt [rel gdt_descriptor]
    push qword 0x10
    lea rax, [rel protected_entry]
    push rax
    retfq

bits 32
protected_entry:
    mov eax, cr0
    and eax, 0x7FFFFFFF
    mov cr0, eax

    mov ecx, 0xC0000080
    rdmsr
    and eax, 0xFFFFFEFF
    wrmsr

    mov ax, 0x18
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    mov [0x5000], edi
    mov dword [0x5004], 1920
    mov dword [0x5008], 1080
    mov dword [0x500C], 7680

    push edi
    mov eax, 0x200000
    call eax

.halt:
    cli
    hlt
    jmp .halt

align 8
gdt_start:
    dq 0
    dq 0x00AF9A000000FFFF
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start
