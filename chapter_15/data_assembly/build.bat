@echo off

if exist str_stack.obj del str_stack.obj
if exist str_stack.exe del str_stack.exe

\masm32\bin\ml /c /coff str_stack.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF str_stack.obj rsrc.obj
if errorlevel 1 goto errlink

dir str_stack.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:console /OPT:NOREF str_stack.obj
if errorlevel 1 goto errlink
dir str_stack.*
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
