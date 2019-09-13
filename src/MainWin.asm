; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.


Include magicsquare.inc


Public cxClient, cyClient, hDC


AboutDlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
EditDlgProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD
BestDlgProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD

extern Trect:RECT, Mrect:RECT
extern Vgap:dword, Hgap:dword,  PrvRect:RECT, NxtRect:RECT
extern Attributes:byte, Msquare:byte, NumSquares:dword, time:TIME
extern MagicNumber:dword, order:dword

.data

$wc     WNDCLASS < CS_OWNDC, WinProc, 0, 0, 0, 0, 0, 0, szAppName, szAppName >
iSelection         dword       IDM_BEGINNER
valuetype          dword        REG_BINARY
KeyDisposition     dword        REG_CREATED_NEW_KEY 
maxtime            dword        00636363h
Snooze             byte 1       ; Every time the game start's waits for user input
State              byte 1       ; initial timing status

szAbout            byte     "ABOUTBOX",0
szEdit             byte     "WINBOX",0
szBest             byte     "BESTTIMES",0
szAppName          byte     "MagicSquare",0
szKeyFolder        byte     "Software\MagicSquare",0
szAttrib           byte     "Attributes",0,0
szTime             byte     "Time",0
szOrder            byte     "order",0
szStatus           byte     "GameStatus",0
szWarning          byte     "Delete settings stored in the registry?",0
szWinerName        byte     "Anonymous", 0
szBeginner         byte     "Beginner",0
szEasy             byte     "Easy",0
szIntermediate     byte     "Intermediate",0
szHard             byte     "Hard",0
szExpert           byte     "Expert",0
szBeginnertime     byte     "BeginnerTime",0
szEasytime         byte     "EasyTime",0
szIntemediatetime  byte     "IntemediateTime",0
szHardtime         byte     "HardTime",0
szExperttime       byte     "ExpertTime",0
szEmpty            byte     " ",0
szHelpMsg          byte     "Fill the magic square with numbers ranging from 1"
                   byte     " to %i, The Magic number is %i.",0
szWinMsg           byte     "Congratulations!, Magic square completed. Next time, "
                   byte     "try to be faster to have a record.",0
                   
.data?
align 16
ErrRect            RECT     <>     ; Error rectangle
$msg               MSG      <>
hWin               dword    ?      ; Main window handle
hMenu              HMENU    ?      ; Menu handle
hInst              DWORD    ?      ; Program instance handle
hStatus            DWORD    ?      ; Status bar handle
cxClient           dword    ?      ; Client area width
cyClient           dword    ?      ; Client area Height
hDC                HDC      ?      ; Handle to Device Context  
curpos             dword    ?      ; Current position
errpos             dword    ?      ; Error position
reppos             dword    ?      ; Replace position
curchar            dword    ?      ; Current character input
MKey               HKEY     ?      ; Registry key
input              dword    ?      ; Last character input
Started            dword    ?      ; Game started
OnInput            byte     ?      ; Are we currently entering a number?
szMsg              byte 128 dup (?)
szFormat           byte 80  dup (?)

.code

WinMain PROC 
    ; Do 4 byte stack alignement
    and     esp,    -4
    ; End Stack alignement
    ; Ensure Xp style theme
    call    InitCommonControls
    ; Get instance of application
    invoke  GetModuleHandle,    0
    mov     $wc.hInstance,  eax
    mov     hInst,          eax
    
    invoke  LoadIcon, eax, ICO_ID
    mov     $wc.hIcon,      eax
    ; Initialise Random seed
    invoke  Randomize
    
    invoke  LoadCursor, 0, IDC_ARROW
    mov     $wc.hCursor,    eax
    ; Set background color to white
    invoke  GetStockObject, WHITE_BRUSH
    mov     $wc.hbrBackground,  eax
    ; Register the Class
    invoke  RegisterClass, addr $wc
    ; Assume it was done !
    invoke GetSystemMetrics, SM_CXSCREEN 
    shr     eax,    1
    sub     eax,    250
    mov     edi,    eax
    invoke GetSystemMetrics, SM_CYSCREEN 
    shr     eax,    1
    sub     eax,    250
    mov     esi,    eax
    ; Now create the window
    $WS =   WS_MINIMIZEBOX or WS_OVERLAPPED or WS_CAPTION OR WS_SYSMENU
    invoke CreateWindowEx, 0, addr szAppName, addr szAppName,
                           $WS , edi, esi, 506, 510, 0, 0, hInst, 0
    mov     hWin,   eax
    ; Assume Window was created
    invoke  ShowWindow, hWin, SW_SHOW
    invoke  UpdateWindow, hWin
    
