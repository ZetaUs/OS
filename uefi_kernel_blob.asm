bits 64

global uefi_kernel_image
global uefi_kernel_image_end

section .rdata align=16
uefi_kernel_image:
    incbin "build/kernel.bin"
uefi_kernel_image_end:
