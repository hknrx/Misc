@echo off
rem Bomb Jack - Build.bat
rem Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
rem

set HAMDIR=E:\Coding\GBA
set PATH=%HAMDIR%\tools\win32;%PATH%
set MAKE_MODE=unix
make all