align 16    
MsgLoop:
    invoke  GetMessage, addr $msg, 0, 0, 0
    test    eax,    eax
    jz      @F
    
    invoke  TranslateMessage,   addr $msg
    invoke  DispatchMessage,    addr $msg
    jmp MsgLoop
    
@@:
    mov     eax,    $msg.wParam
    invoke  ExitProcess,    eax
WinMain ENDP

WinProc  PROC, hWnd:DWORD, UMsg:DWORD, wParam:DWORD, lParam:DWORD
    
    local  ps:PAINTSTRUCT, temp1:dword, temprect:RECT, temp:dword
    mov     eax,    UMsg
    
; BEGIN WM_CREATE    
    .if eax ==  WM_CREATE
        ; Store the device context
        invoke  GetDC,  hWnd
        mov     hDC,    eax
        ; Establish main menu
        invoke  GetMenu,    hWnd
        mov     hMenu,      eax
        ; Create status bar
        $ST = WS_CHILD or WS_VISIBLE or SBS_SIZEGRIP    ; Status bar style
        invoke  CreateStatusWindow, $ST, 0, hWnd, 200
        mov     hStatus,    eax        
        ; Open registry
        invoke  RegOpenKeyEx, HKEY_CURRENT_USER, addr szKeyFolder,
                              0, KEY_ALL_ACCESS, addr MKey
        .if eax ==  ERROR_SUCCESS
            ; Recover Saved settings
            invoke  RegQueryValueEx, MKey, addr szAppName, 0,
                                     addr valuetype, addr Msquare, addr temp
            invoke  RegQueryValueEx, MKey, addr szAppName, 0,
                                     addr valuetype, addr Msquare, addr temp
            invoke  RegQueryValueEx, MKey, addr szAttrib, 0,
                                     addr valuetype, addr Attributes, addr temp
            mov     valuetype,  REG_DWORD
            invoke  RegQueryValueEx, MKey, addr szStatus, 0,
                                     addr valuetype, addr Started, addr temp
            invoke  RegQueryValueEx, MKey, addr szTime, 0,
                                     addr valuetype,addr time,addr temp
            invoke  RegQueryValueEx, MKey, addr szOrder, 0,
                                     addr valuetype, addr order, addr temp
            
            invoke  CalcNumSquares
            invoke  CalcMagicNum
            mov     eax,    order
            call    SetColors
            invoke  CheckMenuItem, hMenu, iSelection, MF_UNCHECKED
            mov     eax,    order
            mov     iSelection, eax
            invoke CheckMenuItem, hMenu, iSelection, MF_CHECKED

        .else
            ; It is the first time this progam is executed on this computer?
            ;... Create registry entries
            invoke  RegCreateKeyEx, HKEY_CURRENT_USER, addr szKeyFolder, 0, 0, 0,
                                   KEY_ALL_ACCESS, 0, addr MKey, addr KeyDisposition
            invoke  RegSetValueEx, MKey, addr szBeginner, 0, REG_SZ,
                                  addr szWinerName, sizeof szWinerName
            invoke  RegSetValueEx, MKey, addr szBeginnertime, 0, REG_DWORD,
                                   addr maxtime, 4
            invoke  RegSetValueEx, MKey, addr szEasy, 0, REG_SZ,
                                   addr szWinerName,sizeof szWinerName
            invoke  RegSetValueEx, MKey, addr szEasytime, 0, REG_DWORD,
                                   addr maxtime, 4
            invoke  RegSetValueEx, MKey, addr szIntermediate, 0, REG_SZ,
                                   addr szWinerName, sizeof szWinerName
            invoke  RegSetValueEx, MKey, addr szIntemediatetime, 0, REG_DWORD,
                                   addr maxtime, 4
            invoke  RegSetValueEx, MKey, addr szHard, 0, REG_SZ,
                                   addr szWinerName, sizeof szWinerName
            invoke  RegSetValueEx, MKey, addr szHardtime, 0, REG_DWORD,
                                   addr maxtime, 4
            invoke  RegSetValueEx, MKey, addr szExpert, 0, REG_SZ,
                                   addr szWinerName,sizeof szWinerName
            invoke  RegSetValueEx, MKey, addr szExperttime, 0, REG_DWORD,   
                                   addr maxtime, 4
            
            invoke  CalcNumSquares
            call    Setup
            invoke  BuildAttrib
        .endif
        
        .if Started == 1
            invoke  SetTimer, hWnd, TIME_ID, 1000, 0  
        .endif   
        
        xor     eax,    eax
        ret
