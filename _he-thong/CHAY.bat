@echo off
rem Chi dung khi may khong mo duoc file .ahk bang cach bam dup.
rem Binh thuong: bam dup D4Lister.ahk o thu muc cha.
title D4Lister
cd /d "%~dp0.."
set AHK=
if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files\AutoHotkey\AutoHotkey.exe
if exist "C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe" set AHK=C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe
if exist "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe" set AHK=C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe
if "%AHK%"=="" (
  echo  [ LOI ] Chua cai AutoHotkey v1.1
  pause
  exit /b 1
)
start "" "%AHK%" "%cd%\D4Lister.ahk"
