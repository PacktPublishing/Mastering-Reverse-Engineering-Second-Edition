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

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\msvcrt.lib
      
    .data
        rsrc_name   db  'ISDATA', 0
        mylabel     db  'Packt', 0
        mytext      db  'Hi World!', 0

    .data?
        ResourceFound   STRUCT  8
            VirtualAddress  dd  ?
            rsrcSize        dd  ?
        ResourceFound   ENDS

        tRsrcItem   ResourceFound   <0,0>
        rsrc_found  db  ?
        ImageBase   dd  ?
        rva_rsrc    dd  ?
        unk_rsrc    db  50 dup(?)
    
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      call main
      invoke ExitProcess,eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    call rsrc_enc_data

    call simple_xor_decrypt
    
    invoke MessageBox, 0, offset mytext, offset mylabel, MB_OK
    
    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

simple_xor_decrypt proc

    mov eax, tRsrcItem.VirtualAddress
    mov ecx, tRsrcItem.rsrcSize

xor_more:
    xor BYTE ptr[eax], 0DFh
    inc eax
    loop xor_more

exit_xor:
    ret

simple_xor_decrypt endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

rsrc_enc_data   proc
        
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
    xor ecx, ecx
    mov cx, word ptr [eax+6]    ;NumberOfSections
    xor edx, edx
    mov dx, word ptr [eax+14h]  ;SizeOfOptionalHeader
    add dx, 18h                 ;18h - sizeof(FILE_HEADER)
    xor ebx, ebx

is_it_rsrc:
    cmp DWORD ptr[eax+edx], 'rsr.'
    jne not_rscrc
    cmp byte ptr [eax+edx+4], 'c'
    jne not_rscrc
    mov ebx, [eax+edx+0Ch]      ;RVA of section
    jmp f_rscr_sec

not_rscrc:
    add eax, 28h                ;28h - sizeof(IMAGE_SECTION_HEADER)
    dec ecx
    cmp ecx, 0
    jne is_it_rsrc

f_rscr_sec:
    cmp ebx, 0
    je exit_rsrc
    ;-----------------------------
    ; Found the resource section
    ;-----------------------------
    mov edx, [ImageBase]
    mov [rva_rsrc], edx
    add [rva_rsrc], ebx
    
    ;------------------------
    ;search Resource By Name
    ;------------------------
    push offset rsrc_name
    call find_rsrc_by_name
    
    
    
exit_rsrc:                
    ret

rsrc_enc_data   endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

find_rsrc_by_name  proc    rsrcName:DWORD

    LOCAL   ctr:DWORD

    xor ecx, ecx
    xor edi, edi
    mov edi, [rva_rsrc]
    ;mov cx, [edi].IMAGE_RESOURCE_DIRECTORY.NumberOfIdEntries
    mov cx, [edi].IMAGE_RESOURCE_DIRECTORY.NumberOfNamedEntries
    mov edx, 10h

iter_name:
    mov esi, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.Name1         ;10h - sizeof(IMAGE_RESOURCE_DIRECTORY)
    and esi, MASK rName.NameIsString                                ;is string if highest bit enabled
    .if esi == MASK rName.NameIsString
        mov esi, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.Name1     ;10h - sizeof(IMAGE_RESOURCE_DIRECTORY)
        and esi, NOT MASK rName.NameIsString
        add esi, [rva_rsrc]
        push edx
        push ecx
        push esi
        call get_wstr_to_str
        ;-----------------------
        ;Return Value is stored
        ;in unkn_rsrc var
        ;EAX - length of string    
        ;-----------------------
        push offset unk_rsrc
        push offset rsrc_name
        call compare_string
        cmp eax, 1
        pop ecx
        pop edx
        jz found_it
        add edx, 8
        dec ecx
        cmp ecx, 0
        jz exit_find_name
        jmp iter_name 
        
    .endif 

found_it:
    ;push [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
    ;call get_dir_entry

    mov esi, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
    and esi, MASK rDirectory.DataIsDirectory
    .if esi == MASK rDirectory.DataIsDirectory
        mov esi, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
        and esi, NOT MASK rDirectory.DataIsDirectory
        push esi
        call get_dir_entry
    .endif
    

exit_find_name:
    ret
    
find_rsrc_by_name endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

get_wstr_to_str  proc    rvaString:DWORD
    LOCAL   strCount:DWORD
    
    push edi
    push ecx
    xor ecx, ecx
    xor edx, edx
    mov eax, offset unk_rsrc
    mov ecx, 50                 ;50 - sizeof (unk_rsrc)
init_var:
    mov BYTE ptr[eax], dl
    loop init_var

    mov edx, [rvaString]
    mov cx, WORD ptr[edx]
    mov strCount, ecx
    
    .while cx != 0
        mov bl, BYTE ptr[edx+2]
        mov BYTE ptr[eax], bl
        inc edx
        inc edx
        inc eax
        dec ecx
    .endw
    xor ebx, ebx
    mov BYTE ptr[eax], bl
    mov eax, strCount

    pop ecx
    pop edi
    ret

get_wstr_to_str  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

compare_string  proc    str1:DWORD, str2:DWORD
    LOCAL cnt1:DWORD

    push edi
    xor eax, eax
    xor ecx, ecx
    mov esi, [str1]
cnt_str1:
    lodsb
    inc ecx
    cmp al, 0
    jnz cnt_str1
    dec ecx
    mov cnt1, ecx
    xor ecx, ecx
    mov esi, [str2]
cnt_str2:
    lodsb
    inc ecx
    cmp al, 0
    jnz cnt_str2
    dec ecx

    cmp ecx, cnt1
    jnz not_match

    mov edi, [str1]
    mov esi, [str2]
    cld
    repe cmpsb
    cmp ecx, 0
    jnz not_match

match_found:
    mov eax, 1
    jmp exit_cmp
not_match:
    mov eax, -1

exit_cmp:
    pop edi
    ret   

compare_string  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

get_dir_entry   proc    rvaDir:DWORD

    push edi
    push edx
    push esi
    push ebx
    cmp rsrc_found, 1
    je exit_dir
    xor ecx, ecx
    xor edi, edi
    xor edx, edx
    mov edi, [rva_rsrc]
    add edi, [rvaDir]
    mov cx, [edi].IMAGE_RESOURCE_DIRECTORY.NumberOfIdEntries
    mov edx, 10h

iter_dir:
    mov esi, DWORD ptr[edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.Id
    mov ebx, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
    and ebx, MASK rDirectory.DataIsDirectory
    .if ebx == MASK rDirectory.DataIsDirectory
        mov ebx, [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
        and ebx, NOT MASK rDirectory.DataIsDirectory
        push ebx
        call get_dir_entry        
    .else
        push [edi+edx].IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
        call get_data_entry   
    .endif

exit_dir:
    pop ebx
    pop esi
    pop edx
    pop edi
    ret

get_dir_entry   endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

get_data_entry  proc    rvaData:DWORD
    
    push edi
    push ebx
    push edx
    xor eax, eax
    
    mov edi, [rva_rsrc]
    add edi, [rvaData]

    mov ebx, [edi]
    add ebx, [ImageBase]

    mov tRsrcItem.VirtualAddress, ebx
    mov ebx, [edi+4]
    mov tRsrcItem.rsrcSize, ebx
    mov rsrc_found, 1   


exit_data:
    pop edx
    push ebx
    pop edi
    ret

get_data_entry  endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
