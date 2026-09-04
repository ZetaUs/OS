$logoPath = "$PSScriptRoot\logo.raw"
$stage2Path = "$PSScriptRoot\stage2.asm"

$logoData = [System.IO.File]::ReadAllBytes($logoPath)

$asmData = "logo_data:`n"
for ($i = 0; $i -lt $logoData.Length; $i += 16) {
    $line = "    db "
    $end = [Math]::Min($i + 16, $logoData.Length)
    $bytes = @()
    for ($j = $i; $j -lt $end; $j++) {
        $bytes += ("0x{0:X2}" -f $logoData[$j])
    }
    $line += ($bytes -join ", ")
    $asmData += $line + "`n"
}

$stage2Content = Get-Content $stage2Path -Raw
$pattern = '(?s)logo_data:.*?(?=times 8192-)'
$stage2Content = $stage2Content -replace $pattern, $asmData

Set-Content $stage2Path $stage2Content -NoNewline
Write-Host "Embedded logo data into stage2.asm"