; END WM_CREATE
        
; BEGIN WM_DESTROY        
     ; Window is being destroyed, clean up
    .elseif eax == WM_DESTROY
        ; Kill the timer that we created
        invoke  KillTimer, hWnd, TIME_ID
        invoke  ReleaseDC, hWnd, hDC
        
        .if wParam == 0
            ; Save Settings
            invoke  RegSetValueEx, MKey, addr szAppName, 0,
                                   REG_BINARY, addr Msquare, NumSquares
            invoke  RegSetValueEx, MKey, addr szAttrib, 0,
                                   REG_BINARY, addr Attributes, NumSquares
            invoke  RegSetValueEx, MKey, addr szStatus, 0,
                                   REG_DWORD, addr Started, 4
            invoke  RegSetValueEx, MKey, addr szTime, 0,
                                   REG_DWORD, addr time, 4
            invoke  RegSetValueEx, MKey, addr szOrder, 0,
                                   REG_DWORD, addr order, 4
        .endif
        
        invoke  RegCloseKey, MKey
        ; Tell the application to terminate after the window is gone.
        invoke  PostQuitMessage, 0
        xor     eax,    eax
        ret
; END WM_DESTROY
        
; BEGIN WM_COMMAND
    .elseif eax == WM_COMMAND
         movzx  eax,    word ptr wParam
         
        .if eax == IDM_NEW  ; New Game
            call    CalcNumSquares
            call    EmptyAllSquares
            call    Setup
            call    EmptySomeSquares
            invoke  BuildAttrib
            ; invoke  CalcRectangles
            
            .if Started == 0    ; The game has not yet started
                sete    byte ptr Started
                invoke  SetTimer, hWnd, TIME_ID, 1000, 0
            .endif
            
            mov     dword ptr time, 0   ; Reset timer
            mov     Snooze,     1       ; D'ont start timing wait for input
            ; invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 80
            invoke  wsprintf, addr szMsg, addr szHelpMsg, NumSquares, MagicNumber
            invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szMsg
            invoke  InvalidateRect, hWnd, 0, TRUE
            
        .elseif eax == IDM_APP_EXIT
            invoke  SendMessage, hWnd, WM_CLOSE, 0, 0
            
        .elseif eax == IDM_RESET
            movzx   eax,    Snooze
            push    eax
            sete    Snooze ; Pause
            $MB  =  MB_ICONQUESTION or MB_YESNO
            invoke  MessageBox, hWnd, addr szWarning, addr szAppName, $MB
            
            .if eax == IDYES 
                invoke  RegDeleteKey, HKEY_CURRENT_USER, addr szKeyFolder
                invoke  SendMessage, hWnd, WM_CLOSE, 1, 0
            .endif
            
            pop     eax
            mov     Snooze, al   ; Continue
            
        .elseif eax == IDM_BEST_TIMES   ; Show Best time dialog
            movzx   eax,    Snooze
            push    eax
            sete    Snooze              ; Stop timer
            invoke  DialogBoxParam, hInst, addr szBest, hWnd, BestDlgProc, 0
            pop     eax
            mov     Snooze, al          ; Restart timer
                
        .elseif eax == IDM_APP_ABOUT
            movzx   eax,    Snooze
            sete    Snooze              ; Stop timer
            push    eax
            invoke  DialogBoxParam, hInst, addr szAbout, hWnd, AboutDlgProc, 0
            pop     eax
            mov     Snooze, al          ; Restart timer

        .elseif eax <= IDM_EXPERT && eax >= IDM_BEGINNER
            mov     order,  eax
            call    SetColors
            invoke  CheckMenuItem, hMenu, iSelection, MF_UNCHECKED
            mov     eax,    order
            mov     iSelection, eax
            invoke  CheckMenuItem, hMenu, iSelection, MF_CHECKED
            call    CalcNumSquares
            call    EmptyAllSquares
            call    Setup
            
            .if Started == 1
                call    EmptySomeSquares
                ; invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 80
                invoke  wsprintf, addr szMsg, addr szHelpMsg, NumSquares, MagicNumber
                invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szMsg
            .else
                invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szEmpty
            .endif
            
            mov     dword ptr time, 0   ; Reset timer
            mov     Snooze,     1       ; D'ont start wait for input
            call    BuildAttrib
            invoke  CalcRectangles
            invoke  InvalidateRect, hWnd, 0, TRUE
            
        .endif
        
        xor     eax,    eax
        ret
