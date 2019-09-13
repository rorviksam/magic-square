; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.

Include magicsquare.inc
    
extern cxClient:dword, cyClient:dword   ; Client area width and height
extern order:dword, NumSquares:dword    ; Properties of the magic square
extern Msquare:byte, Attributes:byte    ; Magic square and it's attributes   
extern hDC:HDC                          ; Handle to device context     

public  Trect, Mrect, Srect, Vgap, Hgap, PrvRect, NxtRect
public fill, empty, time 

.const
text        byte    "%i",0
timestr     byte    "%i:%i:%i",0

.data
boardfont   LOGFONT < 0, 0, 0, 0, FW_MEDIUM, FALSE, FALSE, FALSE, ANSI_CHARSET, \
                     OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, \
                     FIXED_PITCH  or FF_ROMAN, "Times New Roman" >
                        
timefont    LOGFONT < 0, -9, 0, 0, FW_THIN , FALSE, FALSE, FALSE, ANSI_CHARSET, \
                     OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, \
                     FIXED_PITCH  or FF_DECORATIVE, "DigifaceWide" >   
                        
fill        dword   BEG_FILL
empty       dword   BEG_EMPTY


.data?

align 16
Mrect       RECT    <>      ; Main rectangle
Trect       RECT    <>      ; TIme rectangle
Srect       RECT    <>      ; Small rectangle
PrvRect     RECT    <>      ; Previous rectangle
NxtRect     RECT    <>      ; Next rectangle

Vgap        dword   ?       ; Width of each Small rectangle
Hgap        dword   ?       ; Height of each Small rectangle
time        TIME    <>
Brhfill     HBRUSH  ?       ; Brush of a filled rectangle
Brhempty    HBRUSH  ?       ; Brush of an empty rectangle


GAP = 10
LNWIDTH = 3

.code
DrawMainRect   PROC
    local brush:LOGBRUSH, hpen:HPEN,  hold:HGDIOBJ
    
    xor     eax,    eax
    mov     brush.lbStyle,  PS_SOLID
    mov     brush.lbColor,  eax     ; black color
    mov     brush.lbHatch,  eax     ; No Hatched Brush
    
    $PS =   PS_GEOMETRIC or PS_SOLID or PS_ENDCAP_FLAT or PS_JOIN_BEVEL
    invoke  ExtCreatePen, $PS, LNWIDTH, addr brush, eax, eax  ; eax == 0
    mov     hpen,   eax
    invoke  SelectObject, hDC, eax
    mov     hold,   eax
    ; draw main rectangle
    invoke  Rectangle, hDC, Mrect.left, Mrect.top, Mrect.right, Mrect.bottom
    ; Release and delete GDI objects
    invoke  SelectObject, hDC, hold
    invoke  DeleteObject, hpen
    
    ret
DrawMainRect   ENDP

DrawBoard   PROC
    local srect:RECT
    
    movaps  xmm0,   oword ptr Srect
    movlps  qword ptr srect,    xmm0
    movhps  qword ptr srect+8,  xmm0
    invoke  CreateSolidBrush,   fill
    mov     Brhfill,    eax
    invoke  CreateSolidBrush, empty
    mov     Brhempty,   eax
    mov     esi,    offset Attributes
    mov     ecx,    order
    
L1:
    push    ecx
    mov     ebx,    order
    
L1_2:
    push    ebx
    mov     edx,    Brhfill
    movzx   eax,    byte ptr [esi]
    test    eax,    eax
    cmovz   edx,    Brhempty
    invoke  SelectObject, hDC, edx
    invoke  Rectangle, hDC, srect.left, srect.top, srect.right, srect.bottom
    mov     eax,    srect.right
    mov     edx,    Hgap
    mov     srect.left,     eax
    add     srect.right,    edx
    add     esi,    1
    pop     ebx
    sub     ebx,    1
    jnz     short L1_2
    
    mov     eax,    srect.bottom
    mov     edx,    Mrect.left
    mov     srect.top,      eax
    mov     srect.left,     edx
    
    add     eax,    Vgap
    add     edx,    Hgap
    mov     srect.bottom,   eax
    mov     srect.right,    edx

    pop     ecx
    sub     ecx,    1
    jnz     short L1
        
    ; now draw time rectangle
    invoke  SelectObject, hDC, Brhfill
    invoke  Rectangle, hDC, Trect.left, Trect.top, Trect.right, Trect.bottom
    ; Delete GDI objects
    invoke  DeleteObject, Brhfill
    invoke  DeleteObject, Brhempty
    ret
DrawBoard   ENDP

DisplayText   PROC 
    local srect:RECT, szbuffer[8]:byte, hfont:HFONT
    
    mov     eax,    Vgap
    sub     eax,    GAP+6
    mov     boardfont.lfHeight,     eax
    invoke  CreateFontIndirect, addr boardfont
    mov     hfont,  eax
    invoke  SelectObject, hDC, hfont
    movaps  xmm0,   oword ptr Srect
    movlps  qword ptr srect,    xmm0
    movhps  qword ptr srect+8,  xmm0
    xor     ecx,    ecx
    
