@echo off
title D4Lister
cd /d "%~dp0"

set AHK=
if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files\AutoHotkey\AutoHotkey.exe
if exist "C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe" set AHK=C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe
if exist "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe

if "%AHK%"=="" (
  echo.
  echo  [ LOI ] May nay chua cai AutoHotkey v1.1
  echo          Tai tai: https://www.autohotkey.com/download/ahk-v1.zip
  echo.
  pause
  exit /b 1
)

taskkill /f /im AutoHotkey.exe /fi "WINDOWTITLE eq D4Lister*" >nul 2>&1
start "" "%AHK%" "%~dp0D4Lister.ahk"

echo.
echo  D4Lister da chay nen.
echo.
echo    Trong game     F3  chup item  (keo chon vung tooltip)
echo    Tren trinh duyet
echo                   F4  dan mon dang chon
echo                   F5  sang mon ke + dan luon
echo                   F6  lui ve mon truoc
echo    Bat cu luc nao
echo                   F7  doi che do xu ly anh
echo                   F9  xoa sach hang doi
echo                   Ctrl+Shift+F12  thoat han
echo.
echo  Dong cua so nay khong sao, tool van chay.
echo.
timeout /t 8 >nul
