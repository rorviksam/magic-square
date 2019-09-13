; Copyright (C) 2011 Nguemo Samobeu Rorvik 
; All rights reserved.


Include magicsquare.inc


Public cxClient, cyClient, hDC

AboutDlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
EditDlgProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD
BestDlgProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD
TIME_ID      PROTO
ERR_ID       PROTO
INSTANT      PROTO
KEYB_ID      PROTO

extern Trect:RECT, Mrect:RECT
extern Vgap:dword, Hgap:dword,  PrvRect:RECT, NxtRect:RECT
extern Attributes:byte, Msquare:byte, NumSquares:dword, time:TIME
extern MagicNumber:dword, order:dword

.data

iSelection         dword        IDM_BEGINNER
valuetype          dword        REG_BINARY
KeyDisposition     dword        REG_CREATED_NEW_KEY 
$wc     WNDCLASS   < CS_OWNDC, WinProc, 0, 0, 0, 0, 0, 0, szAppName, szAppName >
Snooze             byte 1       ; Every time the game start's waits for user input
State              byte 1       ; initial timing status

.const

maxtime            dword    00636363h

WM_CMDS_TAB        dword    WM_PAINT, WM_TIMER, WM_COMMAND, WM_MOUSEMOVE, WM_KEYDOWN,
                            WM_USER,  WM_SIZE,  WM_CHAR,    WM_CREATE,    WM_DESTROY
                   
W_CB_TAB           dword    WPaint,   WTimer,   WCommand,   WMousemove,   WKeydown, 
                            WUser,    WSize,    WChar,      WCreate,      WDestroy

szAbout            SZWSTR("ABOUTBOX")
szEdit             SZWSTR("WINBOX")
szBest             SZWSTR("BESTTIMES")
szAppName          SZWSTR("MagicSquare")
szKeyFolder        SZWSTR("Software\MagicSquare")
szAttrib           SZWSTR("Attributes")
szTime             SZWSTR("Time")
szOrder            SZWSTR("order")
szStatus           SZWSTR("GameStatus")
szWarning          WSTR("Delete settings stored")
                   SZWSTR(" in the registry?")
szWinerName        SZWSTR("Anonymous")
szBeginner         SZWSTR("Beginner")
szEasy             SZWSTR("Easy")
szIntermediate     SZWSTR("Intermediate")
szHard             SZWSTR("Hard")
szExpert           SZWSTR("Expert")
szBeginnertime     SZWSTR("BeginnerTime")
szEasytime         SZWSTR("EasyTime")
szIntemediatetime  SZWSTR("IntemediateTime")
szHardtime         SZWSTR("HardTime")
szExperttime       SZWSTR("ExpertTime")
szEmpty            SZWSTR(" ")

.data?
align 16
ErrRect            RECT     <>     ; Error rectangle
$msg               MSG      <>
hWin               dword    ?      ; Main window handle
$hWnd              dword    ? 
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
szFormat           word 128 dup(?)
szMsg              word 160 dup(?) 

.code

WinMain PROC 
    ; Do 4 byte stack alignement
    and     esp,    -4

    ; End Stack alignement
    ; Ensure Xp style theme
    call     InitCommonControls

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

   ; Now create the window
    $WS =   WS_MINIMIZEBOX or WS_OVERLAPPED or WS_CAPTION OR WS_SYSMENU
    invoke CreateWindowEx, 0, addr szAppName, addr szAppName,
                           $WS , edi, eax, 506, 510, 0, 0, hInst, 0
    mov     hWin,   eax

    ; Assume Window was created
    invoke  ShowWindow, hWin, SW_SHOW
    invoke  UpdateWindow, hWin
    
    jmp     short @F
    
align 16    
MsgLoop:
    invoke  TranslateMessage,   addr $msg
    invoke  DispatchMessage,   addr $msg
@@:
    invoke  GetMessage, addr $msg, 0, 0, 0
    test    eax,    eax
    jnz     short MsgLoop
    
    mov     eax,    $msg.wParam
    invoke  ExitProcess,    eax
WinMain ENDP

