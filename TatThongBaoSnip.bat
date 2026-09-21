@echo off
chcp 65001 >nul
title Tat thong bao Snip & Sketch / Snipping Tool
echo.
echo ================================================================
echo   TAT THONG BAO CUA SNIP ^& SKETCH / SNIPPING TOOL
echo ================================================================
echo.
echo   Script nay ghi vao HKEY_CURRENT_USER (chi anh huong tai khoan
echo   dang dang nhap). KHONG can quyen Administrator.
echo.
echo   De BAT LAI thong bao: chay file TatThongBaoSnip_HoanTac.bat
echo.
echo ----------------------------------------------------------------

set "NOTIF=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"

echo [1/3] Snip ^& Sketch / Snipping Tool (UWP)...
reg add "%NOTIF%\Microsoft.ScreenSketch_8wekyb3d8bbwe!App" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo       [ ! ] Khong ghi duoc) else (echo       [ OK ])

echo [2/3] Snipping Tool ^(ban cu, Win32^)...
reg add "%NOTIF%\Microsoft.Windows.SnippingTool" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo       [ ! ] Khong ghi duoc) else (echo       [ OK ])

echo [3/3] Toast he thong cua chuc nang Snipping...
reg add "%NOTIF%\Windows.SystemToast.Snipping" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo       [ ! ] Khong ghi duoc) else (echo       [ OK ])

echo.
echo ----------------------------------------------------------------
echo   KIEM TRA LAI GIA TRI DA GHI:
echo ----------------------------------------------------------------
reg query "%NOTIF%\Microsoft.ScreenSketch_8wekyb3d8bbwe!App" /v Enabled 2>nul
reg query "%NOTIF%\Microsoft.Windows.SnippingTool" /v Enabled 2>nul
reg query "%NOTIF%\Windows.SystemToast.Snipping" /v Enabled 2>nul
echo.
echo   Enabled = 0x0  ==^>  da tat thong bao.
echo.
echo   LUU Y: dang xuat roi dang nhap lai (hoac khoi dong lai Explorer)
echo   de Windows nap lai cau hinh thong bao.
echo.
pause
