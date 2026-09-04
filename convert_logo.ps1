param(
    [string]$LogoPath = "$PSScriptRoot\logo.png",
    [string]$OutputPath = "$PSScriptRoot\logo.raw"
)

Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::FromFile($LogoPath)
$bmp = New-Object System.Drawing.Bitmap($bmp, 60, 60)

$pixels = New-Object byte[] (60 * 60)
$off = 0

for ($y = 0; $y -lt 60; $y++) {
    for ($x = 0; $x -lt 60; $x++) {
        $c = $bmp.GetPixel($x, $y)
        $brightness = ($c.R + $c.G + $c.B) / 3
        
        if ($brightness -ge 220) {
            $pixels[$off] = 0x17
        } elseif ($brightness -ge 180) {
            $pixels[$off] = 0x0F
        } elseif ($brightness -ge 140) {
            $pixels[$off] = 0x0E
        } elseif ($brightness -ge 100) {
            $pixels[$off] = 0x06
        } elseif ($brightness -ge 50) {
            $pixels[$off] = 0x04
        } else {
            $pixels[$off] = 0x00
        }
        $off++
    }
}

[System.IO.File]::WriteAllBytes($OutputPath, $pixels)
Write-Host "Converted logo to $OutputPath ($($pixels.Length) bytes)"

$bmp.Dispose()