; END WM_COMMAND

; BEGIN WM_SIZE
    .elseif eax == WM_SIZE
        movzx   eax,    word ptr lParam
        movzx   edx,    word ptr lParam+2
        mov     cxClient,   eax
        mov     cyClient,   edx
        invoke  CalcRectangles
        
        .if  wParam == SIZE_RESTORED       
             mov    al,     State
             mov    Snooze, al              ; Restore timer state
        .elseif wParam == SIZE_MINIMIZED    ; Is the window minimized
             movzx  eax,    Snooze     
             mov    State,  al              ; Save timer state
             sete   Snooze                  ; Pause
        .endif
         
        .if Started == 1
            ; invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 80
            invoke  wsprintf, addr szMsg, addr szHelpMsg, NumSquares, MagicNumber
            invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szMsg
        .endif
        
        xor     eax,    eax
        ret
; END WM_SIZE

; BEGIN WM_MOUSEMOVE
    .elseif eax ==  WM_MOUSEMOVE
        movzx   edi,    word ptr lParam      ; x
        movzx   esi,    word ptr lParam+2    ; y
        invoke  PtInRect, addr Mrect, edi, esi
        test    eax,    eax
        jz      OutOfRect       ; Out of main rect
        
        invoke  PtInRect, addr NxtRect, edi, esi
        test    eax,    eax   
        jnz     OutOfRect       ; We are still in the current rect
        ; We are in another rectangle
        movaps  xmm0,   oword ptr NxtRect
        movaps  oword ptr PrvRect,  xmm0
        invoke  InvertRect, hDC, addr PrvRect
        xor     edx,    edx
        mov     eax,    edi     ;x
        sub     eax,    Mrect.left
        div     Hgap
        imul    eax,    Hgap
        add     eax,    Mrect.left
        mov     NxtRect.left,   eax
        add     eax,    Hgap
        mov     NxtRect.right,  eax
        xor     edx,    edx
        mov     eax,    esi    ;y
        sub     eax,    Mrect.top
        div     Vgap
        imul    eax,    Vgap
        add     eax,    Mrect.top
        mov     NxtRect.top,    eax
        add     eax,    Vgap
        mov     NxtRect.bottom, eax
        invoke  InvertRect, hDC, addr NxtRect
     
    OutOfRect:
        xor     eax,    eax
        ret
; END WM_MOUSEMOVE

