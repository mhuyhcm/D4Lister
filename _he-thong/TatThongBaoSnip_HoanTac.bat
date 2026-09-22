@echo off
chcp 65001 >nul
title Hoan tac - Bat lai thong bao Snip & Sketch
echo.
echo   BAT LAI thong bao cua Snip ^& Sketch / Snipping Tool...
echo.

set "NOTIF=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"

reg add "%NOTIF%\Microsoft.ScreenSketch_8wekyb3d8bbwe!App" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%NOTIF%\Microsoft.Windows.SnippingTool" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%NOTIF%\Windows.SystemToast.Snipping" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1

echo   [ OK ] Da bat lai. Dang xuat / dang nhap lai de co hieu luc.
echo.
pause
