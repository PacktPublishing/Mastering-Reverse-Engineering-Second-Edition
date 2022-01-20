; Base64 decode reference:
; https://github.com/monobeard/libasmb64/blob/master/src/libasmb64_32.s
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
    .code

start:

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      call main
      invoke ExitProcess,eax

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    mov ebx, esp
    
    push 0C357h
    push 006A5052h
    push 006AD48Bh
    push 6B636150h
    push 68746AC4h
    push 8B572069h
    push 4868646Ch
    push 726F6821h
    push 6A006A5Fh
    mov eax, esp
    call eax

    mov eax, MessageBoxA
    call eax

    mov esp, ebx

    ;invoke MessageBox, 0, offset decrypt+6, offset decrypt, MB_OK

    ret

main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start
