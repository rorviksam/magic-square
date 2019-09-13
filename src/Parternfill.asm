BrickPatternFill PROC 
    local   temp:dword, hpen:HPEN, hold:HGDIOBJ, client:RECT
    xor eax, eax
    mov client.left, eax
    mov client.top, eax
    mov eax, cxclient
    mov edx, cyclient
    mov client.right, eax
    mov client.bottom, edx
    invoke CreateSolidBrush, fill
    mov hold, eax
    invoke FillRect, hdc, addr client, eax
    
    invoke  CreatePen, PS_SOLID, 2, 0
    mov hpen, eax
    invoke SelectObject, hdc, hpen
    mov hold, eax
    mov esi, 0;Mrect.top
    align 16
    L1:
        mov edi, 0;Mrect.left
        align 16
        L2:    
            invoke MoveToEx, hdc, edi, esi, NULL
            mov eax, edi
            mov edx, esi
            add eax, 5*GAP
            add edx, 5*GAP
            mov temp, eax
            invoke LineTo, hdc, eax,  edx
            invoke MoveToEx, hdc, temp, esi, NULL
            mov eax, edi
            mov edx, esi
            add eax, 5*GAP/2
            add edx, 5*GAP/2
            invoke LineTo, hdc, eax, edx
            add edi, 5*GAP
            cmp edi, cxclient;Mrect.right
            jb L2
        add esi, 5*GAP
        cmp esi, cyclient;Mrect.bottom
        jb L1
    invoke SelectObject, hdc, hold
    invoke DeleteObject, hpen
    invoke DeleteObject, hold
    ret
BrickPatternFill ENDP
