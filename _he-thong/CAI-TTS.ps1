# =====================================================================
#   CAI DUONG ONG TTS CHO D4LISTER
#
#   Lam dung ba viec:
#     1. Tao mot chung chi TU KY ten "D4Lister TTS", nam trong kho CA
#        NHAN cua tai khoan Windows cua ban. KHONG dua vao kho tin cay
#        cua he thong, KHONG cap quyen tin cay cho bat cu thu gi khac.
#     2. Ky file saapi64.dll bang chung chi do. Diablo 4 chi nap DLL co
#        chu ky, du la chu ky tu tao.
#     3. Chep saapi64.dll vao thu muc cai Diablo 4. THEM mot file, KHONG
#        sua file nao cua game.
#
#   Muon huy bo: xoa saapi64.dll trong thu muc game, va xoa chung chi
#   trong certmgr.msc > Personal > Certificates.
# =====================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Buoc($n, $chu) { Write-Host ""; Write-Host "  [$n] $chu" -ForegroundColor Cyan }
function Xong($chu)     { Write-Host "      $chu" -ForegroundColor Green }
function Loi($chu)      { Write-Host "      $chu" -ForegroundColor Red }

Write-Host ""
Write-Host "  ================================================================"
Write-Host "    CAI DUONG ONG TTS CHO D4LISTER" -ForegroundColor Cyan
Write-Host "  ================================================================"

