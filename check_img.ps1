$img = [System.IO.File]::ReadAllBytes('build\nova-os.img')
Write-Host "Image size: $($img.Length)"
Write-Host "Boot sector: 0x$('{0:X2}' -f $img[0]) 0x$('{0:X2}' -f $img[1])"
Write-Host "Stage2@512: 0x$('{0:X2}' -f $img[512]) 0x$('{0:X2}' -f $img[513])"
$logoOffset = 512 + 32768
Write-Host "Logo@$logoOffset : 0x$('{0:X2}' -f $img[$logoOffset]) 0x$('{0:X2}' -f $img[$logoOffset+1])"
$hzkOffset = 512 + 32768 + 25600
Write-Host "HZK16@$hzkOffset : 0x$('{0:X2}' -f $img[$hzkOffset]) 0x$('{0:X2}' -f $img[$hzkOffset+1])"
Write-Host "HZK16 expected size: 267616 bytes = 523 sectors"