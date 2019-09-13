; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.


Comment \
     Given a magic square of order n, the sum of each row, column and diagonals
must be equal to n(n^2+1)/2 which is called the magic number. 
           
        \
          
          
Include magicsquare.inc          
          
extern  order:dword, NumSquares:dword
extern  Msquare:byte

public MagicNumber

.data?
MagicNumber dword  ?
flags       dword  ?

.code

CalcMagicNum    PROC
    mov     eax,    NumSquares  ; n^2
    add     eax,    1           ; n^2+1   
    shr     eax,    1           ; ( n^2+1 ) / 2
    imul    eax,    order       ; n * ( n^2 + 1 ) / 2
    mov     MagicNumber,    eax
    ret
CalcMagicNum    ENDP


CheckRows   PROC

    mov     ecx,    order
    xor     edi,    edi
    
L1: 
    xor     eax,    eax
    xor     ebx,    ebx
        
L1_2:
    movzx   edx,    Msquare[edi+ebx]
    add     eax,    edx
    add     ebx,    1
    cmp     ebx,    order
    jb      short L1_2
    
    add     edi,    order
    cmp     eax,    MagicNumber
    jne     L2
    sub     ecx,    1
    jnz     short L1
    
L2:
    setz    byte ptr flags    
    ret
CheckRows   ENDP

CheckColumns   PROC

    xor     ecx,    ecx            ; starting column
    
L1:
    xor     ebx,    ebx        ; starting row
    xor     eax,    eax        ; accumulator
        
L1_2:
    mov     edi,    order
    imul    edi,    ebx
    add     edi,    ecx
    movzx   edx,    Msquare[edi]
    add     eax,    edx
    add     ebx,    1
    cmp     ebx,    order
    jb      short L1_2
            
    xor     edx,    edx
    cmp     eax,    MagicNumber
    jne     L2
    add     ecx,    1
    cmp     ecx,    order
    jb      short L1
        
L2:
    sete    dl
    shl     edx,    1    
    or      flags,  edx    
    ret
CheckColumns   ENDP

CheckDiagonals  PROC

    ; check forward leading diagonal first
    xor     ecx,    ecx    ; starting row or column
    xor     eax,    eax    ; accumulator
    
L1:
    mov     edi,    order
    imul    edi,    ecx
    add     edi,    ecx
    movzx   edx,    Msquare[edi]
    add     eax,    edx
    add     ecx,    1
    cmp     ecx,    order
    jb      short L1
    
    xor     edx,    edx            
    cmp     eax,    MagicNumber
    sete    dl
    shl     edx,    2
    or      flags,  edx
    
    ; check backward leading diagonal
    mov     ecx,    order
    sub     ecx,    1            ; starting column
    xor     ebx,    ebx          ; starting row
    xor     eax,    eax
    
L2:
    mov     edi,    order
    imul    edi,    ebx
    add     edi,    ecx
    movzx   edx,    Msquare[edi]
    add     eax,    edx
    sub     ecx,    1       ; next column
    add     ebx,    1       ; next row
    cmp     ebx,    order
    jb      short L2

    xor     edx,    edx            
    cmp     eax,    MagicNumber
    sete    dl
    shl     edx,    3
    or      flags,  edx
    
    ret
CheckDiagonals  ENDP

CheckBoard  PROC
    invoke  CheckRows
    invoke  CheckColumns
    invoke  CheckDiagonals
    mov     eax,    flags
    ret
CheckBoard  ENDP


END
