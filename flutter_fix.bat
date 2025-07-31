@echo off
cd /d "C:\Users\anasm\SEWS connect(pfa)"
set FLUTTER_ROOT=C:\Users\anasm\SEWS connect(pfa)\flutter\flutter
set PATH=%FLUTTER_ROOT%\bin;%PATH%
set DART_SDK=%FLUTTER_ROOT%\bin\cache\dart-sdk
set PATH=%DART_SDK%\bin;%PATH%

REM Run Flutter command
%FLUTTER_ROOT%\bin\flutter.bat %*
