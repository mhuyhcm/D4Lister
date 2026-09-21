@echo off
setlocal enabledelayedexpansion
title D4Lister
cd /d "%~dp0"

rem ── Tu keo ban moi nhat ve tu GitHub ───────────────────────────────
rem    Khong co git / khong co mang thi bo qua, tool van chay binh thuong.
set EXT_DOI=
if exist ".git" (
  where git >nul 2>&1
  if not errorlevel 1 (
    echo  Dang kiem tra ban moi...
    for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set TRUOC=%%i
    git pull --quiet --ff-only >nul 2>&1
    for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set SAU=%%i
    if not "!TRUOC!"=="!SAU!" (
      echo  Da cap nhat ban moi.
      git diff --name-only !TRUOC! !SAU! 2>nul | findstr /b "extension/" >nul && set EXT_DOI=1
    )
  )
)

rem ── Tim AutoHotkey ─────────────────────────────────────────────────
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

rem ── Tat ban cu roi chay ban moi ────────────────────────────────────
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='AutoHotkey.exe'\" | Where-Object { $_.CommandLine -like '*D4Lister.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
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

if defined EXT_DOI (
  echo  ================================================================
  echo    LAN CAP NHAT NAY CO SUA TIEN ICH CHROME
  echo.
  echo    Chrome KHONG tu nap lai tien ich khi file tren dia doi.
  echo    Vao  chrome://extensions  bam nut xoay vong tren o D4Lister,
  echo    roi F5 lai trang diablo.trade.
  echo.
  echo    Khong lam buoc nay thi ban van dang dung BAN CU.
  echo  ================================================================
  echo.
  pause
  exit /b 0
)

echo  Dong cua so nay khong sao, tool van chay.
echo.
rem doi 8 giay. Dung ping chu khong dung timeout: timeout treo khi
rem chay tu cho khong co ban phim (script goi tu dong chang han).
ping -n 9 127.0.0.1 >nul
