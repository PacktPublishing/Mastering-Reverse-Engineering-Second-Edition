; Base64 decode reference:
; https://github.com/monobeard/libasmb64/blob/master/src/libasmb64_32.s
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      .486                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :no
      ne      ; case sensitive

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
        ;mylabel   db 'Packt',0
        ;mytext    db 'Hi World',0
        b64label  db 'UGFja3Q=',0
        b64txt    db 'SGkgV29ybGQ=',0
        b64table  db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        decrypt   dd ?
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      call main
      invoke ExitProcess,eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    ;invoke MessageBox, 0, offset mytext, offset mylabel, MB_OK

    push offset decrypt
    push offset b64label
    call b64decode

    push offset decrypt+6
    push offset b64txt
    call b64decode

    invoke MessageBox, 0, offset decrypt+6, offset decrypt, MB_OK

    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

b64decode proc
    push ebp
    mov  ebp, esp

    push ebx
    push esi
    push edi

    xor  eax, eax
    xor  ebx, ebx
    xor  ecx, ecx
    xor  edx, edx

    lea  ebx, [ebp+8]
    mov  ebx, [ebx]

    lea  esi, [ebp+0ch]
    mov  esi, [esi]

    _loop:
      mov  al, [ebx]
      test al, al
      jz    _exit
      mov  cl, 64
      mov  edi, offset b64table
      repnz scasb
      test cl, cl
      je   _increment
      not  cl
      add  cl, 64
      shl  edx, 6
      or   edx, ecx
      add  ah, 6
      cmp  ah, 8
      jb   _increment
      sub  ah, 8
      mov  cl, ah
      mov  eax, edx
      shr  eax, cl
      mov  ah, cl
      mov  [esi], al
      inc  esi

    _increment:
      inc  ebx
      jmp  _loop

    _exit:
      lea  ecx, [ebp+0ch]
      mov  ecx, [ecx]
      mov  eax, esi
      sub  eax, ecx

      pop  edi
      pop  esi
      pop  ebx

      mov  esp, ebp
      pop  ebp
      
      ret

b64decode endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