; BEGIN WM_KEYDOWN
    .elseif eax == WM_KEYDOWN
        mov     eax,    wParam
        
        .if eax == VK_UP
            invoke  MoveUp
            
        .elseif eax == VK_DOWN
            invoke  MoveDown
            
        .elseif eax == VK_RIGHT
            invoke  MoveRight
            
        .elseif eax == VK_LEFT
            invoke  MoveLeft
            
        .elseif eax == VK_F2
            invoke  SendMessage, hWnd, WM_COMMAND, IDM_NEW, 0
            
        .endif
        
        xor     eax,    eax
        ret
; END WM_KEYDOWN       

; BEGIN WM_CHAR
    .elseif eax == WM_CHAR
        invoke  CurRectToPos
        mov     curpos, eax
        mov     eax,    wParam
        
        .if eax >= VK_0 && eax <= VK_9 
            sub     eax,    30h
            mov     edx,    curchar
            shl     edx,    8
            or      edx,    eax
            mov     curchar,    edx
            
            .if OnInput == 0
                sete    OnInput     ; Indicate the user is typing, give him
                invoke  SetTimer, hWnd, KEYB_ID, 600, 0  ;. 0.6sec for that.
            .endif

        .endif
        
        xor eax, eax
        ret
; END WM_CHAR

; BEGIN WM_TIMER
    .elseif eax == WM_TIMER
         mov    eax,    wParam
         
        .if eax == TIME_ID
        
                .if Snooze == 0
                    call    UpdateTime
                    invoke  InvalidateRect, hWnd, addr Trect, FALSE
                .endif
                
        .elseif eax == KEYB_ID
            invoke  KillTimer, hWnd, KEYB_ID
            ; Has the game Started?
            cmp     Started,    0
            je      stop            ; No!
            ; Now convert current char to a number
            mov     ebx,    curpos
            cmp     Attributes[ebx],    1   ; Trying to overide an invalid square
            je      stop                    ; Don't overide this square
            
            mov     Snooze, 0               ; make sure we are timing
            movzx   eax,    byte ptr curchar+2   ; H     (Hundred)
            movzx   ecx,    byte ptr curchar+1   ; T     (Tens)
            movzx   edi,    byte ptr curchar     ; U     (Unit)
            imul    eax,    100   
            imul    ecx,    10
            add     eax,    ecx
            add     eax,    edi
            mov     input,  eax
            cmp     eax,    NumSquares      
            ja      stop                   ; Not in the distribution
            
            test    eax,    eax
            jz      overide     ; you have entered zero, clear the current square
            ; 1 <= eax <= order^2
            ; Is it already in the magic square?   
            mov     ecx,    NumSquares
            mov     edi,    offset Msquare
            mov     esi,    edi
            cld
            repne   scasb
            jnz     overide ; No!
            
            ; Yes, get it's position.
            sub     edi,    esi   
            sub     edi,    1
            mov     errpos, edi     ; Save it
            mov     reppos, ebx     ; Save the position of the input number
            cmp     edi,    ebx
            je      stop        ; You have entered the same number in the square 
            
            ; Report error : The number is already in the Magic square
            invoke  PostMessage, hWnd, WM_USER, NUNBER_IN_SQUARE_ERROR , 0
            jmp     stop
            
        overide:
            mov     Msquare[ebx],   al    ; overide the current square( set it )
            mov     eax,    ebx
            lea     edi,    temprect
            invoke  PosToCurRect
            invoke  InvalidateRect, hWnd, edi, FALSE
            invoke  CheckBoard
            cmp     eax,    MAGIC_SQUARE_COMPLETE
            jne stop
            
            invoke  SendMessage, hWnd, WM_USER, MAGIC_SQUARE_COMPLETE, 0
            
        stop:
            mov     OnInput,    0
            mov     curchar,    0
            
        .elseif eax == ERR_ID
            invoke  KillTimer, hWnd, ERR_ID
            mov     edi,    errpos
            xor     edx,    edx
            cmp     Attributes[edi], 1
            setne   dl
            cmovne  ebx,    reppos
            sub     edx,    1
            and     Msquare[edi],   dl
            jnz     @F
         
            mov     eax,    input
            mov     Msquare[ebx],   al    ; clear the previous
            invoke  InvalidateRect, hWnd, addr ErrRect, FALSE
            invoke  SetTimer,  hWnd, INSTANT, 0,0  
         
         @@:
            invoke  InvertRect, hDC, addr ErrRect
             
        .elseif eax == INSTANT
            mov     eax,    reppos
            lea     edi,    temprect
            invoke  PosToCurRect
            invoke  InvalidateRect, hWnd, edi, FALSE
            invoke  KillTimer, hWnd, INSTANT
             
        .endif
        
        xor eax,    eax
        ret
