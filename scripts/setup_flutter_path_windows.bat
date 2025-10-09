@echo off
setlocal

REM ------------------------------------------------------------
REM Setup Flutter PATH for current user (Windows)
REM Usage:
REM   1) Edit the FLUTTER_DIR below if Flutter is installed elsewhere
REM   2) Run this script from an elevated or normal PowerShell/cmd
REM   3) Restart your terminal after running
REM ------------------------------------------------------------

set "FLUTTER_DIR=C:\\src\\flutter"
set "FLUTTER_BIN=%FLUTTER_DIR%\\bin"

REM Show current plan
echo Adding %FLUTTER_BIN% to your user PATH...

REM Read current user PATH
for /f "tokens=2* delims=    " %%A in ('reg query HKCU\Environment /v Path 2^>nul ^| find /i "Path"') do set "USER_PATH=%%B"

REM If not present, append
echo %USER_PATH% | find /i "%FLUTTER_BIN%" >nul
if %ERRORLEVEL%==0 (
  echo Flutter bin already in PATH.
) else (
  setx Path "%USER_PATH%;%FLUTTER_BIN%"
  echo Done. You may need to close and reopen your terminal.
)

REM Verify (new terminals will show updated PATH)
where flutter 2>nul || echo Note: Open a NEW terminal and run: flutter --version

endlocal

