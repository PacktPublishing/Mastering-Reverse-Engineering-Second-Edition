
; ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
    include \masm32\include\masm32rt.inc
    include \masm32\include\advapi32.inc
; ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
      
;     libraries
;     ~~~~~~~~~
    includelib \masm32\lib\masm32.lib
    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib
    includelib \masm32\lib\advapi32.lib
    includelib \masm32\lib\msvcrt.lib

.data
    hKHook              HHOOK       0

.data?
    hInstance           dd  ?
    
    
.code

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

LibMain proc instance:DWORD,reason:DWORD,unused:DWORD 

    .if reason == DLL_PROCESS_ATTACH
        mrm hInstance, instance       ; copy local to global
        mov eax, TRUE                 ; return TRUE so DLL will start
        
    .elseif reason == DLL_PROCESS_DETACH
    .elseif reason == DLL_THREAD_ATTACH
    .elseif reason == DLL_THREAD_DETACH
    .endif

    ret

LibMain endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

HookProc    proc    nCode:DWORD, wParam:WPARAM, lParam:LPARAM

    .if (nCode >= HC_ACTION) && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)
        invoke MessageBox, 0, chr$("Hi World!"), chr$("Packt"), MB_OK
    .endif

next_hook:
    invoke CallNextHookEx, hKHook, nCode, wParam, lParam
    ret 

HookProc    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

KeyLogging  proc
    LOCAL msg:MSG
    ;invoke MessageBox, 0, offset szMsg, offset szCaption, MB_OK

    invoke SetWindowsHookEx, WH_KEYBOARD_LL, addr HookProc, hInstance, NULL
    mov hKHook, eax

@@:
    invoke GetMessage, addr msg, 0, 0, 0
    test eax, eax
    je exit_keylog

    invoke TranslateMessage, addr msg
    invoke DispatchMessage, addr msg
    jmp @b

exit_keylog:
    invoke UnhookWindowsHookEx, hKHook
    xor eax, eax
    ret

KeyLogging  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end LibMain