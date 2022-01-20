@echo off

if exist arc4_msgbox.obj del arc4_msgbox.obj
if exist arc4_msgbox.exe del arc4_msgbox.exe

\masm32\bin\ml /c /coff arc4_msgbox.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF arc4_msgbox.obj rsrc.obj
if errorlevel 1 goto errlink

dir arc4_msgbox.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:console /OPT:NOREF arc4_msgbox.obj
if errorlevel 1 goto errlink
dir arc4_msgbox.*
goto TheEnd

:errlink
echo _
echo Link error
goto TheEnd

:errasm
echo _
echo Assembly Error
goto TheEnd

:TheEnd

pause
