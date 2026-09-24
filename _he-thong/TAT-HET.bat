@echo off
title D4Lister - tat
echo.
echo  Dang tat D4Lister...
rem Loc theo DONG LENH chu khong theo ten tien trinh: AutoHotkey co nhieu
rem ban chay (AutoHotkey.exe, AutoHotkeyU64.exe...) nen loc ten se bo sot.
rem Va loc dong lenh thi script AutoHotkey khac cua ban khong bi dung lay.
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'AutoHotkey*.exe' -and $_.CommandLine -like '*D4Lister.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo  Xong. (Script AutoHotkey khac cua ban khong bi dung.)
echo.
timeout /t 4 >nul
