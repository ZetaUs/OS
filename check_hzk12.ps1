# 检查HZK12文件结构
$hzkPath = "HZK\HZK12"
$bytes = [System.IO.File]::ReadAllBytes($hzkPath)

Write-Host "HZK12 file size: $($bytes.Length) bytes"
Write-Host "Total characters: $($bytes.Length / 24)"

# 检查前几个字符
Write-Host "`nFirst 10 characters:"
for ($i = 0; $i -lt 10; $i++) {
    $offset = $i * 24
    $allZero = $true
    for ($j = 0; $j -lt 24; $j++) {
        if ($bytes[$offset + $j] -ne 0) {
            $allZero = $false
            break
        }
    }
    Write-Host "  Char $i`: $(if ($allZero) {'All zeros'} else {'Has data'})"
}

# 检查'N' (ASCII 78)
$charN_offset = 78 * 24
Write-Host "`nCharacter 'N' (ASCII 78) at offset ${charN_offset}:"
$allZero = $true
for ($j = 0; $j -lt 24; $j++) {
    if ($bytes[$charN_offset + $j] -ne 0) {
        $allZero = $false
        break
    }
}
Write-Host "  $(if ($allZero) {'All zeros'} else {'Has data'})"

# 检查汉字区开始位置
$hanziOffset = 128 * 24
Write-Host "`nChinese character zone starts at offset ${hanziOffset}:"
$allZero = $true
for ($j = 0; $j -lt 24; $j++) {
    if ($bytes[$hanziOffset + $j] -ne 0) {
        $allZero = $false
        break
    }
}
Write-Host "  First hanzi: $(if ($allZero) {'All zeros'} else {'Has data'})"

# 查找第一个非零字符
Write-Host "`nSearching for first non-zero character..."
for ($i = 0; $i -lt 200; $i++) {
    $offset = $i * 24
    for ($j = 0; $j -lt 24; $j++) {
        if ($bytes[$offset + $j] -ne 0) {
            Write-Host "  First non-zero char at index $i (offset $offset)"
            for ($row = 0; $row -lt 12; $row++) {
                $byte1 = $bytes[$offset + $row * 2]
                $byte2 = $bytes[$offset + $row * 2 + 1]
                $word = ($byte1 -shl 8) -bor $byte2
                $binary = [Convert]::ToString($word, 2).PadLeft(16, '0')
                Write-Host "    Row $row`: 0x$('{0:X4}' -f $word) = $binary"
            }
            break
        }
    }
    if ($i -lt 200) { break }
}