; END WM_TIMER

; BEGIN WM_USER
    .elseif eax == WM_USER
        mov     eax,    wParam
        .if eax == MAGIC_SQUARE_COMPLETE
            ; He won the game
            sete    Snooze ; Stop timer
            mov     byte ptr Started,   0  ; End of Game
            invoke  ChooseLevel, order
            mov     valuetype,  REG_DWORD
            lea     eax,    temp1    
            lea     edx,    temp
            ; Get previous best time for choosen leve
            invoke RegQueryValueEx,  MKey, esi, 0, addr valuetype, eax, edx
            mov     edx,    temp1           ; previous best time
            mov     eax,    dword ptr time  ; winning time
            
            .if eax < edx   ; Is winning time less than previous best time?
                ; Clear status bar
                invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szEmpty
                ; Yes, get the winners name.
                invoke  DialogBoxParam, hInst, addr szEdit, hWnd, EditDlgProc, 0
                ; Display best times
                invoke  DialogBoxParam, hInst, addr szBest, hWnd, BestDlgProc, 0
            .else
                invoke  PostMessage, hStatus, SB_SETTEXT, 0, addr szWinMsg
            .endif
            
        .elseif eax == NUNBER_IN_SQUARE_ERROR
            mov     eax,    errpos
            mov     edi,    offset ErrRect
            invoke  PosToCurRect
            invoke  InvertRect, hDC, addr ErrRect  ; Highlight the error rectangle
            invoke  SetTimer,  hWnd, ERR_ID, 600,0 ;...for 0.6 secs.
        .endif
    xor     eax,    eax
    ret
 ;END WM_USER
 
 ; BEGIN WM_PAINT
    ; whenever the screen needs updating
    .elseif eax == WM_PAINT
        invoke  BeginPaint, hWnd, addr ps
        mov     hDC,    eax
        invoke  SetBkMode, hDC, TRANSPARENT
        invoke  DrawMainRect
        invoke  DrawBoard
        invoke  DisplayText
        invoke  DisplayTime
        invoke  InvertRect, hDC, addr NxtRect
        invoke  EndPaint, hWnd, addr ps
        xor     eax,    eax
        ret
; END WM_PAINT
        
   .endif
   ; other message
   INVOKE DefWindowProc, hWnd, UMsg, wParam, lParam
   ret
WinProc  ENDP

UpdateTime PROC
    xor     eax,    eax
    xor     edx,    edx
    mov     ebx,    60
    add     time.seconds,   1
    cmp     time.seconds,   bl
    sete    al
    add     time.minutes,   al
    sub     al,     1
    and     time.seconds,   al
    cmp     time.minutes,   bl
    sete    dl
    add     time.hours,     dl
    sub     dl,     1
    and     time.seconds,   dl
    and     time.minutes,   dl
    ret
UpdateTime ENDP

MoveUp PROC
    movaps  xmm0,   oword ptr NxtRect
    movaps  oword ptr PrvRect,  xmm0
    invoke  InvertRect, hDC, addr PrvRect
    mov     eax,    PrvRect.top
    cmp     eax,    Mrect.top
    cmove   eax,    Mrect.bottom
    mov     NxtRect.bottom, eax
    sub     eax,    Vgap
    mov     NxtRect.top,    eax
    invoke  InvertRect, hDC, addr NxtRect
    ret
MoveUp ENDP

