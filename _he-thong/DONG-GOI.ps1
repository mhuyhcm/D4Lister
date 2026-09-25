# =====================================================================
#   DONG GOI D4Lister thanh mot file .zip de danh tren may
#
#   De lam gi: ban tren GitHub la nhanh main, no doi theo tung commit.
#   File nay dong bang mot ban CHOT lai, de khi can bung ra dung ngay —
#   khong phu thuoc mang, khong phu thuoc repo con song hay khong.
#
#   Cach dung:  bam dup DONG-GOI.cmd   (hoac chay file .ps1 nay)
#   Ket qua  :  _ban-phat-hanh\D4Lister-v<so>.zip
#
#   CHI dong nhung thu can de CHAY. Khong dong:
#     queue\            hang doi cua rieng may nay
#     create-listing\   ban luu DOM cua diablo.trade, 88 MB, chi de tra cuu
#     _bai-thu\         bai thu luc phat trien
#     _bo-nho\          ghi chu rieng
#     quet.ini          lua chon quet cua rieng may nay
#     nhat-ky-quet.txt  so ghi cac luot quet
#     .git\             lich su
# =====================================================================
$ErrorActionPreference = 'Stop'
chcp 65001 > $null

$Goc = Split-Path -Parent $PSScriptRoot
Set-Location $Goc

function Loi($m) { Write-Host "  [ LOI ] $m" -ForegroundColor Red; exit 1 }
function Xong($m) { Write-Host "  $m" -ForegroundColor Green }

Write-Host ''
Write-Host '  ================================================'
Write-Host '    DONG GOI D4Lister'
Write-Host '  ================================================'
Write-Host ''

# --- Lay so hieu ban tu chinh ma nguon, khong go tay ---------------
$ahk = Get-Content 'D4Lister.ahk' -TotalCount 5 -Encoding UTF8
$m = [regex]::Match(($ahk -join "`n"), 'D4Lister\s+(v[\d.]+)')
if (-not $m.Success) { Loi 'Khong doc duoc so hieu ban trong D4Lister.ahk' }
$Ban = $m.Groups[1].Value

$mf = Get-Content 'extension\manifest.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$BanExt = $mf.version

# So ban trong manifest phai khop const BAN trong d4lister.js. Lech thi
# trinh duyet chay mot ban ma bao mot ban khac.
$js = Get-Content 'extension\d4lister.js' -Raw -Encoding UTF8
$mj = [regex]::Match($js, "const BAN = '([\d.]+)'")
if (-not $mj.Success) { Loi 'Khong doc duoc const BAN trong d4lister.js' }
if ($mj.Groups[1].Value -ne $BanExt) {
    Loi "So ban lech: manifest.json = $BanExt nhung d4lister.js = $($mj.Groups[1].Value)"
}

# Bay 30. "global X := 5" dat SAU cai return cua khoi tu chay thi phep gan
# khong bao gio chay, nhung AHK van nhan ten bien - no rong mot cach lang
# le, khong loi, khong bao. Da dinh hai lan: mot lan moi o quet thanh "o
# nao cung co do", mot lan bang dat gia hien len roi tat ngay.
$ahk = (Get-Content 'D4Lister.ahk' -Raw -Encoding UTF8) -replace "`r`n", "`n"
$dong = $ahk -split "`n"
$viTriReturn = -1
for ($i = 0; $i -lt $dong.Count; $i++) {
    if ($dong[$i].TrimEnd() -eq 'return') { $viTriReturn = $i; break }
}
if ($viTriReturn -lt 0) { Loi 'Khong thay return cua khoi tu chay trong D4Lister.ahk' }
$xau = @()
for ($i = $viTriReturn + 1; $i -lt $dong.Count; $i++) {
    $m = [regex]::Match($dong[$i], '^global\s+([A-Za-z_]\w*)\s*:=')
    if ($m.Success) { $xau += "dong $($i + 1): $($m.Groups[1].Value)" }
}
if ($xau.Count) {
    Loi ("Bien gan sau return cua khoi tu chay (se rong luc chay): " + ($xau -join '; '))
}

