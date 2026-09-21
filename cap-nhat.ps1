# =====================================================================
#   D4Lister - kiem tra & tai ban moi tu GitHub
#
#   KHONG CAN cai Git. Lay thang file .zip cua nhanh main.
#
#   Ma thoat:
#     0 = dang la ban moi nhat
#     1 = da cap nhat xong
#     2 = da cap nhat, VA co dung vao thu muc extension
#     3 = khong kiem tra duoc (mat mang, GitHub chan...) - bo qua, chay tiep
# =====================================================================
param(
    [string]$ThuMuc = $PSScriptRoot,
    [switch]$ChiKiem          # chi xem co ban moi khong, khong tai
)

$ErrorActionPreference = 'Stop'
$REPO    = 'mhuyhcm/D4Lister'
$fileSHA = Join-Path $ThuMuc 'phien-ban.txt'

# Nhung thu KHONG duoc de ban tren mang ghi de - la do cua nguoi dung
$GIU_LAI = @('queue', 'phien-ban.txt', '_cu', 'create-listing', '_anh-cu',
             'thu-nghiem', 'tesseract', '.git')

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tin = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/commits/main" `
             -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 20
    $moi = $tin.sha
} catch {
    exit 3
}

$dangCo = ''
if (Test-Path $fileSHA) { $dangCo = (Get-Content $fileSHA -Raw).Trim() }

if ($dangCo -eq $moi) { exit 0 }
if ($ChiKiem)         { exit 1 }

# --- Tai ve va bung ra ---
$tam = Join-Path $env:TEMP ('d4l_up_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $tam | Out-Null
try {
    $zip = Join-Path $tam 'main.zip'
    Invoke-WebRequest -Uri "https://github.com/$REPO/archive/refs/heads/main.zip" `
        -OutFile $zip -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 300
    Expand-Archive -Path $zip -DestinationPath $tam -Force
    $goc = Get-ChildItem $tam -Directory | Where-Object { $_.Name -like 'D4Lister-*' } |
           Select-Object -First 1
    if (-not $goc) { exit 3 }

    # Chep de, nhung chua ra nhung thu cua nguoi dung
    $dungExt = $false
    Get-ChildItem $goc.FullName -Recurse -File | ForEach-Object {
        $tuongDoi = $_.FullName.Substring($goc.FullName.Length + 1)
        $dauTien  = ($tuongDoi -split '[\\/]')[0]
        if ($GIU_LAI -contains $dauTien) { return }

        $dich = Join-Path $ThuMuc $tuongDoi
        # Chi chep khi noi dung THUC SU khac -> khong bao "da doi extension" oan
        if (Test-Path $dich) {
            $a = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            $b = (Get-FileHash $dich       -Algorithm SHA256).Hash
            if ($a -eq $b) { return }
        }
        $thuMucCha = Split-Path $dich -Parent
        if (-not (Test-Path $thuMucCha)) { New-Item -ItemType Directory -Force $thuMucCha | Out-Null }
        Copy-Item $_.FullName $dich -Force
        if ($dauTien -eq 'extension') { $dungExt = $true }
    }

    Set-Content -Path $fileSHA -Value $moi -Encoding ascii -NoNewline
    if ($dungExt) { exit 2 } else { exit 1 }
}
catch {
    exit 3
}
finally {
    Remove-Item $tam -Recurse -Force -ErrorAction SilentlyContinue
}
