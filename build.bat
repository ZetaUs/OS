@echo off
setlocal
set "ROOT=%~dp0.."
set "NASM=%ROOT%\Program\NASM\nasm.exe"
set "DEVCPP_BIN="
if defined DEVCPP_HOME if exist "%DEVCPP_HOME%\MinGW64\bin\g++.exe" set "DEVCPP_BIN=%DEVCPP_HOME%\MinGW64\bin"
if not defined DEVCPP_BIN if exist "D:\Program\Dev-Cpp\MinGW64\bin\g++.exe" set "DEVCPP_BIN=D:\Program\Dev-Cpp\MinGW64\bin"
if not defined DEVCPP_BIN if exist "%ProgramFiles(x86)%\Dev-Cpp\MinGW64\bin\g++.exe" set "DEVCPP_BIN=%ProgramFiles(x86)%\Dev-Cpp\MinGW64\bin"
if not defined DEVCPP_BIN if exist "%ProgramFiles%\Dev-Cpp\MinGW64\bin\g++.exe" set "DEVCPP_BIN=%ProgramFiles%\Dev-Cpp\MinGW64\bin"
if not defined DEVCPP_BIN (
  for /f "delims=" %%P in ('where g++.exe 2^>nul') do if not defined DEVCPP_BIN set "DEVCPP_BIN=%%~dpP"
)
if not defined DEVCPP_BIN (
  echo Dev-C++ MinGW compiler not found. Set DEVCPP_HOME to the Dev-C++ folder.
  exit /b 1
)
set "GXX=%DEVCPP_BIN%\g++.exe"
set "LD=%DEVCPP_BIN%\ld.exe"
set "OBJCOPY=%DEVCPP_BIN%\objcopy.exe"
set "OUT=%~dp0build"
if not exist "%OUT%" mkdir "%OUT%"

echo [1/7] Assembling boot sector...
"%NASM%" -f bin "%~dp0boot.asm" -o "%OUT%\boot.bin"
if errorlevel 1 exit /b 1

echo [2/7] Assembling stage2...
"%NASM%" -f bin "%~dp0stage2.asm" -o "%OUT%\stage2.bin"
if errorlevel 1 exit /b 1

echo [3/7] Assembling login screen...
"%NASM%" -f win32 "%~dp0login.asm" -o "%OUT%\login.o"
if errorlevel 1 exit /b 1

echo [4/7] Assembling desktop screen...
"%NASM%" -f win32 "%~dp0desktop.asm" -o "%OUT%\desktop.o"
if errorlevel 1 exit /b 1

echo [5/7] Compiling the freestanding C++ kernel with Dev-C++...
"%GXX%" -m32 -std=c++11 -Os -fno-toplevel-reorder -ffreestanding -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit -fno-stack-protector -fno-pic -fno-pie -fno-builtin -c "%~dp0kernel.cpp" -o "%OUT%\kernel.o"
if errorlevel 1 exit /b 1

echo [6/7] Linking and flattening the kernel...
"%LD%" -mi386pe --image-base 0 --section-alignment 16 --file-alignment 16 --section-start .text=0x10000 -e _kernel_main -o "%OUT%\kernel.exe" "%OUT%\kernel.o" "%OUT%\login.o" "%OUT%\desktop.o"
if errorlevel 1 exit /b 1
"%OBJCOPY%" --only-section=.text --only-section=.rdata --only-section=.data -O binary "%OUT%\kernel.exe" "%OUT%\kernel.bin"
if errorlevel 1 exit /b 1

echo [7/7] Building disk images...

:: Layout:
::   LBA 0: boot sector (512 bytes)
::   LBA 1-8: stage2 (4KB reserved)
::   LBA 9-72: C++ kernel (32KB reserved)
::   LBA 73+: HZK12 font data
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$boot=[System.IO.File]::ReadAllBytes('%OUT%\boot.bin'); $stage2=[System.IO.File]::ReadAllBytes('%OUT%\stage2.bin'); $kernel=[System.IO.File]::ReadAllBytes('%OUT%\kernel.bin'); $hzk12=[System.IO.File]::ReadAllBytes('%~dp0HZK\HZK12'); $imgSize=16*63*200*512; $img=New-Object byte[] $imgSize; $boot.CopyTo($img,0); $stage2.CopyTo($img,512); $kernel.CopyTo($img,9*512); $hzk12.CopyTo($img,73*512); [System.IO.File]::WriteAllBytes('%OUT%\nova-os.img',$img)"
if errorlevel 1 exit /b 1

:: Also create a floppy image for testing
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$boot=[System.IO.File]::ReadAllBytes('%OUT%\boot.bin'); $stage2=[System.IO.File]::ReadAllBytes('%OUT%\stage2.bin'); $kernel=[System.IO.File]::ReadAllBytes('%OUT%\kernel.bin'); $imgSize=1474560; $img=New-Object byte[] $imgSize; $boot.CopyTo($img,0); $stage2.CopyTo($img,512); $kernel.CopyTo($img,9*512); [System.IO.File]::WriteAllBytes('%OUT%\nova-os-floppy.img',$img)"
if errorlevel 1 exit /b 1

for %%F in ("%OUT%\boot.bin") do if not %%~zF==512 (
  echo Boot sector must be 512 bytes, got %%~zF bytes
  exit /b 1
)
echo Built %OUT%\nova-os.img