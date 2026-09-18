# Extract ASCII characters from HZK12 file
# HZK12 format: each character is 24 bytes (12 rows x 2 bytes)
# ASCII characters start at offset 0

$hzkPath = "HZK\HZK12"
$bytes = [System.IO.File]::ReadAllBytes($hzkPath)

Write-Host "HZK12 file size: $($bytes.Length) bytes"
Write-Host "Characters in file: $($bytes.Length / 24)"

# Extract characters we need: N, o, v, a, space, O, S, W, e, l, c, m, U, s, r, n, :, P, w, d, L, g, i
$neededChars = @('N', 'o', 'v', 'a', ' ', 'O', 'S', 'W', 'e', 'l', 'c', 'm', 'U', 's', 'r', 'n', ':', 'P', 'w', 'd', 'L', 'g', 'i')

$output = @()
$output += "; HZK12 font data extracted from HZK12 file"
$output += "; Each character: 12 rows x 2 bytes = 24 bytes"
$output += ""

foreach ($char in $neededChars) {
    $ascii = [int][char]$char
    $offset = $ascii * 24
    
    $charName = if ($char -eq ' ') { 'space' } else { "'$char'" }
    $output += "    ; $charName (ASCII $ascii)"
    
    for ($row = 0; $row -lt 12; $row++) {
        $byte1 = $bytes[$offset + $row * 2]
        $byte2 = $bytes[$offset + $row * 2 + 1]
        $word = ($byte1 -shl 8) -bor $byte2
        $output += "    dw 0x$('{0:X4}' -f $word)"
    }
    
    $output += ""
}

# Add terminator
$output += "    ; Terminator"
$output += "    dw 0x0000"

($output -join "`n") | Set-Content "hzk12_extracted.asm" -NoNewline
Write-Host "Generated hzk12_extracted.asm"

# Also show what the characters look like
Write-Host "`nCharacter preview:"
foreach ($char in $neededChars) {
    $ascii = [int][char]$char
    $offset = $ascii * 24
    $charName = if ($char -eq ' ') { 'space' } else { "'$char'" }
    Write-Host "`n$charName (ASCII $ascii):"
    
    $hasData = $false
    for ($row = 0; $row -lt 12; $row++) {
        $byte1 = $bytes[$offset + $row * 2]
        $byte2 = $bytes[$offset + $row * 2 + 1]
        if ($byte1 -ne 0 -or $byte2 -ne 0) {
            $hasData = $true
            break
        }
    }
    
    if ($hasData) {
        for ($row = 0; $row -lt 12; $row++) {
            $byte1 = $bytes[$offset + $row * 2]
            $byte2 = $bytes[$offset + $row * 2 + 1]
            $binary = [Convert]::ToString($byte1, 2).PadLeft(8, '0') + [Convert]::ToString($byte2, 2).PadLeft(8, '0')
            $visual = $binary.Replace('0', '.').Replace('1', '#')
            Write-Host "  $visual"
        }
    } else {
        Write-Host "  (no data - all zeros)"
    }
}