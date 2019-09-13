
.686p
.mmx
.xmm
.model flat, stdcall
option casemap:none     ; Makes Masm case sensitive

; unicode equ 1

.NOLIST

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include advapi32.inc    ; needed for Registry functions
include comctl32.inc

ifdef   unicode
include ucmacros.inc
include _user32.inc
include _kernel32.inc
include _gdi32.inc
include _advapi32.inc    ; needed for Registry functions
include _comctl32.inc

endif

includelib  user32.lib
includelib  kernel32.lib
includelib  gdi32.lib
includelib  advapi32.lib    ; needed for Registry functions
includelib  comctl32.lib    ; need for xp style theme


NUNBER_IN_SQUARE_ERROR    equ   2
MAGIC_SQUARE_COMPLETE     equ   15

IDM_NEW                   equ   40001
IDM_APP_EXIT              equ   40002
IDM_BEST_TIMES            equ   40003
IDM_APP_ABOUT             equ   40005
IDM_RESET                 equ   40006

IDM_BEGINNER              equ   0003
IDM_EASY                  equ   0005
IDM_INTERMEDIATE          equ   0007
IDM_HARD                  equ   0009
IDM_EXPERT                equ   0011
ICO_ID                    equ   105
ID_EDIT                   equ   333
ID_FORMAT                 equ   334

ID_HELPMSG                equ   62
ID_WINMSG                 equ   63




;TIME_ID     = 101
;KEYB_ID     = 102
;ERR_ID      = 103
;INSTANT     = 104
MAXSIZE     = 128

TIME STRUCT  4
    seconds     byte ?
    minutes     byte ?
    hours       byte ?
    reserved    byte ?
TIME ENDS    


DrawMainRect   PROTO
DrawBoard  PROTO
CalcMagicNum   PROTO
CalcNumSquares  PROTO
CheckRows   PROTO
CheckColumns   PROTO
CheckDiagonals  PROTO
EmptySomeSquares PROTO
CreateMagicSquare PROTO
RandRange PROTO :dword
Random32 PROTO 
Randomize PROTO
SymetryAbtRow  PROTO
SymetryAbtCol  PROTO
Rotation PROTO
DisplayText PROTO 
DisplayTime PROTO
CalcRectangles PROTO
MoveUp PROTO
MoveDown PROTO
MoveRight PROTO
MoveLeft PROTO
BuildAttrib PROTO
CurRectToPos PROTO
CheckBoard  PROTO
PosToCurRect  PROTO
Shuffle   PROTO
SetColors   PROTO
ChooseLevel PROTO :dword


RGB MACRO r,g,b
    EXITM <(r or ((g shl 8) or (b shl 16)))>
ENDM

BEG_FILL     equ RGB(255,111,111)
BEG_EMPTY    equ RGB(255,206,206)  
EAS_FILL     equ RGB(123,122,166)
EAS_EMPTY    equ RGB(196,196,255)
INT_FILL     equ RGB(64,128,128)
INT_EMPTY    equ RGB(196,255,255)  
HAR_FILL     equ RGB(255,154,53)    ;(0,108,20)
HAR_EMPTY    equ RGB(255,248,215)   ; (0,196,196)  
EXP_FILL     equ RGB(0,149,221)     ;(0,128,192) 
EXP_EMPTY    equ RGB(224,238,238)

.LIST
