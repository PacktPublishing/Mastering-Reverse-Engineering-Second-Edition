@echo off

if exist code_stack.obj del code_stack.obj
if exist code_stack.exe del code_stack.exe

\masm32\bin\ml /c /coff code_stack.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF code_stack.obj rsrc.obj
if errorlevel 1 goto errlink

dir code_stack.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:console /OPT:NOREF code_stack.obj
if errorlevel 1 goto errlink
dir code_stack.*
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