WinProc  PROC hWnd:DWORD, UMsg:DWORD, wParam:DWORD, lParam:DWORD
    
    mov     eax,    UMsg
    mov     edi,    offset WM_CMDS_TAB
    mov     ecx,    lengthof WM_CMDS_TAB
    cld
    repne   scasd
    jnz     OtherMsg
    
    sub     edi,    offset WM_CMDS_TAB
    mov     ecx,    edi
    mov     edx,    hWnd
    mov     $hWnd,  edx
    mov     eax,    wParam
    movzx   esi,    word ptr lParam
    movzx   edi,    word ptr lParam+2
    call    near ptr W_CB_TAB[ecx - 4]
    xor     eax,    eax
    ret

    ; other message
OtherMsg:
    INVOKE  DefWindowProc, hWnd, UMsg, wParam, lParam
    ret
WinProc  ENDP

WCreate   PROC
    local temp:dword
    ; Store the device context
    invoke  GetDC,  $hWnd
    mov     hDC,    eax
    
    ; Establish main menu
    invoke  GetMenu,    $hWnd
    mov     hMenu,      eax
    
    ; Create status bar
    $ST = WS_CHILD or WS_VISIBLE or SBS_SIZEGRIP    ; Status bar style
    invoke  CreateStatusWindow, $ST, 0, $hWnd, 200
    mov     hStatus,    eax        
    
    ; Open registry
    invoke  RegOpenKeyEx, HKEY_CURRENT_USER, addr szKeyFolder,
                          0, KEY_ALL_ACCESS, addr MKey
    .if eax ==  ERROR_SUCCESS
        ; Recover Saved settings
        mov     temp,   128
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
        call     SetColors
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
        call     Setup
        invoke  BuildAttrib
    .endif
    
    .if Started == 1
        invoke  SetTimer, $hWnd, TIME_ID, 1000, 0  
    .endif   
    ret    
WCreate   ENDP

WDestroy  PROC
    .if eax == 0        ; eax   == wParam
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
    
    ; Kill the timer that we created
    invoke  KillTimer, $hWnd, TIME_ID
    invoke  ReleaseDC, $hWnd, hDC
    
    invoke  RegCloseKey, MKey
    
    ; Tell the application to terminate after the window is gone.
    invoke  PostQuitMessage, 0
    ret
WDestroy  ENDP

.const
align   4
Mn_TAB      dword   IDM_NEW, IDM_APP_EXIT, IDM_RESET, IDM_BEST_TIMES, IDM_APP_ABOUT
Mn_CB_TAB   dword   MnNew,   MnExit,       MnReset,   MnBestTime,     MnAbout

.code
WCommand  PROC
    ; esi   ==  lowword(lParam)
    test    esi,    esi     
    jnz     short L1      ;   Not a Menu
    
    movzx   eax,    ax      ; eax == wParam
    mov     edi,    offset Mn_TAB
    mov     ecx,    lengthof Mn_TAB
    cld
    repne   scasd
    jnz     short @F
    
    sub     edi,    offset Mn_TAB
    call    near ptr Mn_CB_TAB[edi-4]
    ret
@@:
    call     MnLevel
L1:
    ret
WCommand  ENDP
    
MnNew   PROC

    call     CalcNumSquares
    call     EmptyAllSquares
    call     Setup
    call     EmptySomeSquares
    invoke  BuildAttrib
    
    .if Started == 0    ; The game has not yet started
        sete    byte ptr Started
        invoke  SetTimer, $hWnd, TIME_ID, 1000, 0
    .endif
    
    mov     dword ptr time, 0   ; Reset timer
    mov     Snooze,     1       ; D'ont start timing wait for input
    invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 128
    invoke  wsprintf, addr szMsg, addr szFormat, NumSquares, MagicNumber
    invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szMsg
    invoke  InvalidateRect, $hWnd, 0, TRUE
    ret
MnNew   ENDP        

MnExit  PROC
    invoke  SendMessage, $hWnd, WM_CLOSE, 0, 0
    ret
MnExit  ENDP        

MnReset PROC    
    movzx   eax,    Snooze
    push    eax
    mov     Snooze, 1   ; Pause
    $MB  =  MB_ICONQUESTION or MB_YESNO
    invoke  MessageBox, $hWnd, addr szWarning, addr szAppName, $MB
    
    .if eax == IDYES 
        invoke  RegDeleteKey, HKEY_CURRENT_USER, addr szKeyFolder
        invoke  SendMessage, $hWnd, WM_CLOSE, 1, 0
    .endif
    
    pop     eax
    mov     Snooze, al   ; Continue
    ret
MnReset ENDP        
    
