@echo off
title D4Lister - cai dat
cd /d "%~dp0"
echo.
echo  Dang lay bo cai tu GitHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $s=(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mhuyhcm/D4Lister/main/cai-dat.ps1' -UseBasicParsing -TimeoutSec 30).Content; $f=Join-Path $env:TEMP 'd4l-cai-dat.ps1'; Set-Content -Path $f -Value $s -Encoding UTF8; & powershell -NoProfile -ExecutionPolicy Bypass -File $f -Dich (Join-Path $PWD 'D4Lister') } catch { Write-Host ('[ LOI ] ' + $_.Exception.Message) -ForegroundColor Red; Read-Host 'Enter de thoat' }"
