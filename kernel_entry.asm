bits 32

global _kernel_entry
extern _kernel_main

section .text
_kernel_entry:
    jmp _kernel_main
