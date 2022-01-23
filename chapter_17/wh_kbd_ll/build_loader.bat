@echo off

if exist kbdloader.obj del kbdloader.obj
if exist kbdloader.exe del kbdloader.exe

\masm32\bin\ml /c /coff kbdloader.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF kbdloader.obj rsrc.obj
if errorlevel 1 goto errlink

dir kbdloader.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:WINDOWS /SECTION:.text,ERW /OPT:NOREF kbdloader.obj
if errorlevel 1 goto errlink
dir kbdloader.*
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
