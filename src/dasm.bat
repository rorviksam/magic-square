@echo off
cls
REM The following lines can be customized for your system:
REM ********************************************BEGIN customize
@echo Setting environment for MASM9.
@set PATH=C:\WinDDK\7600.16385.1\bin\x86;C:\WinDDK\7600.16385.1\bin\x86\x86;C:\Program Files\Microsoft Visual Studio 9.0\Common7\IDE;%PATH%
@set INCLUDE=D:\Dev\masm615\include;D:\Dev\masm32\include;%INCLUDE%
@set LIB=C:\WinDDK\7600.16385.1\lib\wxp\i386;C:\WinDDK\7600.16385.1\lib\Crt\i386;%LIB%
@set LIBPATH=C:\WinDDK\7600.16385.1\lib\wxp\i386;C:\WinDDK\7600.16385.1\lib\Crt\i386;%LIBPATH%
REM ********************************************END customize
 
@echo on 

dumpbin /DISASM /IMPORTS /RELOCATIONS /DEPENDENTS /OUT:%1.txt %1.exe