@echo off
if exist wh_kbd_ll.obj del wh_kbd_ll.obj
if exist wh_kbd_ll.dll del wh_kbd_ll.dll
\masm32\bin\ml /c /coff wh_kbd_ll.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL /DEF:wh_kbd_ll.def wh_kbd_ll.obj 
del wh_kbd_ll.obj
del wh_kbd_ll.exp
dir wh_kbd_ll.*
pause
