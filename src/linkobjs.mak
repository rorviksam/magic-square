#Assemble with MASM9

!include C:\Dev\projects2.mak

PROJ    =   MagicSquareW

OBJS    =   MainWinExW.obj rand.obj magicsquare.obj transform.obj \
            boardExW.obj check.obj MagicSquare.res
       


all: $(PROJ).EXE
$(PROJ).EXE: $(OBJS)
      link $(LFLAGS) $(OBJS) /SUBSYSTEM:WINDOWS /OUT:$(PROJ).exe
