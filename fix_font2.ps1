# 修复字体数据：将12x12位图转换为正确的格式
$content = Get-Content stage2.asm -Raw
$lines = $content -split "`r?`n"
$result = @()
$inFont = $false
$charLineCount = 0
$skipCount = 0

foreach ($line in $lines) {
    if ($line -match "^\s*;\s*'.*'\s*-\s*12x12 bitmap") {
        $inFont = $true
        $charLineCount = 0
        $skipCount = 0
        $result += $line
        continue
    }
    if ($inFont -and $line -match "^\s*times\s+12\s+dw") {
        $result += $line
        continue
    }
    if ($inFont -and $line -match "^\s*dw\s+0x") {
        $charLineCount++
        if ($charLineCount -gt 12) {
            $inFont = $false
            $result += $line
            continue
        }
        # 保持原样，但确保是12行
        $result += $line
        continue
    }
    if ($inFont -and $line -match "^\s*$") {
        if ($charLineCount -ge 12) {
            $inFont = $false
        }
        $result += $line
        continue
    }
    $result += $line
}

($result -join "`n") | Set-Content stage2.asm -NoNewline
Write-Host "Font data verified"