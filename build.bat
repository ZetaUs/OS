@echo off
setlocal
set "ROOT=%~dp0.."
set "NASM=%ROOT%\Program\NASM\nasm.exe"
set "GCC=D:\Program Files (x86)\Dev-Cpp\MinGW64\bin\gcc.exe"
set "LD=D:\Program Files (x86)\Dev-Cpp\MinGW64\bin\ld.exe"
set "OBJCOPY=D:\Program Files (x86)\Dev-Cpp\MinGW64\bin\objcopy.exe"
set "OUT=%~dp0build"
if not exist "%OUT%" mkdir "%OUT%"

echo [1/4] Assembling boot sector...
"%NASM%" -f bin "%~dp0boot.asm" -o "%OUT%\boot.bin"
if errorlevel 1 exit /b 1

echo [2/4] Assembling stage2...
"%NASM%" -f bin "%~dp0stage2.asm" -o "%OUT%\stage2.bin"
if errorlevel 1 exit /b 1

echo [3/4] Building disk image...

:: Create a proper hard disk image with logo and HZK16 data
:: Layout:
::   LBA 0: boot sector (512 bytes)
::   LBA 1-64: stage2 (32KB)
::   LBA 65-114: logo.raw (25600 bytes = 50 sectors)
::   LBA 115-637: HZK16 (267616 bytes = 523 sectors)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$boot=[System.IO.File]::ReadAllBytes('%OUT%\boot.bin'); $stage2=[System.IO.File]::ReadAllBytes('%OUT%\stage2.bin'); $logo=[System.IO.File]::ReadAllBytes('%~dp0logo.raw'); $hzk=[System.IO.File]::ReadAllBytes('%~dp0HZK\HZK16'); $imgSize=16*63*200*512; $pad=New-Object byte[] ($imgSize-512-32768-25600-267616); $img=New-Object byte[] $imgSize; $boot.CopyTo($img,0); $stage2.CopyTo($img,512); $logo.CopyTo($img,512+32768); $hzk.CopyTo($img,512+32768+25600); $pad.CopyTo($img,512+32768+25600+267616); [System.IO.File]::WriteAllBytes('%OUT%\nova-os.img',$img)"

for %%F in ("%OUT%\boot.bin") do if not %%~zF==512 (
  echo Boot sector must be 512 bytes, got %%~zF bytes
  exit /b 1
)
echo Built %OUT%\nova-os.img