# 从HZK12文件中提取ASCII字符的字体数据
$hzkPath = "HZK\HZK12"
$bytes = [System.IO.File]::ReadAllBytes($hzkPath)

Write-Host "HZK12 file size: $($bytes.Length) bytes"

# HZK12格式：每个字符24字节（12行 x 2字节/行）
# ASCII字符从偏移0开始，每个字符24字节
# 我们只需要前128个ASCII字符

$charSize = 24
$asciiCount = 128

# 生成汇编代码
$output = @()
$output += "; HZK12 font data extracted from HZK12 file"
$output += "; Each character: 12 rows x 2 bytes = 24 bytes"
$output += "; Format: Each row is 16 bits, left 12 bits are visible"
$output += ""

for ($i = 0; $i -lt $asciiCount; $i++) {
    $offset = $i * $charSize
    $char = [char]$i
    
    if ($char -eq "`n" -or $char -eq "`r") {
        $charName = "newline"
    } elseif ($char -eq " ") {
        $charName = "space"
    } elseif ($char -match '[a-zA-Z0-9]') {
        $charName = "'$char'"
    } else {
        $charName = "char_$i"
    }
    
    $output += "    ; $charName (ASCII $i)"
    
    for ($row = 0; $row -lt 12; $row++) {
        $byte1 = $bytes[$offset + $row * 2]
        $byte2 = $bytes[$offset + $row * 2 + 1]
        $word = ($byte1 -shl 8) -bor $byte2
        $output += "    dw 0x$('{0:X4}' -f $word)"
    }
    
    $output += ""
}

# 写入文件
$output -join "`n" | Set-Content "hzk12_ascii.asm" -NoNewline
Write-Host "Generated hzk12_ascii.asm with $asciiCount characters"