MoveDown PROC
    movaps  xmm0,   oword ptr NxtRect
    movaps  oword ptr PrvRect,  xmm0
    invoke  InvertRect, hDC, addr PrvRect
    mov     eax,    PrvRect.bottom
    cmp     eax,    Mrect.bottom
    cmove   eax,    Mrect.top
    mov     NxtRect.top,    eax
    add     eax,    Vgap
    mov     NxtRect.bottom, eax
    invoke  InvertRect, hDC, addr NxtRect
    ret
MoveDown ENDP

MoveRight PROC
    movaps  xmm0,   oword ptr NxtRect
    movaps  oword ptr PrvRect,  xmm0
    invoke  InvertRect, hDC, addr PrvRect
    mov     eax,    PrvRect.right
    cmp     eax,    Mrect.right
    cmove   eax,    Mrect.left
    mov     NxtRect.left,   eax
    add     eax,    Hgap
    mov     NxtRect.right,  eax
    invoke  InvertRect, hDC, addr NxtRect
    ret
MoveRight ENDP

MoveLeft PROC
    movaps  xmm0,   oword ptr NxtRect
    movaps  oword ptr PrvRect,  xmm0
    invoke  InvertRect, hDC, addr PrvRect
    mov     eax,    PrvRect.left
    cmp     eax,    Mrect.left
    cmove   eax,    Mrect.right
    mov     NxtRect.right,  eax
    sub     eax,    Hgap
    mov     NxtRect.left,   eax
    invoke  InvertRect, hDC, addr NxtRect
    ret
MoveLeft ENDP

CurRectToPos PROC
    xor     edx,    edx
    mov     eax,    NxtRect.right
    div     Hgap
    sub     eax,    1
    mov     ebx,    eax     ; column nuber
    mov     eax,    NxtRect.bottom
    xor     edx,    edx
    div     Vgap            ; eax == row number
    sub     eax,    1
    mov     edx,    order
    imul    edx,    eax     ; row * order
    add     edx,    ebx     ; + column
    mov     eax,    edx
    ret
CurRectToPos ENDP

PosToCurRect   PROC 
    ; Assume a pointer to Rect structure is in edi
left    = 0
top     = 4
right   = 8
bottom  = 12
    xor     edx,    edx
    div     order
    imul    eax,    Vgap
    imul    edx,    Hgap
    add     eax,    Mrect.top
    add     edx,    Mrect.left
    mov     left[edi],  edx
    mov     top[edi],   eax
    add     eax,    Vgap
    add     edx,    Hgap
    mov     right[edi],     edx
    mov     bottom[edi],    eax
    ret
PosToCurRect   ENDP

Setup   PROC
    invoke  CalcMagicNum
    invoke  CreateMagicSquare
    invoke  Shuffle
    ret
Setup   ENDP

EmptyAllSquares PROC
    mov     ecx,    NumSquares
    add     ecx,    3
    shr     ecx,    2
    xor     eax,    eax
    mov     edi,    offset Msquare
    rep     stosd
    ret
EmptyAllSquares ENDP

AboutDlgProc PROC hDlg:DWORD, UMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov     eax,    UMsg
    
    .if eax == WM_INITDIALOG
        mov     eax,    TRUE
        ret
        
    .elseif eax == WM_COMMAND
    
        .if wParam == IDOK
            invoke  EndDialog, hDlg, 0
            mov     eax,    TRUE
            ret
        .endif
        
    .endif
    
    xor eax, eax
    ret
AboutDlgProc ENDP    

