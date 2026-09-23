@echo off
title D4Lister - cai duong ong TTS
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CAI-TTS.ps1"
echo.
pause