Write-Host "    D4Lister $Ban  -  tien ich $BanExt"
Write-Host ''

# --- Nhung thu can de chay -----------------------------------------
$CanCo = @(
    'D4Lister.ahk'
    'CAI-DAT.bat'
    'README.md'
    '.gitattributes'
)
$ThuMuc = @('extension', '_he-thong')

foreach ($f in $CanCo) {
    if (-not (Test-Path $f)) { Loi "Thieu file: $f" }
}
foreach ($d in $ThuMuc) {
    if (-not (Test-Path $d)) { Loi "Thieu thu muc: $d" }
}

# Nhat ky: ten file doi theo tung ban nen tim thay gi lay nay
$NhatKy = Get-ChildItem -Filter 'NHAT-KY*.md' -File | ForEach-Object { $_.Name }
$YTuong = Get-ChildItem -Filter 'Y-TUONG-*.md' -File | ForEach-Object { $_.Name }

# --- Don cho tam ----------------------------------------------------
$Tam = Join-Path $env:TEMP "d4lister-donggoi-$(Get-Random)"
$Trong = Join-Path $Tam "D4Lister-$Ban"
New-Item -ItemType Directory -Path $Trong -Force | Out-Null

foreach ($f in ($CanCo + $NhatKy + $YTuong)) {
    Copy-Item $f -Destination $Trong
}
foreach ($d in $ThuMuc) {
    Copy-Item $d -Destination $Trong -Recurse
}