MnBestTime  PROC       ; Show Best time dialog
    movzx   eax,    Snooze
    push    eax
    mov     Snooze, 1              ; Stop timer
    invoke  DialogBoxParam, hInst, addr szBest, $hWnd, BestDlgProc, 0
    pop     eax
    mov     Snooze, al          ; Restart timer
    ret
MnBestTime  ENDP        

MnAbout PROC
    movzx   eax,    Snooze
    mov     Snooze, 1              ; Stop timer
    push    eax
    invoke  DialogBoxParam, hInst, addr szAbout, $hWnd, AboutDlgProc, 0
    pop     eax
    mov     Snooze, al          ; Restart timer
    ret
MnAbout ENDP

MnLevel PROC

    mov     order,  eax
    call     SetColors
    invoke  CheckMenuItem, hMenu, iSelection, MF_UNCHECKED
    mov     eax,    order
    mov     iSelection, eax
    invoke  CheckMenuItem, hMenu, iSelection, MF_CHECKED
    call     CalcNumSquares
    call     EmptyAllSquares
    call     Setup
    
    .if Started == 1
        call    EmptySomeSquares
        invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 128
        invoke  wsprintf, addr szMsg, addr szFormat, NumSquares, MagicNumber
        invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szMsg
    .else
        invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szEmpty
    .endif
    
    mov     dword ptr time, 0   ; Reset timer
    mov     Snooze,     1       ; D'ont start wait for input
    call     BuildAttrib
    invoke   CalcRectangles
    invoke  InvalidateRect, $hWnd, 0, TRUE
    ret
MnLevel ENDP        


WSize     PROC
    
    mov     cxClient,   esi     ; esi = loword(lParam)
    mov     cyClient,   edi     ; edi = highword(lParam)
    ; eax == wParam
    .if eax == SIZE_RESTORED       
         mov    al,     State
         mov    Snooze, al              ; Restore timer state
         invoke CalcRectangles
    .elseif eax == SIZE_MINIMIZED       ; Is the window minimized
         movzx  eax,    Snooze     
         mov    Snooze, 1               ; Pause
         mov    State,  al              ; Save timer state
    .endif
     
   .if Started == 1
        invoke  LoadString, hInst, ID_HELPMSG, addr szFormat, 128
        invoke  wsprintf, addr szMsg, addr szFormat, NumSquares, MagicNumber
        invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szMsg
   .endif
   ret
WSize    ENDP

WMousemove    PROC
     ; esi == x
     ; edi == y
    invoke  PtInRect, addr Mrect, esi, edi
    test    eax,    eax
    jz      OutOfRect       ; Out of main rect
    
    invoke  PtInRect, addr NxtRect, esi, edi
    test    eax,    eax   
    jnz     OutOfRect       ; We are still in the current rect
    ; We are in another rectangle
    movaps  xmm0,   oword ptr NxtRect
    movntps  oword ptr PrvRect,  xmm0
    invoke  InvertRect, hDC, addr PrvRect
    xor     edx,    edx
    mov     eax,    esi     ;x
    sub     eax,    Mrect.left
    div     Hgap
    imul    eax,    Hgap
    add     eax,    Mrect.left
    mov     NxtRect.left,   eax
    add     eax,    Hgap
    mov     NxtRect.right,  eax
    xor     edx,    edx
    mov     eax,    edi    ;y
    sub     eax,    Mrect.top
    div     Vgap
    imul    eax,    Vgap
    add     eax,    Mrect.top
    mov     NxtRect.top,    eax
    add     eax,    Vgap
    mov     NxtRect.bottom, eax
    invoke  InvertRect, hDC, addr NxtRect
OutOfRect:
   ret 
WMousemove    ENDP

.const
KD_TAB      byte    VK_UP,  VK_DOWN,  VK_RIGHT,  VK_LEFT,  VK_F2
KD_CB_TAB   dword   MoveUp, MoveDown, MoveRight, MoveLeft, MnNew

.code
WKeydown  PROC
    mov     edi,    offset KD_TAB
    mov     ecx,    sizeof KD_TAB
    cld
    repne   scasb
    jnz     short @F
    
    sub     edi,    offset KD_TAB
    ;lea     edi,    [edi*4]
    call    near ptr KD_CB_TAB[edi*4-4]
@@:
    ret
WKeydown  ENDP

WTimer PROC
    call    eax
    ret
WTimer ENDP

