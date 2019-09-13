; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.


Comment /*
	Given an n-order magic square (n is odd), all the remaining magic
   squares can be got from the first by peformming one or both of basic
	geometric transformations such as rotation or symetry about the central
	square, row or column.
            
   Here are some examples on a magic sqaure of order 3:
      
   	  [ 4  9  2 ]     rotate(cycling)     [ 2  7  6 ]   again    [ 6  1  8 ]
      [ 3  5  7 ]    ---------------->    [ 9  5  1 ] ------->   [ 7  5  3 ]
      [ 8  1  6 ] about central square    [ 4  3  8 ]            [ 2  9  4 ]


      [ 4  9  2 ]    symetry about      [ 8  1  6 ] 
      [ 3  5  7 ]    -------------->    [ 3  5  7 ] 
      [ 8  1  6 ]    central row        [ 4  9  2 ] 
         
      [ 4  9  2 ]    symetry about      [ 2  9  4 ] 
      [ 3  5  7 ]    -------------->    [ 7  5  3 ] 
      [ 8  1  6 ]    central column     [ 6  1  8 ] 
                
   Given a magic square of order n there are n^2 ways in which we could place a
	number in the square. So i imagine for a magic square of order n we can find
	up to n^2 of such squares. There are n^2-1 such squares for a magic square
	of order 3 using the transformations described above, this is be normal since 
	there is only one way of setting the central square which is always equal to
	the median of the distribution {1,n^2}, 5 in case. 
*/

include magicsquare.inc            


extern order:dword, NumSquares:dword
extern Msquare:byte

.code

; Columns/rows in the [0..n-1] range.
SymetryAbtRow  PROC
    ; A magic square remains 'magic' after any row/column interchange,
	 ; or rotation about the central cell.
    mov     eax,    order
    shr     eax,    1       ; get central row 
    mov     ecx,    eax
    invoke  RandRange,  0
    mov     edx,    ecx
    mov     ebx,    eax     ; ebx above central row
    sub     edx,    eax
    add     edx,    ecx     ; edx below central row
        
L1:
    mov     edi,    order
    mov     esi,    edi
    imul    edi,    ebx
    imul    esi,    edx 
    lea     esi,    Msquare[esi]
    lea     edi,    Msquare[edi]
    mov     ecx,    order
    
L1_2:    
    movzx   eax,    byte ptr [esi]
    xchg    al,     byte ptr [edi]    
    mov     byte ptr [esi], al
    add     edi,    1
    add     esi,    1
    sub     ecx,    1
    jnz     short L1_2
    
    add     edx,    1
    sub     ebx,    1
    cmp     edx,    order
    jb      short L1
    
    ret
SymetryAbtRow  ENDP

SymetryAbtCol  PROC

    mov     eax,    order
    shr     eax,    1       ; get central column
    mov     ecx,    eax
    invoke  RandRange,  0
    mov     ebx,    eax     ; ebx above central column
    mov     edx,    ecx
    sub     edx,    eax
    add     edx,    ecx     ; edx below central column
    
L1:
    xor     ecx,    ecx
        
L1_2:
    mov     edi,    order
    imul    edi,    ecx
    mov     esi,    edi
    add     edi,    edx     ; edx = col1
    add     esi,    ebx     ; ebx = col2
    movzx   eax,    Msquare[esi]
    xchg    al,     Msquare[edi]
    mov     Msquare[esi],   al
    add     ecx,    1
    cmp     ecx,    order
    jne     short L1_2
    
    add     edx,    1       ; col1 + 1
    sub     ebx,    1       ; col2 - 1
    cmp     edx,    order
    jb      short L1
    
    ret
SymetryAbtCol  ENDP


Rotation PROC
    local  range:dword, col:dword, row:dword, row1:dword, col1:dword
    local Msquare2[MAXSIZE]:byte
    
    ; Make a copy fo the current Msqaure
    cld
    mov     ecx,    NumSquares
    add     ecx,    3
    shr     ecx,    2
    mov     esi,    offset Msquare
    lea     edi,    Msquare2
    rep     movsd
    
    xor     eax,    eax
    mov     col,    eax
    mov     col1,   eax
    mov     row,    eax
    mov     ecx,    order
    sub     ecx,    1
    mov     range,  ecx  ; The range is the max columns number of  the ring
    mov     row1,   ecx
    mov     ecx,    NumSquares
    
L1:
    mov     edi,    order
    mov     esi,    edi
    imul    esi,    row
    imul    edi,    row1
    add     esi,    col
    add     edi,    col1
    movzx   edx,    Msquare2[esi]
    mov     Msquare[edi],   dl
    add     col,    1
    sub     row1,   1
    xor     edx,    edx
    mov     edi,    col
    mov     eax,    row1
    cmp     edi,    range
    seta    dl
    cmova   edi,    row1
    cmova   eax,    range
    add     edi,    edx
    mov     col,    edi
    mov     row1,   eax
    add     row,    edx
    mov     edx,    row
    mov     col1,   edx
    sub     ecx,    1
    jnz     short L1
    
    ret
Rotation ENDP

Shuffle PROC
    mov     eax,    5
    invoke  RandRange,  1
    mov     ecx,    eax    ; number of rotations to do
    
L1:
    push    ecx
    invoke  Rotation
    pop     ecx
    sub     ecx,    1
    jnz     short L1
    
    invoke  SymetryAbtRow
    
    invoke  Random32
    and     al,    01       ; if odd symetry about column
    jz      short L2
    invoke  SymetryAbtCol
    jmp     short L3

L2:                         ;    esle both
    invoke  SymetryAbtCol
    invoke  SymetryAbtRow

L3:
    ret
Shuffle ENDP


END
