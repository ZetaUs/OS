@echo off
setlocal
call "%~dp0build.bat"
if errorlevel 1 exit /b 1

:: Start QEMU with floppy boot (boot a = floppy)
"%~dp0..\Program\qemu\qemu-system-x86_64.exe" -fda "%~dp0build\nova-os-floppy.img" -m 32M -boot a -vga std