WUser     PROC
    local temp1:dword, temp:dword
    .if eax == MAGIC_SQUARE_COMPLETE

        ; He won the game
        mov     Snooze,    1		        ; Stop timer
        mov     byte ptr Started,   0       ; End of Game
        invoke  ChooseLevel, order
        mov     valuetype,  REG_DWORD
        mov     temp,   4
        ; Get previous best time for choosen level
        invoke RegQueryValueEx,  MKey, esi, 0, addr valuetype, addr temp1, addr temp
        mov     edx,    temp1           ; previous best time
        mov     eax,    dword ptr time  ; winning time
        
        .if eax < edx   ; Is winning time less than previous best time?

            ; Clear status bar
            invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szEmpty

            ; Yes, get the winners name.
            invoke  DialogBoxParam, hInst, addr szEdit, $hWnd, EditDlgProc, 0

            ; Display best times
            invoke  DialogBoxParam, hInst, addr szBest, $hWnd, BestDlgProc, 0
        .else
            invoke  LoadString, hInst, ID_WINMSG, addr szFormat, 128
            invoke  PostMessage, hStatus, SB_SETTEXTW, 0, addr szFormat
        .endif
        
    .elseif eax == NUNBER_IN_SQUARE_ERROR
        mov     eax,    errpos
        mov     edi,    offset ErrRect
        invoke  PosToCurRect
        invoke  InvertRect, hDC, addr ErrRect  ; Highlight the error rectangle
        invoke  SetTimer,  $hWnd, ERR_ID, 600,0 ;...for 0.6 secs.
    .endif
    ret
WUser     ENDP

WChar     PROC
    push    eax
    invoke  CurRectToPos
    mov     curpos, eax
    pop     eax
    .if eax >= VK_0 && eax <= VK_9
        sub     eax,    30h
        mov     edx,    curchar
        shl     edx,    8
        or      edx,    eax
        mov     curchar,    edx
        
        .if OnInput == 0
            mov     OnInput,    1     ; Indicate the user is typing, give him
            invoke  SetTimer, $hWnd, KEYB_ID, 600, 0  ;. 0.6sec for that.
        .endif
        
    .endif
    ret
WChar     ENDP

WPaint    PROC
    local ps:PAINTSTRUCT
    
    invoke  BeginPaint, $hWnd, addr ps
    mov     hDC,    eax
    invoke  SetBkMode, hDC, TRANSPARENT
    invoke  DrawMainRect
    invoke  DrawBoard
    invoke  DisplayText
    invoke  DisplayTime
    invoke  InvertRect, hDC, addr NxtRect
    invoke  EndPaint, $hWnd, addr ps
    ret
WPaint    ENDP


TIME_ID PROC
    xor     eax,    eax
    cmp     Snooze, al
    jne     short @F

    ; Update time
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
    invoke  InvalidateRect, $hWnd, addr Trect, FALSE
@@:
    ret
TIME_ID ENDP

INSTANT PROC
    local temprect:RECT
    mov     eax,    reppos
    lea     edi,    temprect
    invoke  PosToCurRect
    invoke  InvalidateRect, $hWnd, edi, FALSE
    invoke  KillTimer, $hWnd, INSTANT
    ret
INSTANT ENDP

ERR_ID  PROC
    invoke  KillTimer, $hWnd, ERR_ID
    mov     edi,    errpos
    xor     edx,    edx
    cmp     Attributes[edi], 1
    setne   dl
    cmovne  ebx,    reppos
    sub     edx,    1
    and     Msquare[edi],   dl
    jnz     short @F
 
    mov     eax,    input
    mov     Msquare[ebx],   al    ; clear the previous
    invoke  InvalidateRect, $hWnd, addr ErrRect, FALSE
    invoke  SetTimer,  $hWnd, INSTANT, 0,0  
 
 @@:
    invoke  InvertRect, hDC, addr ErrRect
    ret
ERR_ID  ENDP

