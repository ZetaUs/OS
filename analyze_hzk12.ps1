# 分析HZK12文件结构
$hzkPath = "HZK\HZK12"
$bytes = [System.IO.File]::ReadAllBytes($hzkPath)

Write-Host "HZK12 file size: $($bytes.Length) bytes"

# 检查前几个字符
Write-Host "`nFirst 10 characters (offset 0-239):"
for ($i = 0; $i -lt 10; $i++) {
    $offset = $i * 24
    $allZero = $true
    for ($j = 0; $j -lt 24; $j++) {
        if ($bytes[$offset + $j] -ne 0) {
            $allZero = $false
            break
        }
    }
    if ($allZero) {
        Write-Host "  Char $i`: All zeros"
    } else {
        Write-Host "  Char $i`: Has data"
        for ($row = 0; $row -lt 12; $row++) {
            $byte1 = $bytes[$offset + $row * 2]
            $byte2 = $bytes[$offset + $row * 2 + 1]
            $word = ($byte1 -shl 8) -bor $byte2
            if ($word -ne 0) {
                $binary = [Convert]::ToString($word, 2).PadLeft(16, '0')
                Write-Host "    Row $row`: 0x$('{0:X4}' -f $word) = $binary"
            }
        }
    }
}

# 检查'N' (ASCII 78)
$charN_offset = 78 * 24
Write-Host "`nCharacter 'N' (ASCII 78) at offset $charN_offset:"
$allZero = $true
for ($j = 0; $j -lt 24; $j++) {
    if ($bytes[$charN_offset + $j] -ne 0) {
        $allZero = $false
        break
    }
}
if ($allZero) {
    Write-Host "  All zeros - ASCII character zone may not contain font data"
} else {
    for ($row = 0; $row -lt 12; $row++) {
        $byte1 = $bytes[$charN_offset + $row * 2]
        $byte2 = $bytes[$charN_offset + $row * 2 + 1]
        $word = ($byte1 -shl 8) -bor $byte2
        $binary = [Convert]::ToString($word, 2).PadLeft(16, '0')
        Write-Host "  Row $row`: 0x$('{0:X4}' -f $word) = $binary"
    }
}

# 检查一些常见位置
Write-Host "`nChecking offset 3072 (128*24, start of Chinese characters):"
$offset = 3072
for ($row = 0; $row -lt 12; $row++) {
    $byte1 = $bytes[$offset + $row * 2]
    $byte2 = $bytes[$offset + $row * 2 + 1]
    $word = ($byte1 -shl 8) -bor $byte2
    if ($word -ne 0) {
        $binary = [Convert]::ToString($word, 2).PadLeft(16, '0')
        Write-Host "  Row $row`: 0x$('{0:X4}' -f $word) = $binary"
    }
}