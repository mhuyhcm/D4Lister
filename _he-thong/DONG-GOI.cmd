@echo off
rem Dong goi D4Lister thanh mot file .zip de danh tren may.
rem Bam dup file nay.
title D4Lister - dong goi
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DONG-GOI.ps1"
echo.
pause
