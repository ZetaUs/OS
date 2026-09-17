# 创建ASCII字符的字体数据（12x12像素）
# 用于显示英文文本

$fontData = @()

# 'N' - 12x12
$fontData += "    ; 'N'"
$fontData += "    dw 0x8001"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xE007"
$fontData += "    dw 0xF00F"
$fontData += "    dw 0xF81F"
$fontData += "    dw 0xFC3F"
$fontData += "    dw 0xFE7F"
$fontData += "    dw 0xFF7F"
$fontData += "    dw 0xFF3F"
$fontData += "    dw 0xFE1F"
$fontData += "    dw 0xFC0F"
$fontData += "    dw 0xF807"
$fontData += ""

# 'o' - 12x12
$fontData += "    ; 'o'"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0xE007"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xE007"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0x3FFC"
$fontData += ""

# 'v' - 12x12
$fontData += "    ; 'v'"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x8001"
$fontData += "    dw 0x8001"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0x6006"
$fontData += "    dw 0x6006"
$fontData += "    dw 0x300C"
$fontData += "    dw 0x1818"
$fontData += "    dw 0x0FF0"
$fontData += "    dw 0x0000"
$fontData += ""

# 'a' - 12x12
$fontData += "    ; 'a'"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0FF0"
$fontData += "    dw 0x1FF8"
$fontData += "    dw 0x300C"
$fontData += "    dw 0x300C"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x300C"
$fontData += "    dw 0x300C"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x1FF8"
$fontData += "    dw 0x0FF0"
$fontData += ""

# ' ' - space
$fontData += "    ; ' '"
$fontData += "    times 12 dw 0x0000"
$fontData += ""

# 'O' - 12x12
$fontData += "    ; 'O'"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0xE007"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xE007"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0x3FFC"
$fontData += ""

# 'S' - 12x12
$fontData += "    ; 'S'"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x0000"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0xC003"
$fontData += "    dw 0xC003"
$fontData += "    dw 0x3FFC"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0xE007"
$fontData += "    dw 0xC003"
$fontData += "    dw 0x7FFE"
$fontData += "    dw 0x3FFC"
$fontData += ""

# Terminator
$fontData += "    ; Terminator"
$fontData += "    dw 0x0000"

# 写入文件
($fontData -join "`n") | Set-Content "ascii_font_novas.asm" -NoNewline
Write-Host "Generated ascii_font_novas.asm"