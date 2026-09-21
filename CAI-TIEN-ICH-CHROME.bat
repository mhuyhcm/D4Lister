@echo off
chcp 65001 >nul
title D4Lister - cai tien ich vao Chrome
echo(
echo  ================================================================
echo    D4Lister  -  CAI TIEN ICH VAO CHROME
echo  ================================================================
echo(
echo  Duong dan thu muc tien ich (da chep san vao clipboard):
echo(
echo      %~dp0extension
echo(
echo|set /p="%~dp0extension"| clip
echo  ----------------------------------------------------------------
echo    LAM 4 BUOC NAY TRONG CHROME:
echo  ----------------------------------------------------------------
echo(
echo    1. Go vao thanh dia chi:   chrome://extensions
echo(
echo    2. Bat cong tac  "Developer mode"  o goc TREN BEN PHAI
echo(
echo    3. Bam nut  "Load unpacked"  vua hien ra o goc tren ben trai
echo(
echo    4. Trong o "File name", bam Ctrl+V roi bam "Select Folder"
echo(
echo  ----------------------------------------------------------------
echo(
echo  Xong thi mo diablo.trade len, tien ich tu chay.
echo  Sua code trong thu muc extension thi vao chrome://extensions
echo  bam nut xoay vong tren o cua tien ich de nap lai.
echo(
pause
