@echo off
if exist kbddll.obj del kbddll.obj
if exist kbddll.dll del kbddll.dll
\masm32\bin\ml /c /coff kbddll.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL /DEF:kbddll.def kbddll.obj 
del kbddll.obj
del kbddll.exp
dir kbddll.*
pause
