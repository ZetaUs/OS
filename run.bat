@echo off
setlocal
call "%~dp0build.bat"
if errorlevel 1 exit /b 1

:: Start QEMU with vmware VGA
start "" "%~dp0..\Program\qemu\qemu-system-x86_64.exe" -hda "%~dp0build\nova-os.img" -m 32M -boot c -vga vmware