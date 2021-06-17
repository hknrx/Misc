@echo off
rem Bomb Jack - MusicJack\Build.bat
rem Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
rem

set HAMDIR=E:\Coding\GBA
set PATH=%HAMDIR%\tools\win32;%PATH%
set MAKE_MODE=unix
make -C .. ADPCM=enabled all

E:\Coding\PC\MinGW\bin\gcc -Wall -O2 Sources\Convert.c -s -o Generated\Convert.exe
Generated\Convert.exe ..\BombJack.gba Generated\MusicJack.h bombJackRom
E:\Coding\PC\MinGW\bin\gcc -Wall -O2 Sources\MusicJack.c -s -o Generated\MusicJack.exe
