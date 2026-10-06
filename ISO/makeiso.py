#!/usr/bin/env python3
"""
Create bootable ISO using El Torito no-emulation mode.
Combines boot.img + kernel.bin into a single boot image.
"""

import struct
import sys
import os

def create_iso(boot_img_path, kernel_bin_path, iso_path):
    SECTOR_SIZE = 2048
    
    with open(boot_img_path, 'rb') as f:
        boot_data = f.read()
    
    with open(kernel_bin_path, 'rb') as f:
        kernel_data = f.read()
    
    if len(boot_data) != 512:
        print(f"[ERROR] Boot image must be exactly 512 bytes, got {len(boot_data)}")
        return False
    
    if boot_data[510:512] != b'\x55\xaa':
        print("[ERROR] Invalid boot signature")
        return False
    
    # Create combined boot image (boot + kernel)
    # Align to 2048 bytes for ISO sector size
    combined_size = 512 + len(kernel_data)
    padded_size = (combined_size + SECTOR_SIZE - 1) // SECTOR_SIZE * SECTOR_SIZE
    combined_boot = bytearray(padded_size)
    combined_boot[:512] = boot_data
    combined_boot[512:512 + len(kernel_data)] = kernel_data
    
    boot_sectors = padded_size // SECTOR_SIZE
    
    # ISO layout:
    # Sector 0-15: System Area
    # Sector 16: Primary Volume Descriptor
    # Sector 17: Boot Record
    # Sector 18: Boot Catalog
    # Sector 19: Root Directory
    # Sector 20+: Combined boot image
    
    BOOT_CATALOG_SECTOR = 18
    BOOT_IMAGE_SECTOR = 20
    ROOT_DIR_SECTOR = 19
    total_sectors = 20 + boot_sectors
    
    # Create ISO data
    iso_data = bytearray(total_sectors * SECTOR_SIZE)
    
    def write_str(buf, offset, s, length):
        s_bytes = s.encode('ascii')[:length]
        buf[offset:offset+len(s_bytes)] = s_bytes
        for i in range(len(s_bytes), length):
            buf[offset + i] = 0x20
    
    def to_bcd(n):
        return ((n // 10) << 4) | (n % 10)
    
    def write_datetime(buf, offset):
        buf[offset:offset+16] = bytes([
            to_bcd(20), to_bcd(26), to_bcd(8), to_bcd(25),
            to_bcd(0), to_bcd(0), to_bcd(0), to_bcd(0),
            to_bcd(0), to_bcd(0), to_bcd(0), to_bcd(0),
            to_bcd(0), to_bcd(0), to_bcd(0), to_bcd(0)
        ])
        buf[offset+16] = 0
    
    def pack_both(buf, off, val):
        struct.pack_into('<I', buf, off, val)
        struct.pack_into('>I', buf, off+4, val)
        struct.pack_into('<H', buf, off+8, val)
        struct.pack_into('>H', buf, off+10, val)
    
    # === Primary Volume Descriptor (Sector 16) ===
    pvd = bytearray(SECTOR_SIZE)
    pvd[0] = 0x01
    pvd[1:6] = b'CD001'
    pvd[6] = 0x01
    
    write_str(pvd, 8, 'NOVA-OS', 32)
    write_str(pvd, 40, 'NOVA-OS', 32)
    
    pack_both(pvd, 80, total_sectors)
    pack_both(pvd, 128, 1)
    pack_both(pvd, 132, 1)
    pack_both(pvd, 136, SECTOR_SIZE)
    pack_both(pvd, 140, 0)
    
    pack_both(pvd, 144, 0)
    pack_both(pvd, 148, 0)
    pack_both(pvd, 152, 0)
    pack_both(pvd, 156, 0)
    
    # Root directory record
    root_rec = bytearray(34)
    root_rec[0] = 34
    root_rec[1] = 0
    struct.pack_into('<I', root_rec, 2, ROOT_DIR_SECTOR)
    struct.pack_into('>I', root_rec, 6, ROOT_DIR_SECTOR)
    struct.pack_into('<I', root_rec, 10, 0)
    struct.pack_into('>I', root_rec, 14, 0)
    root_rec[18:25] = bytes(7)
    root_rec[25] = 0x02
    root_rec[26] = 0
    root_rec[27] = 0
    struct.pack_into('<H', root_rec, 28, 1)
    struct.pack_into('>H', root_rec, 30, 1)
    root_rec[32] = 1
    root_rec[33] = 0x00
    
    pvd[156:190] = root_rec
    
    write_str(pvd, 190, 'NOVA-OS', 128)
    write_str(pvd, 318, 'NOVA-OS', 128)
    write_str(pvd, 446, 'NOVA-OS', 128)
    write_str(pvd, 574, 'NOVA-OS', 128)
    write_str(pvd, 702, '', 37)
    write_str(pvd, 739, '', 37)
    write_str(pvd, 776, '', 37)
    
    write_datetime(pvd, 813)
    write_datetime(pvd, 830)
    write_datetime(pvd, 847)
    write_datetime(pvd, 864)
    
    pvd[881] = 0x01
    
    iso_data[16*SECTOR_SIZE:17*SECTOR_SIZE] = pvd
    
    # === Boot Record (Sector 17) ===
    boot_rec = bytearray(SECTOR_SIZE)
    boot_rec[0] = 0x00
    boot_rec[1:6] = b'CD001'
    boot_rec[6] = 0x01
    write_str(boot_rec, 7, 'EL TORITO SPECIFICATION', 23)
    struct.pack_into('<I', boot_rec, 71, BOOT_CATALOG_SECTOR)
    iso_data[17*SECTOR_SIZE:18*SECTOR_SIZE] = boot_rec
    
    # === Boot Catalog (Sector 18) ===
    catalog = bytearray(SECTOR_SIZE)
    
    # Validation Entry (32 bytes)
    catalog[0] = 0x01        # Header ID
    catalog[1] = 0x00        # Platform ID (x86)
    struct.pack_into('<H', catalog, 2, 0x0000)  # Reserved
    write_str(catalog, 4, 'NOVA-OS', 24)  # ID string
    # Checksum at bytes 28-29 (zeroed first)
    catalog[28] = 0
    catalog[29] = 0
    catalog[30] = 0x55       # Key byte 1
    catalog[31] = 0xAA       # Key byte 2
    
    # Calculate checksum (sum of all 32 bytes as 16-bit words, should equal 0)
    checksum = 0
    for i in range(0, 32, 2):
        checksum += catalog[i] | (catalog[i+1] << 8)
    checksum = (-checksum) & 0xFFFF
    struct.pack_into('<H', catalog, 28, checksum)
    
    # Boot Entry (32 bytes starting at offset 32)
    catalog[32] = 0x88       # Boot indicator (0x88 = bootable)
    catalog[33] = 0x00       # Media type (0x00 = no emulation)
    struct.pack_into('<H', catalog, 34, 0x07C0)  # Load segment
    catalog[36] = 0x00       # System type
    catalog[37] = 0x00       # Reserved
    struct.pack_into('<H', catalog, 38, boot_sectors)  # Sector count
    struct.pack_into('<I', catalog, 40, BOOT_IMAGE_SECTOR)  # LBA of boot image
    
    iso_data[18*SECTOR_SIZE:19*SECTOR_SIZE] = catalog
    
    # === Root Directory (Sector 19) ===
    root_dir = bytearray(SECTOR_SIZE)
    
    dot = bytearray(34)
    dot[0] = 34
    struct.pack_into('<I', dot, 2, ROOT_DIR_SECTOR)
    struct.pack_into('<I', dot, 10, 0)
    dot[25] = 0x02
    struct.pack_into('<H', dot, 28, 1)
    dot[32] = 1
    dot[33] = 0x00
    root_dir[0:34] = dot
    
    dotdot = bytearray(34)
    dotdot[0] = 34
    struct.pack_into('<I', dotdot, 2, ROOT_DIR_SECTOR)
    struct.pack_into('<I', dotdot, 10, 0)
    dotdot[25] = 0x02
    struct.pack_into('<H', dotdot, 28, 1)
    dotdot[32] = 1
    dotdot[33] = 0x00
    root_dir[34:68] = dotdot
    
    iso_data[19*SECTOR_SIZE:20*SECTOR_SIZE] = root_dir
    
    # === Boot Image (Sector 20+) ===
    boot_offset = BOOT_IMAGE_SECTOR * SECTOR_SIZE
    iso_data[boot_offset:boot_offset + padded_size] = combined_boot
    
    with open(iso_path, 'wb') as f:
        f.write(iso_data)
    
    print(f"[OK] Created ISO: {iso_path}")
    print(f"     Size: {total_sectors * SECTOR_SIZE} bytes ({total_sectors * SECTOR_SIZE / 1024 / 1024:.1f} MB)")
    print(f"     Boot sectors: {boot_sectors}")
    print(f"     Mode: No Emulation (Standard CD-ROM boot)")
    return True

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <boot.img> <kernel.bin> <output.iso>")
        sys.exit(1)
    
    boot_img = sys.argv[1]
    kernel_bin = sys.argv[2]
    iso_path = sys.argv[3]
    
    if not os.path.exists(boot_img):
        print(f"[ERROR] Boot image not found: {boot_img}")
        sys.exit(1)
    
    if not os.path.exists(kernel_bin):
        print(f"[ERROR] Kernel not found: {kernel_bin}")
        sys.exit(1)
    
    create_iso(boot_img, kernel_bin, iso_path)