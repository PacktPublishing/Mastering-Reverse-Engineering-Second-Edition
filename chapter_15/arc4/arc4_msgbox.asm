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
        mykey   db  8Ch, 9Ah, 9Ch, 8Dh, 9Ah, 8Bh
        enc_lbl db  024h, 056h, 088h, 0D1h, 055h, 000h
        enc_txt db  020h, 05Fh, 082h, 0C9h, 001h, 08Bh, 047h, 083h, 02Bh, 082h, 080h, 0F5h, 063h, 0E7h, 02Fh, 0EDh,
                    0B8h, 0A6h, 07Dh, 058h, 03Bh, 05Bh, 027h, 013h, 0EDh, 032h, 02Fh, 000h
                    

    .data?
        K   db  256 dup(?)
        S   db  256 dup(?)
        
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      call main
      invoke ExitProcess,eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    jmp force_exit

    push 5
    push offset enc_lbl
    call arc4_cipher
    
    push 27
    push offset enc_txt
    call arc4_cipher

force_exit:         
    invoke MessageBox, 0, offset enc_txt, offset enc_lbl, MB_OK
    
    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

arc4_cipher proc    lpMyText:DWORD, dwSize:DWORD

    LOCAL x:DWORD, y:DWORD, z:DWORD

    pushad
    xor eax, eax
    xor esi, esi
    xor edi, edi
    xor ebx, ebx
    mov edx, 6
    mov ecx, 100h    
init_S:
    mov byte ptr[offset S+eax], al
    mov bl, byte ptr[offset mykey+esi]
    mov byte ptr[offset K+eax], bl
    inc eax
    inc esi
    cmp esi, edx
    jnz cont
    xor esi, esi
cont:
    loop init_S

crypt_key:
    xor ebx, ebx
    xor edx, edx
    mov bl, byte ptr[offset S+ecx]
    mov dl, byte ptr[offset K+ecx]
    add ebx, edx
    mov eax, x
    add eax, ebx
    mov ecx, 100h
    xor edx, edx
    div ecx
    mov x, edx
    mov ecx, y
    mov bl, byte ptr[offset S+ecx]
    mov al, byte ptr[offset S+edx]
    mov byte ptr[offset S+edx], bl
    mov byte ptr[offset S+ecx], al
    inc ecx
    mov y, ecx
    cmp ecx, 100h
    jl  crypt_key

    mov y, 0
    mov x, 0
    mov esi, lpMyText
    mov edi, dwSize

crypt_stream:
    mov eax, y
    inc eax
    xor edx, edx
    mov ecx, 100h
    div ecx
    mov y, edx
    xor ebx, ebx
    mov bl, byte ptr[offset S+edx]
    mov eax, x
    add eax, ebx
    xor edx, edx
    div ecx
    mov x, edx
    mov ecx, y
    mov bl, byte ptr[offset S+ecx]
    mov al, byte ptr[offset S+edx]
    mov byte ptr[offset S+edx], bl
    mov byte ptr[offset S+ecx], al
    add eax, ebx
    mov ecx, 100h
    xor edx, edx
    div ecx
    mov al, byte ptr[offset S+edx]
    xor byte ptr[esi], al
    inc esi
    inc z
    cmp z, edi
    jnz crypt_stream

    mov x, 0
    mov y, 0
    mov z, 0    
    popad
    ret    

arc4_cipher endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
