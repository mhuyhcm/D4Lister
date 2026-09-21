# =====================================================================
#   D4Lister - cai dat tu dau tren mot may moi
#
#   KHONG CAN cai Git. Tai thang file .zip cua repo.
#   Viec duy nhat ban phai lam tay: nap tien ich vao Chrome (Chrome bat
#   buoc chinh nguoi dung bam, khong chuong trinh nao lach duoc).
# =====================================================================
param([string]$Dich = (Join-Path $PWD 'D4Lister'))

$ErrorActionPreference = 'Stop'
$REPO = 'mhuyhcm/D4Lister'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Buoc($n, $chu) { Write-Host ""; Write-Host "[ $n ] $chu" -ForegroundColor Cyan }

Write-Host ""
Write-Host "================================================================"
Write-Host "   D4Lister  -  CAI DAT"
Write-Host "================================================================"
Write-Host "   Se cai vao: $Dich"

# --- 1. Tai ma nguon ---------------------------------------------------
Buoc 1 "Dang tai tu GitHub (~60 MB, hoi lau)..."
$tam = Join-Path $env:TEMP ('d4l_cai_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $tam | Out-Null
$zip = Join-Path $tam 'main.zip'
try {
    $tin = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/commits/main" `
             -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 20
    Invoke-WebRequest -Uri "https://github.com/$REPO/archive/refs/heads/main.zip" `
        -OutFile $zip -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 600
} catch {
    Write-Host "   [ LOI ] Khong tai duoc: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Kiem tra mang roi chay lai file nay." -ForegroundColor Yellow
    Read-Host "Enter de thoat"; exit 1
}
Expand-Archive -Path $zip -DestinationPath $tam -Force
$goc = Get-ChildItem $tam -Directory | Where-Object { $_.Name -like 'D4Lister-*' } | Select-Object -First 1

New-Item -ItemType Directory -Force $Dich | Out-Null
Copy-Item (Join-Path $goc.FullName '*') $Dich -Recurse -Force
Set-Content -Path (Join-Path $Dich 'phien-ban.txt') -Value $tin.sha -Encoding ascii -NoNewline
Remove-Item $tam -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   Xong."

# --- 2. Tesseract ------------------------------------------------------
Buoc 2 "Dang bung Tesseract (doc chu trong anh)..."
$zipTess = Join-Path $Dich 'cai-dat\tesseract-portable.zip'
if (Test-Path (Join-Path $Dich 'tesseract\tesseract.exe')) {
    Write-Host "   Da co san."
} elseif (Test-Path $zipTess) {
    Expand-Archive -Path $zipTess -DestinationPath $Dich -Force
    Write-Host "   Xong."
} else {
    Write-Host "   [ ! ] Khong thay ban nen - se chay khong co phan doc chu." -ForegroundColor Yellow
}

# --- 3. AutoHotkey -----------------------------------------------------
Buoc 3 "Kiem tra AutoHotkey..."
function TimAHK {
    @('C:\Program Files\AutoHotkey\AutoHotkey.exe',
      'C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe',
      'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe') |
      Where-Object { Test-Path $_ } | Select-Object -First 1
}
$ahk = TimAHK
if ($ahk) {
    Write-Host "   Da cai san: $ahk"
} else {
    $setup = Join-Path $Dich 'cai-dat\AutoHotkey_1.1.37.02_setup.exe'
    if (Test-Path $setup) {
        Write-Host "   Chua cai. Dang mo bo cai - bam Express Installation." -ForegroundColor Yellow
        Start-Process $setup -Wait
        $ahk = TimAHK
    }
    if ($ahk) { Write-Host "   Cai xong." }
    else {
        Write-Host "   [ LOI ] Van chua cai duoc AutoHotkey." -ForegroundColor Red
        Read-Host "Enter de thoat"; exit 1
    }
}

# --- 4. Chay ------------------------------------------------------------
Buoc 4 "Khoi dong D4Lister..."
Start-Process $ahk -ArgumentList (Join-Path $Dich 'D4Lister.ahk')
Start-Sleep -Seconds 2
Write-Host "   Da chay nen."

# --- 5. Tien ich Chrome -------------------------------------------------
$thuMucExt = Join-Path $Dich 'extension'
Set-Clipboard -Value $thuMucExt
Write-Host ""
Write-Host "================================================================"
Write-Host "   CON DUNG MOT VIEC PHAI LAM TAY" -ForegroundColor Yellow
Write-Host "================================================================"
Write-Host ""
Write-Host "   Duong dan da chep san vao clipboard:"
Write-Host "     $thuMucExt"
Write-Host ""
Write-Host "     1. Go vao thanh dia chi:  chrome://extensions"
Write-Host "     2. Bat cong tac  Developer mode  (goc tren ben phai)"
Write-Host "     3. Bam  Load unpacked"
Write-Host "     4. Trong o File name bam Ctrl+V roi bam Select Folder"
Write-Host ""
Write-Host "   Chrome bat buoc chinh ban bam - khong chuong trinh nao lach duoc."
Write-Host ""
Write-Host "   Xong thi mo https://diablo.trade, thay dong 'D4Lister san sang'"
Write-Host "   hien o goc duoi ben phai la da chay tot."
Write-Host ""
Write-Host "   TU GIO: chi can chay  CHAY.bat  (hoac de D4Lister chay san)."
Write-Host "   No tu kiem tra ban moi moi lan khoi dong."
Write-Host ""
Read-Host "Enter de dong"
