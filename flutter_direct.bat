@echo off
setlocal enabledelayedexpansion
cd /d "C:\Users\anasm\SEWS connect(pfa)"

REM Set Flutter environment without spaces issues
set "FLUTTER_ROOT=C:\Users\anasm\SEWS connect(pfa)\flutter\flutter"
set "DART_SDK=%FLUTTER_ROOT%\bin\cache\dart-sdk"
set "DART_EXE=%DART_SDK%\bin\dart.exe"
set "FLUTTER_TOOLS=%FLUTTER_ROOT%\packages\flutter_tools"
set "SNAPSHOT=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot"

REM Check if Dart exists
if not exist "%DART_EXE%" (
    echo Error: Dart SDK not found at %DART_EXE%
    echo Please run flutter doctor to check your installation
    exit /b 1
)

REM Run Flutter tools directly
"%DART_EXE%" --packages="%FLUTTER_TOOLS%\.dart_tool\package_config.json" "%SNAPSHOT%" %*