BestDlgProc PROC hDlg:DWORD, UMsg:DWORD, wParam:DWORD, lParam:DWORD
    local count:dword, t:TIME, temp1:dword, temp2:dword, hEdit:HWND
    local szBuffer[20]:byte     ; Hold formatted string
    
    mov     eax,    UMsg
    .if eax == WM_INITDIALOG
        mov     eax,    3
        
    L1:
        push    eax
        mov     count,  eax
        invoke  ChooseLevel, eax
        mov     temp1,  esi
        mov     temp2,  edi
        mov     valuetype,  REG_SZ
        invoke  RegQueryValueEx, MKey, temp2, 0, addr valuetype,
                                 addr szBuffer, addr temp2
        mov     valuetype,  REG_DWORD
        invoke  RegQueryValueEx, MKey, temp1, 0, addr valuetype,
                                 addr t, addr temp2
        invoke  GetDlgItem, hDlg, count
        mov     hEdit,  eax
        invoke  GetWindowText, hEdit, addr szFormat, 60
        movzx   ecx,    t.hours
        movzx   ebx,    t.minutes
        movzx   eax,    t.seconds
        mov     edi,    offset szMsg
        mov     esi,    offset szFormat
        lea     edx,    szBuffer
        invoke  wsprintf, edi, esi, ecx, ebx, eax, edx
        invoke  SetWindowText, hEdit, addr szMsg
        pop     eax
        add     eax,    2
        cmp     eax,    IDM_EXPERT
        jbe     L1
        
        mov     eax,    TRUE
        ret
        
    .elseif eax == WM_COMMAND
    
        .if wParam == IDOK
            invoke  EndDialog, hDlg, 0
            mov     eax,    TRUE
            ret
        .endif
        
    .endif
    
    xor     eax,    eax
    ret
BestDlgProc ENDP    

EditDlgProc PROC hDlg:DWORD, UMsg:DWORD, wParam:DWORD, lParam:DWORD
    local temp1:dword, temp2:dword, hEdit:HWND
    mov     eax,    UMsg
    
    .if eax == WM_INITDIALOG
        invoke  ChooseLevel, order
        mov     temp2,  edi
        mov     valuetype,  REG_SZ
        invoke  RegQueryValueEx, MKey, edi, 0, addr valuetype,
                                 addr szFormat, addr temp1
        invoke  GetDlgItem, hDlg, ID_EDIT
        mov     hEdit,  eax
        invoke  SetWindowText, hEdit, addr szFormat
        invoke  SetFocus, hEdit
        invoke  SendMessage, hEdit, EM_SETSEL, 0, temp1
        invoke  GetDlgItem, hDlg, ID_FORMAT
        mov     hEdit,  eax
        invoke  GetWindowText, hEdit, addr szFormat, 20
        invoke  wsprintf, addr szMsg, addr szFormat, temp2
        invoke  SetWindowText, hEdit, addr szMsg
        mov     eax,    TRUE
        ret
        
    .elseif eax == WM_COMMAND
    
        .if wParam == IDOK
            invoke  GetDlgItem, hDlg, ID_EDIT
            mov     hEdit,  eax
            invoke  GetWindowText, hEdit, addr szFormat, 20   
            mov     temp1,  eax
            invoke  ChooseLevel, order
            mov     temp2,  esi
            invoke  RegSetValueEx, MKey, edi, 0, REG_SZ, addr szFormat, temp1
            invoke  RegSetValueEx, MKey, temp2, 0, REG_DWORD, addr time,4
            invoke  EndDialog, hDlg, 0
            mov     eax,    TRUE
            ret
        .endif    
        
    .endif
    
    xor     eax,    eax
    ret
EditDlgProc ENDP    

ChooseLevel PROC level:dword
    mov     eax,    level
    mov     edi,    offset szBeginner
    mov     esi,    offset szBeginnertime
    mov     edx,    offset szEasy
    mov     ecx,    offset szEasytime
    cmp     eax,    IDM_EASY
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    offset szIntermediate
    mov     ecx,    offset szIntemediatetime
    cmp     eax,    IDM_INTERMEDIATE
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    offset szHard
    mov     ecx,    offset szHardtime
    cmp     eax,    IDM_HARD
    cmove   edi,    edx
    cmove   esi,    ecx
    mov     edx,    offset szExpert
    mov     ecx,    offset szExperttime
    cmp     eax,    IDM_EXPERT
    cmove   edi,    edx
    cmove   esi,    ecx
    ret
ChooseLevel     ENDP

END WinMain