KEYB_ID PROC
    local temprect:RECT
    invoke  KillTimer, $hWnd, KEYB_ID

    ; Has the game Started?
    cmp     Started,    0
    je      stop            ; No!
    
    ; Now convert current char to a number
    mov     ebx,    curpos
    cmp     Attributes[ebx],    1   		; Trying to overide an invalid square
    je      stop                		; Don't overide this square
    
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
    jz      short overide     ; you have entered zero, clear the current square

    ; 1 <= eax <= order^2
    ; Is it already in the magic square?   
    mov     ecx,    NumSquares
    mov     edi,    offset Msquare
    mov     esi,    edi
    cld
    repne   scasb
    jnz     short overide ; No!
    
    ; Yes, get it's position.
    sub     edi,    esi   
    sub     edi,    1
    mov     errpos, edi     ; Save it
    mov     reppos, ebx     ; Save the position of the input number
    cmp     edi,    ebx
    je      short stop        ; You have entered the same number in the square 
    
    ; Report error : The number is already in the Magic square
    invoke  PostMessage, $hWnd, WM_USER, NUNBER_IN_SQUARE_ERROR , 0
    jmp     short stop
    
overide:
    mov     Msquare[ebx],   al    ; overide the current square( set it )
    mov     eax,    ebx
    lea     edi,    temprect
    invoke  PosToCurRect
    invoke  InvalidateRect, $hWnd, edi, FALSE
    invoke  CheckBoard
    cmp     eax,    MAGIC_SQUARE_COMPLETE
    jne     short stop
    
    invoke  SendMessage, $hWnd, WM_USER, MAGIC_SQUARE_COMPLETE, 0
    
stop:
    mov     OnInput,    0
    mov     curchar,    0
    ret
KEYB_ID ENDP

MoveUp PROC
    movaps  xmm0,   oword ptr NxtRect
    movntps  oword ptr PrvRect,  xmm0
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
    movntps  oword ptr PrvRect,  xmm0
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
    movntps  oword ptr PrvRect,  xmm0
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
    movntps  oword ptr PrvRect,  xmm0
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
    local count:dword, t:TIME, temp2:dword, hEdit:HWND
    local szBuffer[50]:word    ; Hold formatted string
    
    mov     eax,    UMsg
    .if eax == WM_INITDIALOG
        mov     eax,    IDM_BEGINNER
        
    L1:
        push    eax
        mov     count,  eax
        invoke  ChooseLevel, eax
        mov     valuetype,  REG_SZ
        mov     temp2,  50*2
        invoke  RegQueryValueEx, MKey, edi, 0, addr valuetype,
                                 addr szBuffer, addr temp2
        mov     valuetype,  REG_DWORD
        mov     temp2,   4
        invoke  RegQueryValueEx, MKey, esi, 0, addr valuetype,
                                 addr t, addr temp2
        invoke  GetDlgItem, hDlg, count
        mov     hEdit,  eax
        invoke  GetWindowText, hEdit, addr szFormat, sizeof szFormat
        lea     edx,    szBuffer
        movzx   eax,    t.seconds
        movzx   ebx,    t.minutes
        movzx   ecx,    t.hours
        mov     esi,    offset szFormat
        mov     edi,    offset szMsg
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
    local temp2:dword, temp3:dword, hEdit:HWND
    mov     eax,    UMsg
    
    .if eax == WM_INITDIALOG
        invoke  ChooseLevel, order
        mov     temp3,  edi
        mov     valuetype,  REG_SZ
        mov     temp2,  50*2
        invoke  RegQueryValueEx, MKey, edi, 0, addr valuetype,
                                 addr szFormat, addr temp2
        invoke  GetDlgItem, hDlg, ID_EDIT
        mov     hEdit,  eax
        invoke  SetWindowText, hEdit, addr szFormat
        invoke  SetFocus, hEdit
        invoke  SendMessage, hEdit, EM_SETSEL, 0, temp2
        invoke  GetDlgItem, hDlg, ID_FORMAT
        mov     hEdit,  eax
        invoke  GetWindowText, hEdit, addr szFormat, sizeof szFormat
        invoke  wsprintf, addr szMsg, addr szFormat, temp3
        invoke  SetWindowText, hEdit, addr szMsg
        mov     eax,    TRUE
        ret
        
    .elseif eax == WM_COMMAND
    
        .if wParam == IDOK
            invoke  GetDlgItem, hDlg, ID_EDIT
            mov     hEdit,  eax
            invoke  GetWindowText, hEdit, addr szFormat, sizeof szFormat
            lea     eax,    [eax*2+2] ; number unicode chars times 2  = number of bytes read
                                      ;...... include unicode null teminating char
            mov     temp2,  eax
            invoke  ChooseLevel, order
            invoke  RegSetValueEx, MKey, edi, 0, REG_SZ, addr szFormat, temp2
            invoke  RegSetValueEx, MKey, esi, 0, REG_DWORD, addr time, 4
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
