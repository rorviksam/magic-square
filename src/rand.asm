; Copyright (C) 2010 Nguemo Samobeu Rorvik 
; All rights reserved.

Include magicsquare.inc

.data
seed  dd 1

.code

align 8
;--------------------------------------------------------------
Random32  proc
;; By Kip R. Irvine
; Returns an unsigned pseudo-random 32-bit integer
; in EAX,in the range 0 - FFFFFFFFh.
; Last update: 7/11/01
;--------------------------------------------------------------
	  imul  eax,    seed,  343FDh
	  add   eax,    269EC3h
	  mov   seed,   eax    ; save the seed for the next call
	  ror   eax,    8        ; rotate out the lowest digit (10/22/00)
	  ret
Random32  endp

RandRange proc min:dword
;; By Kip R. Irvine
; Returns an unsigned pseudo-random 32-bit integer
; in EAX, between min and n-1. Input parameter:
; EAX = n.
; Last update: 7/11/01
;--------------------------------------------------------------
	 push   ebx
	 push   edx
	 mov    ebx,    eax ; maximum value
	 call   Random32    ; eax = random number
	 xor    edx,    edx
	 div    ebx         ; divide by max value
	 mov    eax,    edx ; return the remainder
     add    eax,    min 
	 pop    edx
	 pop    ebx
	 ret
RandRange endp
;--------------------------------------------------------
Randomize proc
;; By Kip R. Irvine
; Re-seeds the random number generator with the current time
; in seconds.
; Receives: nothing
; Returns: nothing
; Last update: 7/11/01
;--------------------------------------------------------
	  push      eax
	  INVOKE    GetTickCount
	  mov       seed,eax
	  pop       eax
	  ret
Randomize endp

END
