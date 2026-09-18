# Check HZK12 file structure
$hzkPath = "HZK\HZK12"
$bytes = [System.IO.File]::ReadAllBytes($hzkPath)

Write-Host "HZK12 file size: $($bytes.Length) bytes"
Write-Host "Total characters: $($bytes.Length / 24)"

# HZK12 is a Chinese font file, not ASCII
# Characters are indexed by GB2312: (区码-1) * 94 + (位码-1)
# 区码 starts from 16 (0x10) for Chinese characters

# Check first few characters
Write-Host "`nFirst 5 characters:"
for ($i = 0; $i -lt 5; $i++) {
    $offset = $i * 24
    $hasData = $false
    for ($j = 0; $j -lt 24; $j++) {
        if ($bytes[$offset + $j] -ne 0) {
            $hasData = $true
            break
        }
    }
    Write-Host "  Char $i`: $(if ($hasData) {'Has data'} else {'Empty'})"
}

# Check character at 区码 16, 位码 1 (first Chinese character)
# Index = (16-1) * 94 + (1-1) = 15 * 94 = 1410
$firstHanzi = 1410
$offset = $firstHanzi * 24
Write-Host "`nFirst Chinese character (区码 16, 位码 1) at index $firstHanzi, offset $offset`:"
for ($row = 0; $row -lt 12; $row++) {
    $byte1 = $bytes[$offset + $row * 2]
    $byte2 = $bytes[$offset + $row * 2 + 1]
    $binary = [Convert]::ToString($byte1, 2).PadLeft(8, '0') + [Convert]::ToString($byte2, 2).PadLeft(8, '0')
    $visual = $binary.Replace('0', '.').Replace('1', '#')
    Write-Host "  $visual"
}

# Check if ASCII characters exist (they usually don't in HZK files)
Write-Host "`nChecking ASCII 'N' (78) at offset $((78 * 24)):"
$offset = 78 * 24
$hasData = $false
for ($j = 0; $j -lt 24; $j++) {
    if ($bytes[$offset + $j] -ne 0) {
        $hasData = $true
        break
    }
}
Write-Host "  $(if ($hasData) {'Has data'} else {'Empty - ASCII not in HZK12'})"