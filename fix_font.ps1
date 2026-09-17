$content = Get-Content stage2.asm -Raw
$lines = $content -split "`r?`n"
$result = @()
$inFont = $false
$charLineCount = 0

foreach ($line in $lines) {
    if ($line -match "^\s*;\s*'.*'\s*-\s*16x12 bitmap") {
        $inFont = $true
        $charLineCount = 0
        $result += $line -replace "16x12", "12x12"
        continue
    }
    if ($inFont -and $line -match "^\s*times\s+16\s+dw") {
        $result += $line -replace "times 16", "times 12"
        continue
    }
    if ($inFont -and $line -match "^\s*dw\s+0x") {
        $charLineCount++
        if ($charLineCount -le 2 -or $charLineCount -gt 14) {
            if ($charLineCount -gt 14) {
                $inFont = $false
            }
            continue
        }
        $result += $line
        continue
    }
    if ($inFont -and $line -match "^\s*$") {
        if ($charLineCount -ge 14) {
            $inFont = $false
        }
        $result += $line
        continue
    }
    $result += $line
}

($result -join "`n") | Set-Content stage2.asm -NoNewline
Write-Host "Font data fixed to 12 rows"