try {
    # --- 1. Tim thu muc game -----------------------------------------
    Buoc 1 "Tim thu muc Diablo 4"
    $ungVien = @('F:\Diablo IV', 'C:\Program Files (x86)\Diablo IV', 'D:\Diablo IV',
                 'E:\Diablo IV', 'C:\Diablo IV', 'G:\Diablo IV')
    $d4 = $ungVien | Where-Object { Test-Path (Join-Path $_ 'Diablo IV.exe') } | Select-Object -First 1
    if (-not $d4) {
        $d4 = (Read-Host "      Khong tu tim duoc. Go duong dan thu muc Diablo IV").Trim().Trim('"')
    }
    if (-not (Test-Path (Join-Path $d4 'Diablo IV.exe'))) {
        throw "Khong thay 'Diablo IV.exe' trong: $d4"
    }
    Xong $d4

    # Tolk.dll la thu Blizzard dong san. Khong co no thi ca huong nay vo nghia.
    $tolk = Join-Path $d4 'Tolk.dll'
    if (Test-Path $tolk) {
        Xong "Tolk.dll cua Blizzard: co san (dung nhu mong doi)"
    } else {
        Loi "Khong thay Tolk.dll - ban game nay co the khong ho tro trinh doc man hinh."
    }

    # --- 1b. Da cai roi thi thoi, va game dang chay thi khong ghi duoc ---
    #
    # File saapi64.dll do CHINH GAME nap luc khoi dong. Game con chay thi
    # Windows khoa file, chep de len se hong o buoc cuoi. Hoi truoc cho gon,
    # dung de chay het 5 buoc roi moi bao loi.
    $dich = Join-Path $d4 'saapi64.dll'
    $dangChay = Get-Process -Name 'Diablo IV' -ErrorAction SilentlyContinue

    if (Test-Path $dich) {
        $ky = Get-AuthenticodeSignature $dich
        $cuaTa = $ky.SignerCertificate -and $ky.SignerCertificate.Subject -eq 'CN=D4Lister TTS'
        Buoc '1b' "Kiem tra file da cai"
        Xong "$dich"
        Xong "$((Get-Item $dich).Length) byte, sua luc $((Get-Item $dich).LastWriteTime)"
        if ($cuaTa) {
            Xong "Da ky boi CN=D4Lister TTS - dung la ban do script nay cai."
            Write-Host "      (trang thai chu ky '$($ky.Status)' la BINH THUONG: chung chi tu ky" -ForegroundColor DarkGray
            Write-Host "       khong co goc tin cay, Windows khong dung duoc chuoi tin cay." -ForegroundColor DarkGray
            Write-Host "       Diablo 4 chi doi file CO chu ky, khong doi chu ky cua ai.)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "    => DA CAI ROI, KHONG CAN LAM GI." -ForegroundColor Green
            Write-Host ""
            $tl = Read-Host "      Van muon tai lai ban moi va cai de len? (go 'c' de cai lai, Enter de thoat)"
            if ($tl.Trim().ToLower() -ne 'c') {
                Write-Host ""
                Write-Host "    Thoat, khong dong gi toi file." -ForegroundColor Cyan
                Write-Host ""
                return
            }
        }
    }

    if ($dangChay) {
        Write-Host ""
        Loi "DIABLO 4 DANG CHAY (PID $($dangChay.Id))."
        Loi "Game giu file saapi64.dll nen khong chep de len duoc."
        Write-Host ""
        Write-Host "    Thoat han game (khong phai chi thoat ra man hinh chon nhan vat)," -ForegroundColor Yellow
        Write-Host "    roi chay lai file nay." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # --- 2. Tai DLL ---------------------------------------------------
    Buoc 2 "Tai saapi64.dll tu repo D4LF (giay phep MIT)"
    $tam = Join-Path $env:TEMP 'd4lister-saapi64.dll'
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/d4lfteam/d4lf/main/tts/saapi64.dll' `
                      -OutFile $tam -Headers @{ 'User-Agent' = 'D4Lister' } -TimeoutSec 180
    $kt = (Get-Item $tam).Length
    if ($kt -lt 50000) { throw "File tai ve qua nho ($kt byte), co ve khong phai DLL." }
    Xong "$kt byte"

    # --- 3. Chung chi tu ky -------------------------------------------
    Buoc 3 "Chuan bi chung chi tu ky"
    $ten = 'CN=D4Lister TTS'
    $cert = Get-ChildItem Cert:\CurrentUser\My |
            Where-Object { $_.Subject -eq $ten -and $_.HasPrivateKey } |
            Select-Object -First 1
    if ($cert) {
        Xong "Dung lai chung chi da co: $($cert.Thumbprint)"
    } else {
        $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $ten `
                    -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(5)
        Xong "Da tao moi: $($cert.Thumbprint)"
    }
    Write-Host "      (nam o Cert:\CurrentUser\My - kho ca nhan, khong phai kho tin cay he thong)" -ForegroundColor DarkGray

    # --- 4. Ky file ----------------------------------------------------
    Buoc 4 "Ky file"
    $kq = Set-AuthenticodeSignature -FilePath $tam -Certificate $cert -HashAlgorithm SHA256
    if ($kq.Status -ne 'Valid' -and $kq.Status -ne 'UnknownError') {
        throw "Ky that bai: $($kq.Status)"
    }
    Xong "Trang thai: $($kq.Status)"

    # --- 5. Chep vao thu muc game --------------------------------------
    Buoc 5 "Chep vao thu muc game"
    Copy-Item $tam $dich -Force
    Xong $dich

    Write-Host ""
    Write-Host "  ================================================================"
    Write-Host "    XONG. CON BA VIEC LAM TAY:" -ForegroundColor Green
    Write-Host "  ================================================================"
    Write-Host ""
    Write-Host "    1. THOAT GAME ROI BAT LAI" -ForegroundColor Yellow
    Write-Host "       (game chi nap file nay luc khoi dong)"
    Write-Host ""
    Write-Host "    2. Trong game bat ba cong tac:"
    Write-Host "         Options > Accessibility : Use Screen Reader"
    Write-Host "                                   3rd Party Screen Reader"
    Write-Host "         Options > Gameplay      : Advanced Tooltip Information"
    Write-Host ""
    Write-Host "    3. Chay  _thu-tts.ahk  roi re chuot len vai mon do"
    Write-Host ""
}
catch {
    Write-Host ""
    Loi "LOI: $($_.Exception.Message)"
    Write-Host ""
}
