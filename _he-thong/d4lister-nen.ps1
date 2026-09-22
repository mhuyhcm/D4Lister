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
$GIU_LAI = @('queue', 'phien-ban.txt', 'tesseract', 'create-listing',
             '.git', 'CAI-DAT.bat')

# ---------------------------------------------------------------------
#   HAI CHUONG TRINH PHU: khong nam trong ban tai ve nua
#
#   Truoc day ban tai ve keo theo ca bo cai Tesseract (55 MB) va
#   AutoHotkey (3 MB) -> moi lan cap nhat deu tai lai 59 MB cho mot vai
#   dong code doi. Gio ban tai ve con khoang 100 KB, hai cai kia chi tai
#   khi may THUC SU thieu.
#
#   Tesseract lay tu chinh repo nay, GHIM VAO MA COMMIT chu khong phai ten
#   nhanh. Ghim vao commit thi file do nam yen mai mai, du sau nay nhanh
#   main co xoa no di. (Ghim vao tag v1 cung duoc, nhung tag phai duoc day
#   len truoc; ghim commit thi khong phu thuoc thu tu lam gi.)
#   Da do that: raw.githubusercontent tra ve du file 55 MB, con do duoc
#   tung doan, va noi dung trung hash voi ban tren dia.
#   AutoHotkey lay tu trang chu - cung da do, 200 OK, 3.426.108 byte.
#
#   Muon tai tay thi xem  _he-thong\TAI-VE-TAY.txt
# ---------------------------------------------------------------------
$COMMIT_BO_CAI = 'acd1f63a41fe4c64c9a0b5d6d829cbe3217e2b0f'   # = tag v1
$TAI_TESS  = "https://raw.githubusercontent.com/$REPO/$COMMIT_BO_CAI/_he-thong/bo-cai/tesseract-portable.zip"
$TAI_AHK   = 'https://www.autohotkey.com/download/1.1/AutoHotkey_1.1.37.02_setup.exe'
$TRANG_AHK = 'https://www.autohotkey.com/download/1.1'

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

function TaiFile([string]$url, [string]$dich, [string]$nhan) {
    try {
        Write-Host "   Dang tai $nhan ..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $url -OutFile $dich `
            -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 900
        return (Test-Path $dich)
    } catch {
        Write-Host "   [ ! ] Tai khong duoc: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Tesseract xach tay: co san thi thoi, khong thi tai ve roi bung
function CaiTesseract {
    if (Test-Path (Join-Path $ThuMuc 'tesseract\tesseract.exe')) {
        Write-Host '   Da co san.'
        return $true
    }
    # May nao con giu ban nen trong thu muc thi dung luon, khoi tai lai
    $zip = Join-Path $ThuMuc '_he-thong\bo-cai\tesseract-portable.zip'
    if (-not (Test-Path $zip)) {
        $zip = Join-Path $env:TEMP 'd4l-tesseract.zip'
        if (-not (TaiFile $TAI_TESS $zip 'Tesseract (~55 MB, chi lan dau)')) { return $false }
    }
    try { Expand-Archive -Path $zip -DestinationPath $ThuMuc -Force } catch { return $false }
    Test-Path (Join-Path $ThuMuc 'tesseract\tesseract.exe')
}

function TimAHK {
    @('C:\Program Files\AutoHotkey\AutoHotkey.exe',
      'C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe',
      'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe') |
      Where-Object { Test-Path $_ } | Select-Object -First 1
}

# AutoHotkey: co roi thi thoi, khong thi tai bo cai ve va chay
function CaiAHK {
    $ahk = TimAHK
    if ($ahk) { return $ahk }

    $setup = Join-Path $ThuMuc '_he-thong\bo-cai\AutoHotkey_1.1.37.02_setup.exe'
    if (-not (Test-Path $setup)) {
        $setup = Join-Path $env:TEMP 'd4l-ahk-setup.exe'
        if (-not (TaiFile $TAI_AHK $setup 'AutoHotkey 1.1 (~3 MB)')) { return $null }
    }

    # Thu cai im lang truoc. Bo cai cua AutoHotkey la mot script AHK da bien
    # dich, noi dung nen, khong soi duoc no co nhan /S hay khong -> thu mot
    # cai, khong an thi MO CUA SO ra cho bam tay. Duong nao cung xong.
    Write-Host '   Chua co. Dang cai AutoHotkey...' -ForegroundColor Yellow
    try { Start-Process $setup -ArgumentList '/S' -Wait } catch {}
    $ahk = TimAHK
    if ($ahk) { return $ahk }

    Write-Host '   Bo cai vua mo ra - bam  Express Installation.' -ForegroundColor Yellow
    try { Start-Process $setup -Wait } catch {}
    TimAHK
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
Write-Host '[ 2/4 ] Kiem tra Tesseract (doc chu trong anh)...' -ForegroundColor Cyan
if (CaiTesseract) { Write-Host '   Xong.' }
else {
    Write-Host '   [ ! ] Khong cai duoc - tool van chay, chi la khong co phan' -ForegroundColor Yellow
    Write-Host '         doc chu (phai bam SCAN roi tu sua so bang tay).' -ForegroundColor Yellow
    Write-Host "         Muon cai tay: $TAI_TESS"
}

Write-Host ''
Write-Host '[ 3/4 ] Kiem tra AutoHotkey...' -ForegroundColor Cyan
$ahk = CaiAHK
if ($ahk) { Write-Host '   Xong.' }
else {
    Write-Host '   [ LOI ] Chua co AutoHotkey thi khong chay duoc.' -ForegroundColor Red
    Write-Host '   Tai o day roi cai, xong chay lai file nay:' -ForegroundColor Yellow
    Write-Host "     $TRANG_AHK"
    try { Start-Process $TRANG_AHK } catch {}
    Read-Host 'Enter de thoat'; exit 1
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
