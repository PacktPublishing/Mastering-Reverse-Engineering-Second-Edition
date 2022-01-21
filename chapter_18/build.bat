@echo off

if exist ram_scraper.obj del ram_scraper.obj
if exist ram_scraper.exe del ram_scraper.exe

\masm32\bin\ml /c /coff ram_scraper.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF ram_scraper.obj rsrc.obj
if errorlevel 1 goto errlink

dir ram_scraper.*
goto TheEnd

:nores
\masm32\bin\Link /SUBSYSTEM:console /OPT:NOREF ram_scraper.obj
if errorlevel 1 goto errlink
dir ram_scraper.*
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
