@echo off

if exist polymorph.obj del polymorph.obj
if exist polymorph.exe del polymorph.exe

\masm32\bin\ml /c /coff polymorph.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF polymorph.obj rsrc.obj
if errorlevel 1 goto errlink

dir polymorph.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:WINDOWS /SECTION:.text,ERW /OPT:NOREF polymorph.obj
if errorlevel 1 goto errlink
dir polymorph.*
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
