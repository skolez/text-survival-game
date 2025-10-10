@echo off
setlocal

REM Wrapper to launch ChromeDriver via the PowerShell helper
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch_chromedriver.ps1" %*

