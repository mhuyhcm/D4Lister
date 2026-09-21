@echo off
title D4Lister - tat
echo.
echo  Dang tat D4Lister...
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='AutoHotkey.exe'\" | Where-Object { $_.CommandLine -like '*D4Lister.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo  Xong. (Script AutoHotkey khac cua ban khong bi dung.)
echo.
timeout /t 4 >nul