L1:
    xor     ebx,    ebx
        
L1_2:
    push    ecx
    push    ebx
    mov     esi,    order
    imul    esi,    ecx
    add     esi,    ebx
    movzx   eax,    Msquare[esi]
    lea     edx,    szbuffer
    test    eax,    eax
    jz      short L1_3
    
    invoke  wsprintf, edx, addr text, eax
    lea     edx,    szbuffer
    lea     edi,    srect
    $DT =   DT_CENTER or DT_SINGLELINE or DT_VCENTER    ; DrawText style
    invoke  DrawText, hDC, edx, eax, edi, $DT
    
L1_3:
    mov     eax,    srect.right
    mov     edx,    Hgap
    mov     srect.left,     eax
    add     srect.right,    edx

    pop     ebx
    pop     ecx
    add     ebx,    1
    cmp     ebx,    order
    jb      short L1_2
    
    mov     eax,    srect.bottom
    mov     edx,    Srect.left
    mov     srect.top,  eax
    mov     srect.left, edx
    
    add     eax,    Vgap
    add     edx,    Hgap
    mov     srect.bottom,   eax
    mov     srect.right,    edx

    add     ecx,    1
    cmp     ecx,    order
    jb      L1
    invoke  DeleteObject, hfont

    ret
DisplayText   ENDP

DisplayTime PROC 
    local szbuffer[16]:byte, hfont:HFONT
    
    mov     eax,    Trect.bottom
    sub     eax,    Trect.top
    
    mov     timefont.lfHeight,  eax
    invoke  CreateFontIndirect, addr timefont
    mov     hfont,  eax
    invoke  SelectObject, hDC, hfont
    invoke  SetTextCharacterExtra, hDC, 1    ; add 1 to char spacing
    movzx   eax,    time.seconds
    movzx   ebx,    time.minutes
    movzx   ecx,    time.hours
    lea     edx,    szbuffer
    invoke  wsprintf, edx, addr timestr, ecx, ebx, eax
    lea     edx,    szbuffer
    $DT =   DT_CENTER or DT_SINGLELINE or DT_VCENTER
    invoke  DrawText, hDC, edx, eax, addr Trect, $DT

    invoke  SetTextCharacterExtra, hDC, 0    ; restore default char spacing
    invoke  DeleteObject, hfont

    ret
DisplayTime ENDP

CalcRectangles  PROC
    ; calc main rect
    xor     ecx,    ecx
    mov     eax,    cxClient
    mov     edx,    cyClient
    sub     eax,    2*GAP+3
    sub     edx,    5*GAP+3
    add     ecx,    2*GAP
    mov     Mrect.right,    eax
    mov     Mrect.bottom,   edx
    mov     Mrect.left,     ecx
    sub     ecx,    GAP
    mov     Mrect.top,      ecx
    
    ; ensure the distance b/w right and left is a multiple of the order
    xor     edx,    edx
    mov     eax,    Mrect.right
    sub     eax,    Mrect.left
    div     order
    mov     Hgap,   eax
    add     Mrect.left,     edx  ;  adjust
    
    ; ensure the distance b/w bottom and top is a multiple of the order
    xor     edx,    edx
    mov     eax,    Mrect.bottom
    sub     eax,    Mrect.top
    div     order
    mov     Vgap,   eax
    add     Mrect.top,      edx  ;  adjust

    ; calc coord of time rect
    mov     eax,    Mrect.right
    add     eax,    Mrect.left
    ; mov     eax,    cxClient
    shr     eax,    1
    mov     edx,    eax
    add     eax,    5*GAP+1
    sub     edx,    5*GAP
    mov     ecx,    Mrect.bottom
    mov     Trect.top,      ecx
    add     ecx,    3*GAP
    mov     Trect.left,     edx
    mov     Trect.right,    eax
    mov     Trect.bottom,   ecx
    
    ; Calc coord of small rect
    mov     eax,    Mrect.left
    mov     edx,    Mrect.top
    mov     Srect.left,     eax
    mov     Srect.top,      edx
    add     eax,    Hgap
    add     edx,    Vgap
    mov     Srect.right,    eax
    mov     Srect.bottom,   edx
    movaps  xmm0,   oword ptr Srect
    movntps  oword ptr PrvRect,  xmm0
    movntps  oword ptr NxtRect,  xmm0
    ret
CalcRectangles  ENDP


SetColors   PROC
    mov     edx,    EAS_FILL
    mov     ecx,    EAS_EMPTY
    mov     edi,    BEG_FILL
    mov     esi,    BEG_EMPTY
    cmp     eax,    IDM_EASY
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    INT_FILL
    mov     ecx,    INT_EMPTY
    cmp     eax,    IDM_INTERMEDIATE
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    HAR_FILL
    mov     ecx,    HAR_EMPTY
    cmp     eax,    IDM_HARD
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    EXP_FILL
    mov     ecx,    EXP_EMPTY
    cmp     eax,    IDM_EXPERT
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     fill,   edi
    mov     empty,  esi
    ret
SetColors   ENDP

END
