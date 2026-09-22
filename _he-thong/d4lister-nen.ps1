# =====================================================================
#   D4Lister - nen he thong: CAI DAT va CAP NHAT chung mot cho
#
#   Hai viec nay truoc day nam o hai file, ma phan loi giong het nhau
#   (tai .zip cua repo roi bung ra). Gop lai de sua mot cho la xong.
#
#   KHONG CAN cai Git.
#
#   Cach dung:
#     -Viec KiemTra     chi hoi GitHub co ban moi khong
#     -Viec CapNhat     co ban moi thi tai ve, ghi de (chua file rieng)
#     -Viec CaiDat      cai tu dau tren may trong
#
#   Ma thoat:
#     0 = dang la ban moi nhat / xong xuoi
#     1 = da cap nhat
#     2 = da cap nhat, VA co dung vao thu muc extension
#     3 = khong lam duoc (mat mang, GitHub chan...) - bo qua, chay tiep
# =====================================================================
param(
    [ValidateSet('KiemTra', 'CapNhat', 'CaiDat')]
    [string]$Viec = 'CapNhat',
    [string]$ThuMuc = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$REPO = 'mhuyhcm/D4Lister'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Cua NGUOI DUNG - ban tren mang khong duoc ghi de
$GIU_LAI = @('queue', 'phien-ban.txt', 'tesseract', '_cu', 'create-listing',
             '_anh-cu', 'thu-nghiem', '.git', 'CAI-DAT.bat')

function ShaMoiNhat {
    try {
        (Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/commits/main" `
            -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 20).sha
    } catch { $null }
}

function ShaDangCo {
    $f = Join-Path $ThuMuc 'phien-ban.txt'
    if (Test-Path $f) { (Get-Content $f -Raw).Trim() } else { '' }
}

# Tai .zip cua nhanh main ve, bung ra, tra ve duong dan thu muc goc ben trong
function TaiVeBung([string]$tam) {
    $zip = Join-Path $tam 'main.zip'
    Invoke-WebRequest -Uri "https://github.com/$REPO/archive/refs/heads/main.zip" `
        -OutFile $zip -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 600
    Expand-Archive -Path $zip -DestinationPath $tam -Force
    Get-ChildItem $tam -Directory | Where-Object { $_.Name -like 'D4Lister-*' } | Select-Object -First 1
}

# Chep de, chua ra file rieng. Tra ve $true neu co dung vao extension.
function ChepDe([string]$goc) {
    $dungExt = $false
    Get-ChildItem $goc -Recurse -File | ForEach-Object {
        $tuongDoi = $_.FullName.Substring($goc.Length + 1)
        $dauTien  = ($tuongDoi -split '[\\/]')[0]
        if ($GIU_LAI -contains $dauTien) { return }

        $dich = Join-Path $ThuMuc $tuongDoi
        # Chi chep khi noi dung THUC SU khac -> khong bao "da doi ext" oan
        if (Test-Path $dich) {
            if ((Get-FileHash $_.FullName -Algorithm SHA256).Hash -eq
                (Get-FileHash $dich       -Algorithm SHA256).Hash) { return }
        }
        $cha = Split-Path $dich -Parent
        if (-not (Test-Path $cha)) { New-Item -ItemType Directory -Force $cha | Out-Null }
        Copy-Item $_.FullName $dich -Force
        if ($dauTien -eq 'extension') { $script:dungExtGlobal = $true }
    }
    return $script:dungExtGlobal
}

# Bung Tesseract xach tay neu chua co
function BungTesseract {
    if (Test-Path (Join-Path $ThuMuc 'tesseract\tesseract.exe')) { return $true }
    $zip = Join-Path $ThuMuc '_he-thong\bo-cai\tesseract-portable.zip'
    if (-not (Test-Path $zip)) { return $false }
    Expand-Archive -Path $zip -DestinationPath $ThuMuc -Force
    Test-Path (Join-Path $ThuMuc 'tesseract\tesseract.exe')
}

function TimAHK {
    @('C:\Program Files\AutoHotkey\AutoHotkey.exe',
      'C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe',
      'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe') |
      Where-Object { Test-Path $_ } | Select-Object -First 1
}

# =====================================================================
$script:dungExtGlobal = $false

# ----- CHI KIEM TRA ---------------------------------------------------
if ($Viec -eq 'KiemTra') {
    $moi = ShaMoiNhat
    if (-not $moi) { exit 3 }
    if ($moi -eq (ShaDangCo)) { exit 0 } else { exit 1 }
}

# ----- CAP NHAT -------------------------------------------------------
if ($Viec -eq 'CapNhat') {
    $moi = ShaMoiNhat
    if (-not $moi) { exit 3 }
    if ($moi -eq (ShaDangCo)) { exit 0 }

    $tam = Join-Path $env:TEMP ('d4l_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force $tam | Out-Null
    try {
        $goc = TaiVeBung $tam
        if (-not $goc) { exit 3 }
        $dungExt = ChepDe $goc.FullName
        Set-Content -Path (Join-Path $ThuMuc 'phien-ban.txt') -Value $moi -Encoding ascii -NoNewline
        if ($dungExt) { exit 2 } else { exit 1 }
    }
    catch { exit 3 }
    finally { Remove-Item $tam -Recurse -Force -ErrorAction SilentlyContinue }
}

# ----- CAI DAT TU DAU -------------------------------------------------
Write-Host ''
Write-Host '================================================================'
Write-Host '   D4Lister  -  CAI DAT'
Write-Host '================================================================'
Write-Host "   Se cai vao: $ThuMuc"

Write-Host ''
Write-Host '[ 1/4 ] Dang tai tu GitHub (~60 MB, hoi lau)...' -ForegroundColor Cyan
$moi = ShaMoiNhat
if (-not $moi) {
    Write-Host '   [ LOI ] Khong hoi duoc GitHub. Kiem tra mang roi chay lai.' -ForegroundColor Red
    Read-Host 'Enter de thoat'; exit 1
}
$tam = Join-Path $env:TEMP ('d4l_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $tam | Out-Null
try {
    $goc = TaiVeBung $tam
    New-Item -ItemType Directory -Force $ThuMuc | Out-Null
    [void](ChepDe $goc.FullName)
    Set-Content -Path (Join-Path $ThuMuc 'phien-ban.txt') -Value $moi -Encoding ascii -NoNewline
} catch {
    Write-Host "   [ LOI ] $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Enter de thoat'; exit 1
} finally { Remove-Item $tam -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host '   Xong.'

Write-Host ''
Write-Host '[ 2/4 ] Dang bung Tesseract (doc chu trong anh)...' -ForegroundColor Cyan
if (BungTesseract) { Write-Host '   Xong.' }
else { Write-Host '   [ ! ] Khong bung duoc - se chay khong co phan doc chu.' -ForegroundColor Yellow }

Write-Host ''
Write-Host '[ 3/4 ] Kiem tra AutoHotkey...' -ForegroundColor Cyan
$ahk = TimAHK
if ($ahk) { Write-Host "   Da cai san." }
else {
    $setup = Join-Path $ThuMuc '_he-thong\bo-cai\AutoHotkey_1.1.37.02_setup.exe'
    if (Test-Path $setup) {
        Write-Host '   Chua cai. Dang mo bo cai - bam Express Installation.' -ForegroundColor Yellow
        Start-Process $setup -Wait
        $ahk = TimAHK
    }
    if ($ahk) { Write-Host '   Cai xong.' }
    else {
        Write-Host '   [ LOI ] Van chua cai duoc AutoHotkey.' -ForegroundColor Red
        Read-Host 'Enter de thoat'; exit 1
    }
}

Write-Host ''
Write-Host '[ 4/4 ] Khoi dong D4Lister...' -ForegroundColor Cyan
Start-Process $ahk -ArgumentList (Join-Path $ThuMuc 'D4Lister.ahk')
Start-Sleep -Seconds 2
Write-Host '   Da chay nen.'

$thuMucExt = Join-Path $ThuMuc 'extension'
try { Set-Clipboard -Value $thuMucExt } catch {}
Write-Host ''
Write-Host '================================================================'
Write-Host '   CON DUNG MOT VIEC PHAI LAM TAY' -ForegroundColor Yellow
Write-Host '================================================================'
Write-Host ''
Write-Host '   Duong dan da chep san vao clipboard:'
Write-Host "     $thuMucExt"
Write-Host ''
Write-Host '     1. Go vao thanh dia chi:  chrome://extensions'
Write-Host '     2. Bat cong tac  Developer mode  (goc tren ben phai)'
Write-Host '     3. Bam  Load unpacked'
Write-Host '     4. Trong o File name bam Ctrl+V roi bam Select Folder'
Write-Host ''
Write-Host '   Chrome bat buoc chinh ban bam - khong chuong trinh nao lach duoc.'
Write-Host ''
Write-Host '   TU GIO CHI CAN: bam dup  D4Lister.ahk' -ForegroundColor Green
Write-Host '   No tu kiem tra ban moi moi lan chay.'
Write-Host ''
Read-Host 'Enter de dong'
