@echo off

REM NRX 99
REM 09/10/99

tasm /m /mx NRX_OTH.ASM, NRX_OTH.OBJ
tlink /x NRX_OTH.OBJ, NRX_OTH.EXE