; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.

Comment \* 
	A magic square of order n is an arrangement of the numbers 1 through n^2 in
   a square array in such a way that the sum of each row and column is
	n(n^2 + l)/2, and so is the sum of the two diagonals.

   Example: A magic square of order 3

      [ 4  9  2 ]  ; A distribution of numbers from 1 to 3^2
      [ 3  5  7 ]  ; The central cell contains the median of the distribtion
      [ 8  1  6 ]  ; e.g.(5). The magic number is 15 = 3(3^2+1)/2

   The rule for generating it is easily seen: 
   1.  Start with 1 just below the middle square, fill and add 1
   2.  then go down and to the right diagonally, fill and add 1
   3.  when running off the edge imagine an entire plane tiled with squares
   4.  — until reaching a filled square 
       then drop down two spaces from the most-recently-filled square and
		 continue. This method works whenever n is odd.

   [This algorithm is due to Manuel Moschopoulos, who lived in Constantinople
   about 1300. For numerous other interesting magic square constructions, many
	of which are good programming exercises, see W. W. Rouse Ball, Mathematical
	Recreations and Essays, revised by H. S. M. Coxeter (New York: Macmillan,
	1939), Chapter 7.]

   See DONALD E. KNUTH, Stanford University, Fundamental Algorithms, p. 177
*\

         
Include magicsquare.inc

Public Msquare, NumSquares, order, Attributes

.data
    order   dword 3       
    
.data?
    Attributes  byte  MAXSIZE dup(?)
    Msquare     byte  MAXSIZE dup(?)   ; limit the greatest Msquare to  11 by 11

    NumSquares  dword ?

.code

CalcNumSquares  PROC
    mov     eax,    order
    imul    eax,    eax
    mov     NumSquares, eax
    ret
CalcNumSquares  ENDP

CreateMagicSquare PROC

    local RealDim:dword
    ; get real dimensions
    mov     eax,    order
    mov     esi,    eax
    sub     eax,    1
    mov     RealDim,    eax
    xor     ebx,    ebx
    
    ; Now fill Magic Square
    shr     esi,    1           ; get center
    mov     edi,    esi
    add     edi,    1           ; edi =row number , esi =  column nuber
    mov     ecx,    1
    
Fill:
    ; rows and columns start from 0 to order-1
    cmp     edi,    RealDim
    cmova   edi,    ebx
    cmp     esi,    RealDim
    cmova   esi,    ebx
    mov     eax,    order
    mul     edi
    add     eax,    esi
    cmp     Msquare[eax],   bl      ; is it already filled ? ebx = 0
    setne   dl                      ; yes, edx had been cleared by the mul instruction
    sub     esi,    edx             ; column number = column number - (1 or 0)
    add     edi,    edx             ; row number = row number + (1 or 0) 
    test    esi,    esi
    cmovl   esi,    RealDim
    test    edx,    edx
    jnz     short Fill                    ; are we in the square ?
                                    ; .. yes
    mov     Msquare[eax],   cl      ; now fill
    add     edi,    1
    add     esi,    1
    add     ecx,    1
    cmp     ecx,    NumSquares
    jbe     short Fill
    
    ret
CreateMagicSquare ENDP

EmptySomeSquares PROC
    local nempty:dword          ; Number of squares to empty
    
    mov     eax,    order
    shr     eax,    1
    add     eax,    1
    mov     nempty, eax
    
    xor ecx, ecx
    
L1:
    mov ebx,    nempty
        
L1_2:
    mov     eax,    order
    mov     esi,    eax
    invoke  RandRange,  0
    imul    esi,    ecx
    add     esi,    eax
    mov     Msquare[esi],   0
    sub     ebx,    1
    jnz     short L1_2
        
    add     ecx,    1
    cmp     ecx,     order
    jb      short L1
        
    ret
EmptySomeSquares ENDP

BuildAttrib PROC
    mov     edi,    offset Attributes
    mov     esi,    offset Msquare
    xor     ecx,    ecx
    
L1:
    movzx   eax,    byte ptr [esi]
    test    eax,    eax
    setnz   byte ptr [edi]
    add     esi,    1
    add     edi,    1
    add     ecx,    1
    cmp     ecx,    NumSquares
    jb      short L1
        
    ret
BuildAttrib ENDP

END
