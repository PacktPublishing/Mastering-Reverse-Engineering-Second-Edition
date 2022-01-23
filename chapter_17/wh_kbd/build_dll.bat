@echo off
if exist wh_kbd.obj del wh_kbd.obj
if exist wh_kbd.dll del wh_kbd.dll
\masm32\bin\ml /c /coff wh_kbd.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL /DEF:wh_kbd.def wh_kbd.obj 
del wh_kbd.obj
del wh_kbd.exp
dir wh_kbd.*
pause
