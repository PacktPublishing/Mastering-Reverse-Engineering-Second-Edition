@echo off

if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
:over1

if exist persrc.obj del persrc.obj
if exist persrc.exe del persrc.exe

\masm32\bin\ml /c /coff persrc.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF persrc.obj rsrc.obj
if errorlevel 1 goto errlink

dir persrc.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF persrc.obj
if errorlevel 1 goto errlink
dir persrc.*
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
