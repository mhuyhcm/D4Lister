@echo off
title D4Lister
cd /d "%~dp0"

rem Ban moi: chinh D4Lister.ahk tu kiem khi khoi dong. Khong can cai Git.

rem ── Lan dau chay: bung Tesseract xach tay ──────────────────────────
if not exist "tesseract\tesseract.exe" (
  if exist "cai-dat\tesseract-portable.zip" (
    echo.
    echo  Lan dau chay tren may nay - dang bung Tesseract ^(~160 MB^)...
    powershell -NoProfile -Command "Expand-Archive -Path 'cai-dat\tesseract-portable.zip' -DestinationPath '.' -Force" >nul 2>&1
    if exist "tesseract\tesseract.exe" ( echo  Xong. ) else ( echo  [ ! ] Bung khong duoc - se chay khong co phan doc chu. )
    echo.
  )
)

rem ── Tim AutoHotkey, chua co thi mo bo cai kem theo ─────────────────
call :TimAHK
if "%AHK%"=="" (
  if exist "cai-dat\AutoHotkey_1.1.37.02_setup.exe" (
    echo.
    echo  May nay chua cai AutoHotkey. Dang mo bo cai kem san...
    echo  Bam Express Installation la xong.
    echo.
    start /wait "" "cai-dat\AutoHotkey_1.1.37.02_setup.exe"
    call :TimAHK
  )
)
if "%AHK%"=="" (
  echo.
  echo  [ LOI ] Chua cai duoc AutoHotkey v1.1
  echo          Tai tay tai: https://www.autohotkey.com/download/ahk-v1.zip
  echo.
  pause
  exit /b 1
)

rem ── Tat ban cu roi chay ban moi ────────────────────────────────────
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='AutoHotkey.exe'\" | Where-Object { $_.CommandLine -like '*D4Lister.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
start "" "%AHK%" "%~dp0D4Lister.ahk"

echo.
echo  D4Lister da chay nen. No tu kiem tra ban moi ngay bay gio.
echo.
echo    Trong game     F3  chup item  ^(keo chon vung tooltip^)
echo    Tren trinh duyet
echo                   F4  dan mon dang chon
echo                   F5  sang mon ke + dan luon
echo                   F6  lui ve mon truoc
echo    Bat cu luc nao
echo                   F7  doi che do xu ly anh
echo                   F9  xoa sach hang doi
echo                   Ctrl+Shift+F11  nap lai ^(kiem tra luon ban moi^)
echo                   Ctrl+Shift+F12  thoat han
echo.
echo  Dong cua so nay khong sao, tool van chay.
echo.
ping -n 7 127.0.0.1 >nul
exit /b 0

:TimAHK
set AHK=
if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files\AutoHotkey\AutoHotkey.exe
if exist "C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe" set AHK=C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe
if exist "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe
goto :eof