# queue\ phai CO nhung phai RONG: thieu no thi lan chay dau bao loi
New-Item -ItemType Directory -Path (Join-Path $Trong 'queue') -Force | Out-Null
Set-Content -Path (Join-Path $Trong 'queue\_de-trong.txt') -Encoding UTF8 `
    -Value 'Thu muc nay de trong. D4Lister ghi chu cua tung mon vao day.'

# --- Nen -------------------------------------------------------------
$Ra = Join-Path $Goc '_ban-phat-hanh'
New-Item -ItemType Directory -Path $Ra -Force | Out-Null
$Zip = Join-Path $Ra "D4Lister-$Ban.zip"
if (Test-Path $Zip) { Remove-Item $Zip -Force }

# Tu dat ten tung muc, khong dung Compress-Archive cung khong dung
# ZipFile.CreateFromDirectory: tren PowerShell 5.1 (chay .NET Framework)
# CA HAI deu ghi dau phan cach la GACH CHEO NGUOC vao trong zip, trong khi
# chuan zip quy dinh gach cheo xuoi. Explorer va 7-Zip van mo duoc, nhung
# co chuong trinh giai nen bung ra thanh mot dong file ten
# "D4Lister-v4\D4Lister.ahk" nam chung mot cho, khong co thu muc nao.
Add-Type -AssemblyName System.IO.Compression           # ZipArchive
Add-Type -AssemblyName System.IO.Compression.FileSystem # ZipFileExtensions
$fs = [System.IO.File]::Open($Zip, [System.IO.FileMode]::Create)
$za = New-Object System.IO.Compression.ZipArchive($fs, 'Create')
foreach ($f in (Get-ChildItem $Tam -Recurse -File | Sort-Object FullName)) {
    $ten = $f.FullName.Substring($Tam.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $za, $f.FullName, $ten,
        [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
}
$za.Dispose()
$fs.Dispose()

# --- Kiem lai ban vua nen, khong tin suong ---------------------------
$z = [System.IO.Compression.ZipFile]::OpenRead($Zip)
$ds = $z.Entries | ForEach-Object { $_.FullName }
$soFile = ($z.Entries | Where-Object { $_.Name -ne '' }).Count
$z.Dispose()

$PhaiCo = @(
    "D4Lister-$Ban/D4Lister.ahk"
    "D4Lister-$Ban/extension/d4lister.js"
    "D4Lister-$Ban/extension/affix-list.js"
    "D4Lister-$Ban/extension/manifest.json"
    "D4Lister-$Ban/_he-thong/CAI-TTS.cmd"
    "D4Lister-$Ban/_he-thong/CAI-TTS.ps1"
    "D4Lister-$Ban/CAI-DAT.bat"
)
$thieu = $PhaiCo | Where-Object { $ds -notcontains $_ }
if ($thieu) { Loi "Goi thieu: $($thieu -join ', ')" }

# Bo cai AutoHotkey di kem hay khong — thu muc _he-thong\bo-cai\ nam ngoai
# repo (bi .gitignore) nen may nao co thi dong kem, khong co thi thoi.
$coBoCai = [bool]($ds | Where-Object { $_ -like '*bo-cai/*setup.exe' })

# Khong duoc lot thu rieng tu vao goi
$CamCo = @('create-listing/', '_bai-thu/', '_bo-nho/', 'quet.ini',
           'nhat-ky-quet.txt', '.pem')
$lot = @()
foreach ($c in $CamCo) {
    $lot += $ds | Where-Object { $_ -like "*$c*" }
}
if ($lot) { Loi "Goi co thu khong duoc dong: $($lot -join ', ')" }

Remove-Item $Tam -Recurse -Force

# --- Ban sao mang ten CO DINH ---------------------------------------
# So hieu ban khong xep theo thu tu chu duoc: v4.1.2 dung TRUOC v4.2,
# v4.3, v4.4. Mo thu muc lay file duoi cung la cam phai ban CU. Da dinh
# that (25/09/2026): goi moi co tien ich 9.5 nam dau danh sach, con
# D4Lister-v4.4.zip voi tien ich 7.9 nam cuoi, nhin nhu moi nhat.
#
# Nen luon de mot ban sao ten co dinh. Can ban nao thi lay dung ban do,
# khong phai doan qua ten.
$ZipMoi = Join-Path $Ra 'D4Lister-MOI-NHAT.zip'
Copy-Item $Zip -Destination $ZipMoi -Force
Set-Content -Path (Join-Path $Ra 'MOI-NHAT.txt') -Encoding UTF8 -Value @(
    "Ban moi nhat: D4Lister-$Ban   (tien ich $BanExt)"
    "Dong luc    : $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    ''
    'D4Lister-MOI-NHAT.zip la ban sao cua chinh no.'
    'Dung lay file duoi cung trong thu muc: so hieu ban KHONG xep theo'
    'thu tu chu (v4.1.2 dung truoc v4.2), nen file duoi cung thuong la'
    'ban CU nhat chu khong phai moi nhat.'
)

$mb = [math]::Round((Get-Item $Zip).Length / 1MB, 2)
Write-Host ''
Xong "Xong: _ban-phat-hanh\D4Lister-$Ban.zip   ($mb MB, $soFile file)"
Xong "      va ban sao  D4Lister-MOI-NHAT.zip"

# Canh bao neu con zip nao XEP SAU ban vua dong — de khoi cam nham.
$xepSau = Get-ChildItem $Ra -Filter 'D4Lister-v*.zip' -File |
    Where-Object { $_.Name -gt "D4Lister-$Ban.zip" } |
    ForEach-Object { $_.Name }
if ($xepSau) {
    Write-Host ''
    Write-Host '    [ LUU Y ] Mo thu muc ra, may zip nay nam DUOI ban vua dong' -ForegroundColor Yellow
    Write-Host "             nhung deu CU hon: $($xepSau -join ', ')" -ForegroundColor Yellow
    Write-Host '             Lay D4Lister-MOI-NHAT.zip cho chac.' -ForegroundColor Yellow
}
if ($coBoCai) {
    Write-Host ''
    Write-Host '    Trong do 3,3 MB la bo cai AutoHotkey di kem. Doi lai: bung'
    Write-Host '    ra la chay duoc ngay tren may trang, khong can mang.'
}
Write-Host ''
Write-Host '    Bung ra dung: gia nen ra dau cung duoc, roi bam dup'
Write-Host '    D4Lister.ahk. May chua co AutoHotkey thi chay CAI-DAT.bat.'
Write-Host '    Lan dau con phai chay _he-thong\CAI-TTS.cmd mot lan.'
Write-Host ''
