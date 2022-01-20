@echo off

if exist b64.obj del b64.obj
if exist b64.exe del b64.exe

\masm32\bin\ml /c /coff b64.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF b64.obj rsrc.obj
if errorlevel 1 goto errlink

dir b64.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:console /OPT:NOREF b64.obj
if errorlevel 1 goto errlink
dir b64.*
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
