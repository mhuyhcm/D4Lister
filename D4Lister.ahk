;=====================================================================
;   D4Lister v3  -  Hỗ trợ đăng item Diablo 4 lên diablo.trade
;   AutoHotkey v1  |  File độc lập, không #Include gì, chạy được trên máy khác
;
;   TRONG GAME:
;     F3          Lấy món đang rê chuột  (đọc thẳng chữ của game, KHÔNG chụp)
;
;   TRÊN TRÌNH DUYỆT:
;     F4          Dán item hiện tại (thay cho Ctrl+V)
;     F5          Sang item kế tiếp
;     F6          Lùi về item trước đó
;
;   KHÁC:
;     F9               Xóa sạch hàng đợi
;     Ctrl+Shift+F11   Nạp lại script (và kiểm tra bản mới)
;     Ctrl+Shift+F12   Thoát script (hoặc chuột phải vào icon khay hệ thống)
;=====================================================================
;   V3 BỎ HẲN CHỤP ẢNH VÀ OCR
;
;   Diablo 4 có sẵn chức năng đọc item thành lời cho người khiếm thị. Blizzard
;   đóng sẵn Tolk.dll trong thư mục game; Tolk đi tìm một "file khách" để
;   chuyển chữ sang. Ta cắm saapi64.dll vào — file đó không đọc thành tiếng,
;   nó ghi chữ ra đường ống  \\.\pipe\d4lf.
;
;   Chữ nhận được là chữ THẬT của game, nên:
;     - hết hẳn chuyện đọc nhầm số  (+2 thành 42, 196 thành 19)
;     - không kéo chọn vùng, không chờ Tesseract ~1 giây
;     - dấu Greater Affix nhận ra chắc chắn, xem khối LỌC CHỮ TTS bên dưới
;
;   CHUẨN BỊ MỘT LẦN:
;     1. Chạy  _he-thong\CAI-TTS.cmd   (chép saapi64.dll vào thư mục game)
;     2. Thoát game rồi bật lại
;     3. Trong game bật ba công tắc:
;          Options > Accessibility : Use Screen Reader
;                                    3rd Party Screen Reader
;          Options > Gameplay      : Advanced Tooltip Information
;
;   Không cần Borderless Windowed nữa — không chụp màn hình thì chế độ
;   Fullscreen độc quyền cũng chạy được.
;=====================================================================
#SingleInstance Force
#NoEnv
#Persistent
#InstallKeybdHook
#InstallMouseHook
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
SetBatchLines, -1
SetWinDelay, -1
ListLines, Off
CoordMode, Mouse, Screen

; QUAN TRỌNG: phải gọi TRƯỚC mọi thao tác cửa sổ/màn hình.
; AHK v1 mặc định KHÔNG nhận biết DPI -> khi màn hình để scale > 100%,
; Windows trả về ảnh màn hình đã bị THU NHỎ (chữ ít pixel đi) -> OCR của
; diablo.trade đọc thiếu dòng. Bật nhận biết DPI thì chụp đúng pixel thật,
; sắc nét ngang Win+Shift+S.
global g_DpiMode := EnableDpiAwareness()

;=====================================================================
;   CẤU HÌNH  -  sửa ở đây
;=====================================================================
global HK_QUET    := "F2"           ; quét hàng loạt rương + túi đồ
global HK_CAPTURE := "F3"           ; lấy món đang rê chuột
global HK_PASTE   := "F4"           ; dán item hiện tại
global HK_NEXT    := "F5"           ; sang item kế + dán luôn
global HK_PREV    := "F6"           ; lùi về item trước
global HK_CLEAR   := "F9"           ; xóa sạch hàng đợi
global HK_RELOAD  := "^+F11"        ; nạp lại script (và kiểm tra bản mới)
global HK_EXIT    := "^+F12"        ; thoát script

; Tên đường ống phải trùng với cái saapi64.dll ghi vào. Đừng đổi.
global TEN_ONG    := "\\.\pipe\d4lf"
global NHIP_ONG   := 40             ; ngó đường ống mỗi bao nhiêu mili giây

; Ghi mọi câu game gửi ra queue\_tts.log để dò khi nhận sai. Mặc định TẮT —
; rê chuột trong túi đồ là nó phình rất nhanh.
global TTS_LOG    := false

global MSG_TIME   := 1100           ; thời gian hiện tooltip (ms)
global QUEUE_DIR  := A_ScriptDir . "\queue"

; Màu tooltip: nền trắng, chữ xanh lá / đỏ / cam
global COL_BG   := "FFFFFF"
global COL_OK   := "0A8A0A"
global COL_ERR  := "C00000"
global COL_WARN := "C06000"

;=====================================================================
;   QUÉT HÀNG LOẠT  (F2)
;
;   F3 vẫn giữ nguyên: lấy đúng món đang rê chuột. F2 là đường khác —
;   tự rê qua từng ô rương và túi đồ, món nào có thì đưa vào hàng đợi.
;
;   CÁCH LÀM lấy theo D4LF (đã đọc mã nguồn của họ): rê chuột qua tâm
;   từng ô, game gửi tooltip ra đường ống, ô trống thì game im lặng.
;   Khác D4LF một chỗ: họ chụp màn hình để biết ô nào có đồ; V3 đã bỏ hết
;   bộ xử lý ảnh nên ta rê hết mọi ô, ô nào im thì bỏ qua.
;
;   TOẠ ĐỘ — ĐO THẬT trên ảnh chụp ngày 24/09/2026, không dùng công thức
;   quy đổi của D4LF. Đo bằng cách dò các đường kẻ của lưới:
;
;       RƯƠNG   11 đường dọc  x = 42 .. 623   cách đều 58,1
;                6 đường ngang y = 279 .. 740  cách đều 92,2
;       TÚI ĐỒ  x = 1301, ô rộng 52,4  ·  y = 709, ô cao 77,0
;       TAB     dải căn giữa quanh x = 332,5, mỗi ô rộng 59,1, y = 185
;
;   Riêng dải tab thì công thức của D4LF SAI: họ giãn 63 px trong khi
;   thực tế 59,1 — tab ở hai đầu lệch tới 12-13 px mà ô tab chỉ rộng 53.
;   Bấm hụt ra ngoài panel là bấm vào thế giới, nhân vật chạy đi.
;
;   Mọi số dưới đây là TOẠ ĐỘ TRONG VÙNG VẼ của cửa sổ game, không phải
;   toạ độ màn hình. Góc của vùng vẽ đọc lúc chạy — kéo cửa sổ đi chỗ
;   khác thì mọi thứ vẫn đúng.
;=====================================================================

; --- lưới rương: 5 hàng × 10 cột ---
global RUONG_X    := 42
global RUONG_Y    := 256        ; 279 trên màn hình − 23 của thanh tiêu đề
global RUONG_OW   := 58.1
global RUONG_OH   := 92.2
global RUONG_COT  := 10
global RUONG_HANG := 5

; --- lưới túi đồ: 3 hàng × 11 cột ---
global TUI_X    := 1301
global TUI_Y    := 686
global TUI_OW   := 52.4
global TUI_OH   := 77.0
global TUI_COT  := 11
global TUI_HANG := 3

; --- dải tab: căn giữa, số tab đổi được ở menu khay ---
global TAB_GIUA := 332.5
global TAB_RONG := 59.1
global TAB_Y    := 162          ; 185 − 23

; --- nhịp ---
global CHO_O_MS   := 160        ; chờ tooltip tối đa bao lâu mỗi ô
global CHO_TAB_MS := 400        ; chờ sau khi bấm đổi tab
global LECH_CHUOT := 8          ; con trỏ lệch quá ngần này px = người dùng động vào

; --- vùng vẽ mong đợi. Khác thì dừng, vì mọi toạ độ trên đo ở cỡ này ---
global CLIENT_W := 1920
global CLIENT_H := 1027

global g_DangQuet := false
global FILE_CAU_HINH := A_ScriptDir . "\quet.ini"

;=====================================================================
;   BIẾN TOÀN CỤC
;=====================================================================
global g_Items   := []      ; danh sách file .txt trong hàng đợi
global g_Cur     := 0       ; vị trí item đang chọn (1-based)
global g_Busy    := false
global g_MsgHwnd := 0

; Vừa lấy xong thì phím đầu tiên bấm sau đó (F4 / F5 / F6) sẽ nhảy về ĐẦU
; đợt vừa lấy, thay vì đứng ở món cuối. Sang trình duyệt bấm F4 là dán đúng
; món đầu tiên.
global g_FreshCapture := false
global g_BatchStart   := 1

; --- đường ống TTS ---
global g_Pipe    := 0
global g_Dem     := []      ; bộ đệm câu đang gom cho món hiện tại
global g_MonCuoi := ""      ; món vừa rê chuột qua gần nhất, chưa bấm F3
global g_TenCuoi := ""
global g_MonDaLay := ""     ; món vừa bấm F3 — chặn bấm hai lần ra hai bản
global g_DaNoi   := false   ; game đã nối vào đường ống chưa
global g_LanThuOng := 0     ; lần gần nhất thử dựng đường ống (A_TickCount)

; --- quét hàng loạt (F2) ---
global g_SoTab   := 7       ; rương có mấy tab — chọn trong hộp thoại F2
global g_QuetTui := true    ; có quét cả túi đồ nhân vật không
global g_Tab     := []      ; g_Tab[i] = có quét tab i không
global g_DaQuet  := []      ; nội dung các món đã lấy trong lượt quét này
global g_TraLoi  := ""      ; hộp thoại F2 trả về: "" chưa chọn / quet / huy

; Đếm số món LIÊN TIẾP mà mọi dòng chỉ số đều không có khoảng [min - max].
; Chạm ngưỡng là gần như chắc chắn công tắc Advanced Tooltip Information
; đang tắt — xem khối CHỐT KIỂM trong LocMonTTS().
global g_NghiTatTooltip := 0
global NGHI_TOI_DA      := 3

; --- hằng số Win32 cho đường ống ---
global PIPE_ACCESS_DUPLEX    := 0x00000003
global PIPE_TYPE_MESSAGE     := 0x00000004
global PIPE_READMODE_MESSAGE := 0x00000002
global PIPE_NOWAIT           := 0x00000001
global INVALID_HANDLE_VALUE  := -1
global ERROR_PIPE_BUSY       := 231
global ERROR_BROKEN_PIPE     := 109

;=====================================================================
;   KHỞI ĐỘNG
;=====================================================================
Menu, Tray, Icon, C:\WINDOWS\system32\shell32.dll, 44
Menu, Tray, Tip, D4Lister v3 - F3 lay mon / F4 dan / F5-F6 chuyen

if !FileExist(QUEUE_DIR)
    FileCreateDir, %QUEUE_DIR%

daDonQueueCu := DonQueueCu()

LoadQueue()

NapCauHinhQuet()

Hotkey, %HK_QUET%,    DoQuet
Hotkey, %HK_CAPTURE%, DoCapture
Hotkey, %HK_PASTE%,   DoPaste
Hotkey, %HK_NEXT%,    DoNext
Hotkey, %HK_PREV%,    DoPrev
Hotkey, %HK_CLEAR%,   DoClear
Hotkey, %HK_RELOAD%,  DoReload
Hotkey, %HK_EXIT%,    DoExit

; Dựng đường ống NGAY, kể cả khi game chưa bật. Game bật sau sẽ tự nối vào.
;
; Dựng HỤT không phải là hết chuyện. Bấm Ctrl+Shift+F11 nạp lại script thì
; bản mới khởi động trong lúc bản cũ chưa kịp chết, mà đường ống chỉ cho một
; mối nối — bản mới dựng hụt, rồi bản cũ chết, thế là chẳng còn đường ống nào.
; Vì vậy đồng hồ dưới đây vẫn chạy và cứ mỗi giây thử dựng lại một lần.
canhBao := ""
if (!MoOng())
{
    if (A_LastError = ERROR_PIPE_BUSY)
        canhBao := "`nĐường ống đang bận — sẽ tự thử lại"
    else
        canhBao := "`nChưa dựng được đường ống (mã " . A_LastError . ") — sẽ tự thử lại"
}
SetTimer, DocOng, %NHIP_ONG%

if (daDonQueueCu)
    ShowMsg("Đã dọn hàng đợi cũ của bản chụp ảnh" . canhBao, "warn")
else if (g_Items.Length() > 0)
    ShowMsg("D4Lister v3 — " . g_Items.Length() . " item trong hàng đợi" . canhBao, "warn")
else if (canhBao != "")
    ShowMsg("D4Lister v3" . canhBao, "err")
else
    ShowMsg("D4Lister v3 sẵn sàng", "ok")

; Kiểm tra bản mới, nhưng để script chạy được ngay đã rồi mới đi hỏi mạng.
SetTimer, KiemTraCapNhat, -800
return

;=====================================================================
;   HOTKEY: F3  -  LẤY MÓN ĐANG RÊ CHUỘT
;
;   Đường ống chạy suốt ở nền và luôn giữ sẵn món vừa rê chuột qua, nên F3
;   chỉ là lệnh "lấy cái đang giữ". Gần như tức thì: không kéo chọn vùng,
;   không chụp, không chờ đọc chữ.
;=====================================================================
DoCapture:
    if (g_Busy)
        return
    g_Busy := true
    ; Quét lại thư mục TRƯỚC khi lấy: nếu vừa bấm F9 xóa sạch thì món tiếp
    ; theo phải là "item 1/1" chứ không đếm tiếp từ con số cũ trong bộ nhớ.
    RefreshForCapture()
    HideMsgNow()

    ; Vét ống NGAY, khỏi chờ nhịp đồng hồ kế tiếp.
    ; Và nếu đang dở một tooltip (đã nhận được vài câu nhưng chưa tới câu
    ; kết) thì đợi nốt, tối đa 250 ms. Bấm F3 ngay khi vừa rê tới món mới
    ; mà lấy luôn thì ra món TRƯỚC ĐÓ — đúng cái sai bạn gặp.
    ; Tắt đồng hồ trong lúc này để hai bên không cùng đọc một đường ống.
    SetTimer, DocOng, Off
    VetOng()
    Loop, 10
    {
        if (g_Dem.Length() = 0)
            break
        Sleep, 25
        VetOng()
    }
    SetTimer, DocOng, %NHIP_ONG%

    if (g_MonCuoi = "")
    {
        g_Busy := false
        ; Ba chuyện khác hẳn nhau, đừng gộp một câu:
        ;   chưa cầm được ống  -> lỗi phía script này
        ;   cầm rồi mà game chưa nối -> thiếu saapi64.dll hoặc chưa bật công tắc
        ;   nối rồi mà chưa có món -> chỉ là chưa rê chuột
        if (g_Pipe = 0 || g_Pipe = INVALID_HANDLE_VALUE)
            ShowMsg("Chưa dựng được đường ống — D4LF có đang chạy không?", "err")
        else if (!g_DaNoi)
            ShowMsg("Game chưa nối vào đường ống — xem _he-thong\CAI-TTS.cmd", "err")
        else
            ShowMsg("Chưa rê chuột lên món nào", "err")
        return
    }
    if (g_MonCuoi = g_MonDaLay)
    {
        g_Busy := false
        ShowMsg("Món này lấy rồi — rê sang món khác", "warn")
        return
    }

    chu := LocMonTTS(g_MonCuoi)
    if (chu = "")
    {
        g_Busy := false
        ShowMsg("Không đọc ra chỉ số nào từ món này", "err")
        return
    }

    outFile := QUEUE_DIR . "\" . SoTiepTheo() . ".txt"
    FileDelete, %outFile%
    ; UTF-8-RAW chứ không phải UTF-8: bản có đuôi -RAW không đặt BOM.
    ; Đặt BOM thì ba byte EF BB BF dính liền vào TÊN MÓN ở dòng đầu, lúc F4
    ; đọc lại là tên hoá ra "﻿GALVANIC AZURITE" — tiện ích đem tên đó
    ; đi gõ vào ô tìm của trang thì không ra món nào.
    FileAppend, %chu%, %outFile%, UTF-8-RAW
    if !FileExist(outFile)
    {
        g_Busy := false
        ShowMsg("Không ghi được vào hàng đợi", "err")
        return
    }

    ; Món đầu tiên của một đợt mới -> ghi nhớ vị trí bắt đầu đợt
    if (!g_FreshCapture)
        g_BatchStart := g_Items.Length() + 1

    g_Items.Push(outFile)
    g_Cur := g_Items.Length()
    g_FreshCapture := true
    g_MonDaLay := g_MonCuoi

    if (!DatClipboard(chu))
    {
        g_Busy := false
        ShowMsg("Đã lưu item " . g_Cur . " nhưng LỖI COPY — bấm F5 rồi F6", "err")
        return
    }

    g_Busy := false

    ; Nghi công tắc Advanced Tooltip Information đang tắt thì nói ngay, và
    ; nói TO. Lúc này chữ vẫn lấy được bình thường, chỉ riêng dấu sao là
    ; không đáng tin — nên tiện ích đã được bảo là đừng đụng vào dấu sao.
    if (g_NghiTatTooltip >= NGHI_TOI_DA)
    {
        ShowMsg(g_Cur . "/" . g_Items.Length() . "  " . g_TenCuoi
            . "`n⚠ " . g_NghiTatTooltip . " món liên tiếp không có khoảng [min - max]"
            . "`nBật Options > Gameplay > Advanced Tooltip Information"
            . "`nDấu sao đang KHÔNG được đặt — dễ khai sai khi bán", "err")
        return
    }
    ShowMsg(g_Cur . "/" . g_Items.Length() . "  " . g_TenCuoi, "ok")
return

DoPaste:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item", "err")
        return
    }
    ; Vừa chụp xong -> lần dán đầu tiên phải về món đầu của đợt chụp
    if (g_FreshCapture)
    {
        g_Cur := g_BatchStart
        g_FreshCapture := false
    }
    if (g_Cur < 1 || g_Cur > g_Items.Length())
        g_Cur := 1

    ; Nạp lại clipboard ngay trước khi dán -> luôn dán đúng item đang chọn,
    ; kể cả khi clipboard bị chương trình khác ghi đè.
    if (!DatClipboardTuFile(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F5 rồi F6 để nạp lại", "err")
        return
    }
    Sleep, 80
    SendInput, ^v
    ShowMsg(g_Cur . "/" . g_Items.Length() . "  ▸", "ok")
return

;=====================================================================
;   HOTKEY: F5 / F6  CHUYỂN ITEM
;=====================================================================
DoNext:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item", "err")
        return
    }
    if (g_FreshCapture)
    {
        GoToBatchStart()
        return
    }
    if (g_Cur >= g_Items.Length())
    {
        ShowMsg("cuối  " . g_Cur . "/" . g_Items.Length(), "warn")
        return
    }
    g_Cur += 1
    if (!DatClipboardTuFile(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F5 lại lần nữa", "err")
        return
    }
    ; Sang món kế là DÁN LUÔN. Đăng xong một món chỉ cần bấm đúng phím này.
    Sleep, 80
    SendInput, ^v
    ShowMsg(g_Cur . "/" . g_Items.Length() . "  ▸", "ok")
return

DoPrev:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item", "err")
        return
    }
    if (g_FreshCapture)
    {
        GoToBatchStart()
        return
    }
    if (g_Cur <= 1)
    {
        ShowMsg("đầu  1/" . g_Items.Length(), "warn")
        return
    }
    g_Cur -= 1
    if (!DatClipboardTuFile(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F6 lại lần nữa", "err")
        return
    }
    ShowMsg(g_Cur . "/" . g_Items.Length(), "ok")
return

;=====================================================================
;   HOTKEY: F9 - XÓA SẠCH HÀNG ĐỢI
;=====================================================================
DoClear:
    ; Xóa THẲNG mọi file trong thư mục, không chỉ những file đang có trong
    ; bộ nhớ. Xóa cả .txt đi kèm, nếu không lần chụp sau sẽ nhặt phải chữ cũ.
    n := 0
    Loop, %QUEUE_DIR%\*.txt
    {
        FileDelete, % A_LoopFileFullPath
        if (!ErrorLevel)
            n++
    }
    FileDelete, % QUEUE_DIR . "\_tts.log"

    g_Items := []
    g_Cur := 0
    g_FreshCapture := false
    g_BatchStart := 1
    g_MonDaLay := ""      ; xóa sạch rồi thì món đang rê chuột lấy lại được
    g_DaQuet := []

    if (n = 0)
        ShowMsg("Hàng đợi đã trống sẵn", "warn")
    else
        ShowMsg("Đã xóa " . n . " item", "warn")
return

DoExit:
    DongOng()
    ExitApp
return

;=====================================================================
;   HOTKEY: Ctrl+Shift+F11 - NẠP LẠI SCRIPT
;   Nạp lại cũng chạy luôn phần kiểm tra bản mới ở dưới.
;=====================================================================
DoReload:
    ShowMsg("Đang nạp lại…", "warn")
    Sleep, 400
    Reload
return

;=====================================================================
;   KIỂM TRA BẢN MỚI TRÊN GITHUB
;
;   Chạy 0,8 giây SAU khi script đã sẵn sàng, để bạn bấm phím được ngay
;   chứ không phải ngồi đợi mạng.
;
;   Máy không cài git, hoặc thư mục không phải bản tải bằng git, hoặc mất
;   mạng — đều bỏ qua im lặng, tool vẫn chạy bình thường.
;=====================================================================
KiemTraCapNhat:
    SetTimer, KiemTraCapNhat, Off
    psFile := A_ScriptDir . "\_he-thong\d4lister-nen.ps1"
    if !FileExist(psFile)
        return
    ; Thư mục có .git = đây là MÁY ĐANG SỬA CODE, dùng git để cập nhật.
    ; Tự tải bản trên mạng về đè ở đây là mất sạch việc đang làm dở.
    if FileExist(A_ScriptDir . "\.git")
        return

    RunWait, % "powershell -NoProfile -ExecutionPolicy Bypass -File """ . psFile
             . """ -Viec CapNhat -ThuMuc """ . A_ScriptDir . """", , Hide UseErrorLevel
    ma := ErrorLevel

    if (ma = 0 || ma = 3)       ; đã mới nhất, hoặc không hỏi được (mất mạng)
    {
        HideMsgNow()
        return
    }
    if (ma = 2)
    {
        ; Chrome KHÔNG tự nạp lại tiện ích cài kiểu Load unpacked. Không nhắc
        ; thì bạn vẫn đang dùng bản cũ mà tưởng đã cập nhật.
        MsgBox, 48, D4Lister — đã có bản mới
            , % "Đã tải bản mới xong.`n`nLẦN NÀY CÓ SỬA TIỆN ÍCH CHROME.`n`n"
              . "Vào chrome://extensions bấm nút xoay vòng trên ô D4Lister,`n"
              . "rồi F5 lại trang diablo.trade.`n`n"
              . "Không làm bước này thì trình duyệt vẫn chạy bản cũ."
    }
    ; Bản mới đã nằm trên đĩa nhưng script đang chạy vẫn là bản cũ -> nạp lại.
    ShowMsg("Đã tải bản mới — đang nạp lại…", "warn")
    Sleep, 1200
    Reload
return

;=====================================================================
;   NẠP LẠI HÀNG ĐỢI CỦA PHIÊN TRƯỚC
;   Lỡ tắt nhầm script thì không mất công chụp lại.
;=====================================================================
LoadQueue()
{
    RefreshQueue(true)
}

;=====================================================================
;   DỌN HÀNG ĐỢI CÒN SÓT CỦA BẢN CHỤP ẢNH
;
;   Bản cũ lưu ảnh NNN.png rồi để Tesseract đẻ ra NNN.txt nằm cạnh. Bản này
;   cũng lưu NNN.txt nhưng nội dung khác hẳn — là chữ đã lọc sẵn. Để lẫn thì
;   F4 dán ra chữ OCR thô, tiện ích đọc không ra gì.
;
;   Thấy còn .png hoặc .tsv là biết hàng đợi của bản cũ -> dọn sạch. Hàng đợi
;   vốn là thứ lấy xong dán xong là bỏ, nên dọn không mất gì.
;=====================================================================
DonQueueCu()
{
    global QUEUE_DIR
    coCu := false
    Loop, %QUEUE_DIR%\*.png
    {
        coCu := true
        break
    }
    Loop, %QUEUE_DIR%\*.tsv
    {
        coCu := true
        break
    }
    if (!coCu)
        return false
    Loop, %QUEUE_DIR%\*.*
        FileDelete, % A_LoopFileFullPath
    return true
}

;=====================================================================
;   Liệt kê file chữ trong hàng đợi, sắp xếp theo tên.
;   Tên là số thứ tự nên sắp theo tên = sắp theo thứ tự lấy.
;=====================================================================
ScanQueueFiles()
{
    global QUEUE_DIR

    list := ""
    Loop, %QUEUE_DIR%\*.txt
        list .= A_LoopFileName . "`n"

    items := []
    if (list = "")
        return items
    Sort, list
    Loop, Parse, list, `n
    {
        if (A_LoopField = "")
            continue
        items.Push(QUEUE_DIR . "\" . A_LoopField)
    }
    return items
}

;=====================================================================
;   Quét lại trước khi LẤY MÓN.
;   Chỉ cập nhật danh sách, KHÔNG đụng tới trạng thái "đầu đợt chụp".
;   Nếu thư mục đã bị xóa sạch (bấm F9 ở máy này hoặc máy kia) thì coi như
;   bắt đầu lại từ đầu -> món chụp tiếp theo là item 1/1.
;=====================================================================
RefreshForCapture()
{
    global g_Items, g_Cur, g_BatchStart, g_FreshCapture

    g_Items := ScanQueueFiles()
    if (g_Items.Length() = 0)
    {
        g_Cur := 0
        g_BatchStart := 1
        g_FreshCapture := false
    }
    else if (g_Cur > g_Items.Length())
        g_Cur := g_Items.Length()
}

RefreshQueue(isStartup := false)
{
    global g_Items, g_Cur, g_BatchStart, g_FreshCapture

    prevCount := g_Items.Length()
    g_Items := ScanQueueFiles()

    if (isStartup)
    {
        g_Cur := g_Items.Length() ? 1 : 0
        g_BatchStart := 1
        g_FreshCapture := false
        return
    }

    ; Máy kia vừa chụp thêm -> đánh dấu là đợt mới, bắt đầu từ file đầu tiên mới
    if (g_Items.Length() > prevCount)
    {
        g_BatchStart := prevCount + 1
        g_FreshCapture := true
    }

    if (g_Cur > g_Items.Length())
        g_Cur := g_Items.Length()
    if (g_Cur < 1 && g_Items.Length() > 0)
        g_Cur := 1
}

;=====================================================================
;   BẬT NHẬN BIẾT DPI
;   Thử lần lượt từ API mới nhất xuống cũ nhất để chạy được trên mọi
;   phiên bản Windows. Trả về tên chế độ đã bật (để hiện lúc khởi động).
;=====================================================================
EnableDpiAwareness()
{
    ; DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4  (Windows 10 1703+)
    if (DllCall("SetProcessDpiAwarenessContext", "ptr", -4, "int"))
        return "Per-Monitor V2"
    ; PROCESS_PER_MONITOR_DPI_AWARE = 2  (Windows 8.1+)
    if (DllCall("Shcore\SetProcessDpiAwareness", "int", 2, "int") = 0)
        return "Per-Monitor"
    ; System DPI aware  (Windows Vista+)
    if (DllCall("SetProcessDPIAware", "int"))
        return "System"
    return "Không bật được"
}

;=====================================================================
;   VỀ MÓN ĐẦU CỦA ĐỢT VỪA LẤY
;   Gọi khi vừa lấy xong mà bấm F5 hoặc F6 — đưa con trỏ về
;   đầu đợt thay vì nhích tới/lui từ món cuối cùng vừa lấy.
;=====================================================================
GoToBatchStart()
{
    global g_Items, g_Cur, g_BatchStart, g_FreshCapture

    g_FreshCapture := false
    g_Cur := g_BatchStart
    if (g_Cur < 1 || g_Cur > g_Items.Length())
        g_Cur := 1
    if (!DatClipboardTuFile(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm lại phím vừa bấm", "err")
        return
    }
    ShowMsg("về đầu  " . g_Cur . "/" . g_Items.Length(), "ok")
}
;=====================================================================
;   TOOLTIP: nền trắng, chữ xanh lá (lỗi = đỏ, cảnh báo = cam)
;   Không cướp focus (WS_EX_NOACTIVATE) -> đang gõ giá vẫn gõ tiếp được.
;=====================================================================
ShowMsg(text, kind := "ok")
{
    global g_MsgHwnd, MSG_TIME, COL_BG, COL_OK, COL_ERR, COL_WARN

    if (kind = "err")
    {
        col := COL_ERR
        mark := "✕   "
    }
    else if (kind = "warn")
    {
        col := COL_WARN
        mark := "!   "
    }
    else
    {
        col := COL_OK
        mark := "✓   "
    }

    Gui, Msg:Destroy
    Gui, Msg:+AlwaysOnTop -Caption +ToolWindow +Border -DPIScale +E0x08000000 +LastFound
    Gui, Msg:Color, %COL_BG%
    ; Đã bật nhận biết DPI -> Windows không tự phóng to chữ nữa, phải tự nhân
    ; theo mức scale, nếu không tooltip sẽ bé tí trên màn hình scale cao.
    fs := Round(11 * A_ScreenDPI / 96)
    mg := Round(14 * A_ScreenDPI / 96)
    Gui, Msg:Margin, %mg%, % Round(10 * A_ScreenDPI / 96)
    Gui, Msg:Font, s%fs% Bold, Segoe UI
    Gui, Msg:Add, Text, c%col% BackgroundTrans, % mark . text
    g_MsgHwnd := WinExist()

    ; Hiện ngoài màn hình trước để đo kích thước -> không bị nháy hình
    Gui, Msg:Show, NA AutoSize x-32000 y-32000
    WinGetPos, , , gw, gh, ahk_id %g_MsgHwnd%

    MouseGetPos, mx, my
    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79
    px := mx + 18
    py := my + 22
    if (px + gw > vx + vw)
        px := vx + vw - gw - 4
    if (py + gh > vy + vh)
        py := my - gh - 12
    if (px < vx)
        px := vx + 4
    if (py < vy)
        py := vy + 4

    WinMove, ahk_id %g_MsgHwnd%, , %px%, %py%
    SetTimer, HideMsgTimer, % -MSG_TIME
}

HideMsgTimer:
    HideMsgNow()
return

HideMsgNow()
{
    global g_MsgHwnd
    SetTimer, HideMsgTimer, Off
    Gui, Msg:Destroy
    g_MsgHwnd := 0
}

;=====================================================================
;   ĐƯỜNG ỐNG TTS
;
;   Cấu hình lấy đúng theo D4LF (đã đọc mã nguồn của họ):
;       PIPE_ACCESS_DUPLEX
;       PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE
;       tối đa 1 mối nối, đệm 64 KB
;   Chế độ THÔNG ĐIỆP quan trọng: mỗi câu game gửi là một gói riêng, đọc ra
;   là trọn câu, khỏi phải tự đoán chỗ ngắt dòng.
;
;   Khác D4LF một chỗ: họ chạy đa luồng nên chặn chờ được; AHK một luồng nên
;   phải dùng PIPE_NOWAIT rồi ngó theo nhịp.
;
;   TÁCH MỘT MÓN  (cũng lấy theo D4LF, hàm find_item_start của họ):
;     - gom mọi câu vào bộ đệm
;     - gặp câu có "mouse button" / "action button"  ->  hết một tooltip
;     - dò NGƯỢC lên tìm dòng VIẾT HOA TOÀN BỘ (>= 3 chữ cái) -> tên món
;     - cắt từ đó tới cuối = món đồ, giữ tạm chờ bấm F3
;=====================================================================
MoOng()
{
    global
    g_Pipe := DllCall("CreateNamedPipe"
        , "str",  TEN_ONG
        , "uint", PIPE_ACCESS_DUPLEX
        , "uint", PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_NOWAIT
        , "uint", 1
        , "uint", 65536
        , "uint", 65536
        , "uint", 0
        , "ptr",  0
        , "ptr")
    if (g_Pipe = INVALID_HANDLE_VALUE || g_Pipe = 0)
        return false
    DllCall("ConnectNamedPipe", "ptr", g_Pipe, "ptr", 0)
    return true
}

DocOng:
    ; Chưa cầm được đường ống thì thử lại mỗi giây một lần, không bỏ cuộc.
    if (g_Pipe = 0 || g_Pipe = INVALID_HANDLE_VALUE)
    {
        if (A_TickCount - g_LanThuOng >= 1000)
        {
            g_LanThuOng := A_TickCount
            MoOng()
        }
        return
    }
    VetOng()
return

;   Vét cạn đường ống. Tách thành HÀM để cả đồng hồ, F3 và F2 dùng chung
;   — ba nơi đều cần đọc, mà đọc chồng nhau thì mất câu.
VetOng()
{
    global
    if (g_Pipe = 0 || g_Pipe = INVALID_HANDLE_VALUE)
        return
    ; VÉT CẠN đường ống mỗi nhịp, không phải nhấp một câu mỗi nhịp.
    ;
    ; BẪY ĐÃ SỤP MỘT LẦN: đường ống chạy ở CHẾ ĐỘ THÔNG ĐIỆP, mỗi lần
    ; ReadFile trả về ĐÚNG MỘT câu. Bản trước đọc một câu mỗi nhịp 40 ms,
    ; mà một tooltip có tới mười mấy câu — tức mất hơn nửa giây mới nuốt
    ; xong MỘT món. Rê chuột qua vài món liên tiếp là hàng đợi dồn lại vài
    ; giây: con trỏ đã sang món khác từ lâu mà F3 vẫn lấy phải món cũ.
    ; Cảm giác của người dùng đúng là "lag, copy nhầm món".
    ;
    ; Chặn 400 vòng để lỡ có gì bất thường thì cũng không treo cả script.
    VarSetCapacity(buf, 65536, 0)
    Loop, 400
    {
        doc := 0
        ok := DllCall("ReadFile", "ptr", g_Pipe, "ptr", &buf, "uint", 65535
                    , "uint*", doc, "ptr", 0)
        if (!ok || doc <= 0)
            break
        g_DaNoi := true
        NhanCau(StrGet(&buf, doc, "UTF-8"))
    }
    if (A_LastError = ERROR_BROKEN_PIPE)
    {
        ; Game thoát -> dựng lại để lần sau bật game vẫn hứng được
        g_DaNoi := false
        g_Dem := []
        DllCall("DisconnectNamedPipe", "ptr", g_Pipe)
        DllCall("ConnectNamedPipe", "ptr", g_Pipe, "ptr", 0)
    }
}

;   Dọn mấy thứ rác đã biết là có trong chữ TTS (danh sách của D4LF)
DonCau(d)
{
    for i, rac in ["&apos;", "&quot;", "[FAVORITED ITEM]. ", "[MARKED AS JUNK]. "
                 , "(Spiritborn Only)"]
        d := StrReplace(d, rac, "")
    ; Game chèn KHOẢNG TRẮNG KHÔNG NGẮT (U+00A0) vào tên món, kiểu
    ; "GALVANIC<A0>AZURITE<A0>". Trim không cắt được nó. Tiện ích Chrome thì
    ; đối chiếu tên món để biết có đang điền đúng món hay không, nên để lọt
    ; là nó từ chối điền. D4LF cũng dọn đúng ký tự này.
    d := StrReplace(d, Chr(0xA0), " ")
    return Trim(RegExReplace(d, "\s+", " "))
}

;   Dòng này có phải TÊN MÓN không: viết hoa toàn bộ, ít nhất 3 chữ cái
LaTenMon(d)
{
    for i, bo in ["COMPASS AFFIXES", "DUNGEON AFFIXES", "AFFIXES", "SELECT ALL"]
        if (InStr(d, bo))
            return false
    chu := RegExReplace(d, "[^A-Za-z]", "")
    if (StrLen(chu) < 3)
        return false
    hoa := RegExReplace(d, "[^A-Z]", "")
    return (StrLen(hoa) = StrLen(chu))
}

NhanCau(goi)
{
    global
    Loop, Parse, goi, `n, `r
    {
        d := DonCau(A_LoopField)
        if (d = "")
            continue
        if (InStr(d, "Champions who earn the favor of"))
            continue
        if (TTS_LOG)
            FileAppend, %d%`n, % QUEUE_DIR . "\_tts.log", UTF-8-RAW
        g_Dem.Push(d)

        ; Hết một tooltip chưa?
        thap := Format("{:L}", d)
        if (!InStr(thap, "mouse button") && !InStr(thap, "action button"))
            continue

        ; Dò ngược tìm tên món
        vt := 0
        Loop, % g_Dem.Length()
        {
            i := g_Dem.Length() - A_Index + 1
            if (LaTenMon(g_Dem[i]))
            {
                vt := i
                break
            }
        }
        if (vt = 0)
        {
            g_Dem := []
            continue
        }

        mon := ""
        Loop, % g_Dem.Length() - vt + 1
            mon .= g_Dem[vt + A_Index - 1] . "`n"

        ; CHỈ GIỮ LẠI. Bấm F3 mới ghi vào hàng đợi.
        g_MonCuoi := mon
        g_TenCuoi := g_Dem[vt]
        g_Dem := []
    }
}

;=====================================================================
;   LỌC CHỮ TTS  ->  chữ gửi cho tiện ích Chrome
;
;   Chữ game gửi có dạng:
;       [1] GALVANIC AZURITE               <- tên món
;       [2] Ancestral Unique Ring          <- độ hiếm + loại đồ
;       [3] 900 Item Power
;       [4] 173 All Resist (+263.2% Toughness)
;       [5] +120 Intelligence +[100 - 121]
;       [6] +3,500 Poison Resistance
;       ...
;       [n] Right mouse button
;
;   CHỖ BẮT ĐẦU KHỐI CHỈ SỐ  (lấy theo D4LF, hàm
;   _get_affix_starting_location_from_tts_section của họ):
;       vũ khí     : sau dòng "Damage Per Second" ba dòng
;                    (còn "Damage per Hit" và "Attacks per Second" xen giữa)
;       trang sức  : ngay sau dòng "All Resist"
;       khiên      : sau dòng "Armor" ba dòng
;       giáp       : ngay sau dòng "Armor"
;   Nhờ neo vào đây, mấy dòng bạn bảo không cần (Item Power, Damage Per
;   Second, Damage per Hit, Attacks per Second, All Resist) tự rụng — không
;   phải lọc bằng danh sách tên nữa.
;
;   CHỖ KẾT THÚC: gặp một trong các mốc "Empty Socket", "Requires Level",
;   "Sell Value"... (danh sách _AFFIX_STOP_MARKERS của D4LF).
;=====================================================================
;   DẤU GREATER AFFIX
;
;   Dòng nào CÓ SỐ mà KHÔNG có ngoặc [..] thì là Greater Affix.
;
;   Vì sao chắc: affix thường bị chặn cứng trong khoảng của nó nên game luôn
;   in được khoảng. Affix Greater roll ở trần rồi nhân 1.5 nên giá trị vượt
;   ra ngoài khoảng, in kèm khoảng sẽ vô lý -> game giấu khoảng đi.
;   Đọc ngược "không có khoảng = Greater" vì thế không sai được: affix
;   thường không có đường nào vượt trần để mà mất khoảng.
;
;   D4LF làm y hệt, nhánh cuối trong _AFFIX_RE của họ:
;       (?P<greateraffix2>[0-9]+[.0-9]*)(?![^\[]*\[).*
;   = một con số mà phía sau không còn dấu [ nào nữa.
;
;   Ngoại lệ duy nhất họ ghi rõ trong mã: dòng "Charm Slot" trông như
;   Greater nhưng không bao giờ là Greater.
;
;   Dòng có dấu được đánh "**" ở đầu; tiện ích Chrome đọc dấu đó rồi bật
;   công tắc Greater Affix trên form diablo.trade.
;=====================================================================
LocMonTTS(mon)
{
    ds := []
    Loop, Parse, mon, `n, `r
    {
        d := Trim(A_LoopField)
        if (d != "")
            ds.Push(d)
    }
    if (ds.Length() < 3)
        return ""

    ten  := ds[1]
    loai := ds[2]
    ra   := ten . "`n" . loai

    ; SỨC MẠNH ITEM. diablo.trade có dãy nút 10 / 120 / 330 / 540 / 750 /
    ; 800 / 850 / 900 Ancestral — tiện ích cần con số này mới bấm đúng nút.
    ; Gửi nguyên cả dòng "900 Item Power": bộ đọc của tiện ích đã có sẵn luật
    ; bỏ qua dòng này lúc dò affix, nên kèm vào không đẻ ra cảnh báo thừa.
    vtSM := ViTriDong(ds, "item power")
    if (vtSM > 0)
        ra .= "`n" . Trim(RegExReplace(RegExReplace(ds[vtSM], "\([^)]*\)", ""), "\s+", " "))

    i := ChoBatDauChiSo(ds, loai)
    soDong      := 0
    soCoSo      := 0
    soKhongNgoac := 0
    cauRieng    := ""
    while (i <= ds.Length())
    {
        d := ds[i]
        if (LaMocDung(d))
            break
        ; Câu dài nằm trong khối chỉ số chính là SỨC MẠNH RIÊNG của đồ
        ; Unique (hoặc Aspect của đồ Legendary). Nó không phải affix —
        ; diablo.trade xếp nó ở mục UNIQUE POWER riêng — nhưng vẫn có một
        ; con số phải điền, nên nhặt ra trước khi vứt dòng.
        if (cauRieng = "" && SoTu(d) > 12)
            cauRieng := d
        d := DonChiSo(d)
        if (d != "")
        {
            ra .= "`n" . d
            soDong++
            ; Đếm cho phép kiểm công tắc Advanced Tooltip Information ở dưới.
            ; Chỉ tính dòng CÓ SỐ — dòng chữ suông không nói lên điều gì.
            if (RegExMatch(d, "\d"))
            {
                soCoSo++
                if (!InStr(d, "["))
                    soKhongNgoac++
            }
        }
        i++
    }
    if (soDong = 0)
        return ""

    ; Giá trị mục UNIQUE POWER, kèm khoảng, cho tiện ích biết có phải kịch
    ; trần không. Trang mặc định đặt kịch trần lúc dựng đồ Unique, nên không
    ; gửi cái này thì món nào cũng thành 60% trong khi thật ra chỉ 44%.
    if (cauRieng != "")
    {
        rieng := SucManhRieng(cauRieng)
        if (rieng != "")
            ra .= "`n#D4L-UNIQUE:" . rieng
        ; Gửi luôn CẢ CÂU. Đồ Legendary bắt chọn Aspect thì trang mới dựng
        ; ra món, mà chữ của game KHÔNG nói tên Aspect — chỉ in mô tả. Tiện
        ; ích phải đem câu này đi dò ngược ra tên trong danh mục của trang.
        ra .= "`n#D4L-ASPECT:" . RegExReplace(cauRieng, "\s+", " ")
    }

    ; SỐ Ổ NGỌC. Dòng "Empty Socket" chính là một trong các mốc kết thúc khối
    ; chỉ số nên vòng lặp trên đã dừng lại ở đó — phải đếm riêng trên cả món.
    ;
    ; CHỈ đếm được ổ TRỐNG: ổ đã nhét ngọc thì game in ra tác dụng của viên
    ; ngọc chứ không in chữ "Empty Socket". Đếm ra 0 thì KHÔNG gửi gì, để
    ; tiện ích khỏi xoá mất lựa chọn bạn tự bấm.
    soO := 0
    for k, d in ds
        if (InStr(Format("{:L}", d), "empty socket"))
            soO++
    if (soO > 0)
        ra .= "`n#D4L-SOCKET:" . soO

    ;=================================================================
    ;   CHỐT KIỂM CÔNG TẮC "Advanced Tooltip Information"
    ;
    ;   Luật nhận dấu sao của ta là: dòng nào KHÔNG in [min - max] thì là
    ;   Greater Affix. Mà thứ in ra cái khoảng đó CHÍNH LÀ công tắc
    ;   Options > Gameplay > Advanced Tooltip Information.
    ;
    ;   Tắt công tắc đi thì game không in khoảng cho dòng nào cả, và luật
    ;   trên sẽ đóng dấu sao lên TOÀN BỘ affix — rồi đăng lên sàn sai hết,
    ;   im lặng, không ai biết. Đây là lỗi đắt nhất mà tool này có thể gây ra.
    ;
    ;   D4LF chặn bằng một phép đếm rẻ tiền (src/loot/filter.py): trên 80%
    ;   số món mà dòng nào cũng là Greater thì chắc chắn có gì đó sai.
    ;
    ;   Ta làm chặt hơn một chút: đếm số món LIÊN TIẾP mà mọi dòng có số đều
    ;   không ngoặc. Một món như vậy vẫn có thể là thật (đồ 4 sao). Nhưng ba
    ;   món liên tiếp thì không còn là may mắn nữa.
    ;
    ;   Chỉ xét món có TỪ HAI dòng chỉ số trở lên — món một dòng không nói
    ;   lên điều gì.
    ;=================================================================
    if (soCoSo >= 2 && soKhongNgoac = soCoSo)
        g_NghiTatTooltip++
    else
        g_NghiTatTooltip := 0

    ; CỜ BÁO "PHẦN DÒ DẤU SAO ĐÃ CHẠY XONG".
    ; Thiếu cờ này thì tiện ích TẮT NGẦM toàn bộ việc bật/tắt dấu sao — nó
    ; thà không đụng còn hơn xoá nhầm dấu sao trang đã nhận đúng. Bản V2 phát
    ; cờ từ hàm đo pixel; V3 bỏ hàm đó nên phải phát ở đây.
    ;
    ; ĐANG NGHI công tắc tắt thì KHÔNG phát cờ. Tiện ích sẽ để nguyên dấu sao
    ; thay vì đóng bừa lên mọi dòng — đúng công dụng cờ này sinh ra để làm.
    if (g_NghiTatTooltip < NGHI_TOI_DA)
        ra .= "`n#D4L-SAO-OK"

    ; Gửi kèm số hiệu bản tiện ích ĐANG NẰM TRÊN ĐĨA. Chrome không tự nạp
    ; lại tiện ích cài kiểu Load unpacked, nên sau khi cập nhật thì file
    ; trên đĩa là bản mới mà trình duyệt vẫn chạy bản cũ. Tiện ích so số
    ; này với số của chính nó, lệch thì tự hiện cảnh báo trên trang.
    ban := BanExtTrenDia()
    if (ban != "")
        ra .= "`n#D4L-EXT:" . ban
    return ra
}

;   Dòng chỉ số ĐẦU TIÊN nằm ở vị trí nào (1-based)
ChoBatDauChiSo(ds, loai)
{
    l := Format("{:L}", loai)

    if (InStr(l, "shield"))
    {
        vt := ViTriDong(ds, "armor")
        if (vt > 0)
            return vt + 3
    }
    if (InStr(l, "ring") || InStr(l, "amulet"))
    {
        vt := ViTriDong(ds, "all resist")
        if (vt > 0)
            return vt + 1
    }
    vt := ViTriDong(ds, "damage per second")
    if (vt > 0)
        return vt + 3
    vt := ViTriDong(ds, "armor")
    if (vt > 0)
        return vt + 1
    vt := ViTriDong(ds, "all resist")
    if (vt > 0)
        return vt + 1
    ; Loại đồ lạ: bám tạm vào dòng Item Power
    vt := ViTriDong(ds, "item power")
    return (vt > 0) ? vt + 1 : 3
}

;   Tìm dòng mà phần CHỮ của nó đúng bằng nhãn cần tìm.
;   "173 All Resist (+263.2% Toughness)" -> bỏ ngoặc, bỏ số -> "all resist"
ViTriDong(ds, nhan)
{
    Loop, % ds.Length()
    {
        d := RegExReplace(ds[A_Index], "\([^)]*\)", "")
        d := RegExReplace(d, "[^A-Za-z ]", "")
        d := Trim(RegExReplace(d, "\s+", " "))
        if (Format("{:L}", d) = nhan)
            return A_Index
    }
    return 0
}

;   Hết khối chỉ số chưa (danh sách _AFFIX_STOP_MARKERS của D4LF)
LaMocDung(d)
{
    l := Format("{:L}", d)
    for i, m in ["empty socket", "requires level", "properties lost when equipped"
               , "cannot salvage", "sell value", "durability", "tempers:"
               , "unlocks new look", "mouse button", "action button"
               , "rampage:", "feast:", "hunger:"]
        if (InStr(l, m))
            return true
    return false
}

;   Đếm số từ của một dòng.
SoTu(d)
{
    n := 0
    Loop, Parse, d, %A_Space%
        if (A_LoopField != "")
            n++
    return n
}

;   SỨC MẠNH RIÊNG của đồ Unique / Aspect của đồ Legendary.
;
;   Câu dài, trong đó có "<giá trị> ...  [min - max]", ví dụ:
;     "...and receive 44.0%[x] [40.0 - 60.0]% increased Shock damage..."
;   Biểu thức lấy đúng theo _ASPECT_RE của D4LF. Con số "4 seconds" ở đầu
;   câu không lọt được vì sau nó không có ngoặc [min - max] nào.
;
;   Trả về "44.0|40.0|60.0" — tiện ích so giá trị với trần để biết có phải
;   bật công tắc "Maxxed out Unique Power" hay không.
SucManhRieng(d)
{
    if RegExMatch(d, "([0-9]+\.?[0-9]*)[^0-9]+\[([0-9]+\.?[0-9]*) - ([0-9]+\.?[0-9]*)\]", m)
        return m1 . "|" . m2 . "|" . m3
    return ""
}

;   Dọn một dòng chỉ số. Trả về "" nếu dòng đó không phải chỉ số.
DonChiSo(d)
{
    ; Bỏ phần trong ngoặc tròn: so sánh với đồ đang mặc "(+8)", giới hạn
    ; class "(Druid Warlock Only)". diablo.trade không có ô cho mấy thứ này.
    d := Trim(RegExReplace(RegExReplace(d, "\([^)]*\)", ""), "\s+", " "))
    if (d = "")
        return ""
    if (StrLen(RegExReplace(d, "[^A-Za-z]", "")) < 3)
        return ""

    ; "Unlocks new look on salvage" / "Unlocks new Aspect in the Codex of
    ; Power and look on salvage" — ghi chú của game, không phải chỉ số.
    ; Câu thứ hai dài đúng 12 từ nên lọt qua được phép cắt câu dài.
    if (RegExMatch(Format("{:L}", d), "^unlocks\s"))
        return ""

    ; Sức mạnh riêng của đồ Unique và lời văn kể chuyện là những CÂU dài.
    ; diablo.trade xếp chúng ở mục UNIQUE POWER riêng, không phải ô affix.
    if (SoTu(d) > 12)
        return ""

    coSo    := RegExMatch(d, "\d")
    coNgoac := InStr(d, "[")
    ; "Charm Slot" trông như Greater nhưng không bao giờ là Greater (D4LF)
    laSao   := (coSo && !coNgoac && !InStr(Format("{:L}", d), "charm slot"))

    ; Bỏ dấu phẩy ngăn nghìn: 3,500 -> 3500. Chạy hai lần cho số hàng triệu.
    d := RegExReplace(d, "(\d),(\d)", "$1$2")
    d := RegExReplace(d, "(\d),(\d)", "$1$2")

    return (laSao ? "**" : "") . d
}

;=====================================================================
;   CLIPBOARD  -  V3 chỉ đặt CHỮ, không còn ảnh
;
;   Tiện ích Chrome bắt sự kiện paste rồi đọc text/plain, nó chưa bao giờ
;   dùng tới ảnh. diablo.trade cũng để ảnh là tuỳ chọn ("or scan screenshot").
;   Bỏ ảnh đi thì clipboard nhẹ hẳn — qua Parsec đồng bộ cũng nhanh hơn.
;=====================================================================
DatClipboard(chu)
{
    Clipboard := chu
    ClipWait, 1
    return !ErrorLevel
}

DatClipboardTuFile(f)
{
    if !FileExist(f)
        return false
    FileRead, chu, *P65001 %f%
    if (chu = "")
        return false
    return DatClipboard(chu)
}

;   Đọc số hiệu bản tiện ích từ extension\manifest.json
BanExtTrenDia()
{
    f := A_ScriptDir . "\extension\manifest.json"
    if !FileExist(f)
        return ""
    FileRead, j, *P65001 %f%
    if RegExMatch(j, """version""\s*:\s*""([^""]+)""", m)
        return m1
    return ""
}
;=====================================================================
;   Số thứ tự tiếp theo cho file chữ: 001, 002, ...
;=====================================================================
SoTiepTheo()
{
    global QUEUE_DIR
    n := 0
    Loop, %QUEUE_DIR%\*.txt
    {
        SplitPath, A_LoopFileName, , , , ten
        if (RegExMatch(ten, "^\d+$") && (ten + 0 > n))
            n := ten + 0
    }
    return SubStr("000" . (n + 1), -2)
}
;=====================================================================
;   GÓC VÀ CỠ CỦA VÙNG VẼ
;   Trả về false nếu không thấy cửa sổ game.
;=====================================================================
VungVe(ByRef gx, ByRef gy, ByRef rong, ByRef cao)
{
    WinGet, hwnd, ID, Diablo IV
    if (!hwnd)
        return false
    VarSetCapacity(pt, 8, 0)
    DllCall("ClientToScreen", "ptr", hwnd, "ptr", &pt)
    gx := NumGet(pt, 0, "Int")
    gy := NumGet(pt, 4, "Int")
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rc)
    rong := NumGet(rc, 8, "Int")
    cao  := NumGet(rc, 12, "Int")
    return true
}


;=====================================================================
;   QUÉT MỘT Ô
;
;   Xoá món đang giữ trước khi rê, để cái nhận được chắc chắn là của ô
;   này chứ không phải sót lại của ô trước.
;
;   Trả về: "" nếu ô trống hoặc bị huỷ, ngược lại là chữ của món.
;=====================================================================
QuetMotO(x, y, ByRef huy)
{
    global
    local het, mon

    g_MonCuoi := ""
    g_TenCuoi := ""
    g_Dem := []
    VetOng()            ; vét sạch phần còn đọng của ô trước
    g_MonCuoi := ""
    g_Dem := []

    MouseMove, %x%, %y%, 0

    het := A_TickCount + CHO_O_MS
    Loop
    {
        if (GetKeyState("Escape", "P"))
        {
            huy := "bạn bấm Esc"
            return ""
        }
        MouseGetPos, mx, my
        if (Abs(mx - x) > LECH_CHUOT || Abs(my - y) > LECH_CHUOT)
        {
            huy := "con trỏ bị động vào"
            return ""
        }
        VetOng()
        if (g_MonCuoi != "")
            break
        if (A_TickCount > het)
            return ""       ; ô trống
        Sleep, 15
    }

    ; Tooltip có thể còn đang về dở — đợi nốt một nhịp ngắn
    Sleep, 25
    VetOng()
    return g_MonCuoi
}


;=====================================================================
;   QUÉT MỘT LƯỚI
;=====================================================================
QuetLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang, ten, ByRef huy, ByRef soMoi)
{
    global
    local r, c, tx, ty, mon, chu

    r := 0
    while (r < soHang)
    {
        ; Báo tiến độ MỖI HÀNG, không phải mỗi ô: ShowMsg dựng lại cả cửa
        ; sổ GUI nên gọi 83 lần một lượt thì vừa chậm vừa nhấp nháy.
        ShowMsg(ten . " — hàng " . (r + 1) . "/" . soHang
            . "`nđã lấy " . soMoi . " món   ·   Esc để dừng", "warn")
        c := 0
        while (c < soCot)
        {
            tx := gx + Round(x0 + ow * (c + 0.5))
            ty := gy + Round(y0 + oh * (r + 0.5))
            mon := QuetMotO(tx, ty, huy)
            if (huy != "")
                return
            if (mon != "")
            {
                chu := LocMonTTS(mon)
                if (chu != "" && ThemVaoHangDoi(chu, mon))
                    soMoi++
            }
            c++
        }
        r++
    }
}


;=====================================================================
;   HOTKEY: F2  -  QUÉT HÀNG LOẠT
;=====================================================================
DoQuet:
    if (g_Busy || g_DangQuet)
        return
    HideMsgNow()

    if (g_Pipe = 0 || g_Pipe = INVALID_HANDLE_VALUE)
    {
        ShowMsg("Chưa dựng được đường ống — D4LF có đang chạy không?", "err")
        return
    }
    if (!g_DaNoi)
    {
        ShowMsg("Game chưa nối vào đường ống — xem _he-thong\CAI-TTS.cmd", "err")
        return
    }
    if (!VungVe(gx, gy, cw, ch))
    {
        ShowMsg("Không thấy cửa sổ Diablo IV", "err")
        return
    }
    if (cw != CLIENT_W || ch != CLIENT_H)
    {
        ShowMsg("Vùng vẽ của game là " . cw . "×" . ch . ", không phải "
            . CLIENT_W . "×" . CLIENT_H . "`nMọi toạ độ đo ở cỡ kia nên sẽ rê trượt ô."
            . "`nĐể game ở chế độ cửa sổ mặc định, màn hình 1920×1080.", "err")
        return
    }

    ; Hỏi quét gì NGAY lúc bấm, không bắt nhớ lần trước đã đặt ra sao.
    ; Hộp thoại mở với đúng lựa chọn của buổi trước (đọc từ quet.ini).
    g_DangQuet := true                 ; chặn F2 bấm chồng lúc hộp thoại đang mở
    if (!HoiQuetGi())
    {
        g_DangQuet := false
        return
    }

    dsTab := DocDsTab()
    if (dsTab = "" && !g_QuetTui)
    {
        ShowMsg("Chưa chọn quét gì cả", "err")
        g_DangQuet := false
        return
    }

    ; Hộp thoại vừa cướp tiêu điểm. Game không được kích hoạt thì rê chuột
    ; vào ô cũng chẳng ra tooltip, quét sẽ về tay không mà chẳng rõ vì sao.
    WinActivate, Diablo IV
    WinWaitActive, Diablo IV,, 2
    if (ErrorLevel)
    {
        ShowMsg("Không đưa được cửa sổ Diablo IV lên trước", "err")
        g_DangQuet := false
        return
    }
    Sleep, 250                         ; chờ game vẽ lại rồi mới rê

    g_Busy := true
    MouseGetPos, chuotX, chuotY
    RefreshForCapture()
    soMoi := 0
    huy := ""
    SetTimer, DocOng, Off          ; chỉ một nơi được đọc đường ống

    ; --- các tab rương ---
    Loop, Parse, dsTab, `,
    {
        if (huy != "")
            break
        i := A_LoopField + 0
        tabX := gx + Round(TAB_GIUA + TAB_RONG * (i - 1 - (g_SoTab - 1) / 2))
        tabY := gy + TAB_Y
        ShowMsg("Đổi sang tab " . i . "…", "warn")
        MouseMove, %tabX%, %tabY%, 0
        Sleep, 60
        Click
        Sleep, %CHO_TAB_MS%
        QuetLuoi(gx, gy, RUONG_X, RUONG_Y, RUONG_OW, RUONG_OH
               , RUONG_COT, RUONG_HANG, "Rương tab " . i, huy, soMoi)
    }

    ; --- túi đồ ---
    if (huy = "" && g_QuetTui)
        QuetLuoi(gx, gy, TUI_X, TUI_Y, TUI_OW, TUI_OH
               , TUI_COT, TUI_HANG, "Túi đồ", huy, soMoi)

    MouseMove, %chuotX%, %chuotY%, 0
    SetTimer, DocOng, %NHIP_ONG%
    g_Busy := false
    g_DangQuet := false

    if (huy != "")
        ShowMsg("Dừng giữa chừng (" . huy . ")`nĐã lấy được " . soMoi . " món", "warn")
    else if (soMoi = 0)
        ShowMsg("Quét xong, không tìm thấy món nào mới"
            . "`nRương đã mở chưa? Bấm F2 khi đang mở rương.", "warn")
    else
        ShowMsg("Quét xong — thêm " . soMoi . " món"
            . "`nHàng đợi: " . g_Items.Length() . " món", "ok")
return

;=====================================================================
;   THÊM MỘT MÓN VÀO HÀNG ĐỢI
;
;   Tách ra khỏi F3 để F2 dùng chung. Chống trùng bằng cách so NỘI DUNG
;   món, không phải "món cuối" như F3 — quét hàng loạt thì con trỏ đi qua
;   lại, rất dễ đọc lại một món đã có.
;=====================================================================
ThemVaoHangDoi(chu, monGoc)
{
    global

    for k, cu in g_DaQuet
        if (cu = monGoc)
            return false

    f := QUEUE_DIR . "\" . SoTiepTheo() . ".txt"
    FileDelete, %f%
    FileAppend, %chu%, %f%, UTF-8-RAW
    if !FileExist(f)
        return false

    if (!g_FreshCapture)
        g_BatchStart := g_Items.Length() + 1
    g_Items.Push(f)
    g_Cur := g_Items.Length()
    g_FreshCapture := true
    g_DaQuet.Push(monGoc)
    return true
}


;=====================================================================
;   MENU KHAY: CHỌN QUÉT GÌ
;
;   Đặt ở menu khay chứ không phải sửa mã: mỗi buổi bạn muốn quét tab
;   khác nhau. Lưu vào quet.ini cạnh script nên lần sau mở vẫn nhớ.
;=====================================================================
DocDsTab()
{
    global g_Tab
    ra := ""
    Loop, 7
        if (g_Tab[A_Index])
            ra .= (ra = "" ? "" : ",") . A_Index
    return ra
}

NapCauHinhQuet()
{
    global
    IniRead, v, %FILE_CAU_HINH%, quet, soTab, 7
    g_SoTab := (v = 6) ? 6 : 7
    IniRead, v, %FILE_CAU_HINH%, quet, tui, 1
    g_QuetTui := (v != 0)
    IniRead, dsTab, %FILE_CAU_HINH%, quet, tab, 1
    g_Tab := []
    Loop, 7
        g_Tab[A_Index] := false
    Loop, Parse, dsTab, `,
    {
        i := A_LoopField + 0
        if (i >= 1 && i <= 7)
            g_Tab[i] := true
    }
}

LuuCauHinhQuet()
{
    global
    IniWrite, % g_SoTab, %FILE_CAU_HINH%, quet, soTab
    IniWrite, % (g_QuetTui ? 1 : 0), %FILE_CAU_HINH%, quet, tui
    IniWrite, % DocDsTab(), %FILE_CAU_HINH%, quet, tab
}

;=====================================================================
;   HỘP THOẠI "QUÉT GÌ"  —  hiện lên mỗi lần bấm F2
;
;   Mỗi buổi bán một khác: hôm chỉ quét tab 1, hôm quét cả rương lẫn túi.
;   Hỏi ngay lúc bấm thì khỏi phải nhớ lần trước đã đặt gì, mà vẫn ghi vào
;   quet.ini nên mở lên là thấy sẵn lựa chọn cũ, bấm Enter là chạy.
;
;   Trả về true nếu người dùng chọn Quét.
;=====================================================================
HoiQuetGi()
{
    global
    local i, cx, cy

    g_TraLoi := ""

    Gui, hQuet:New, +AlwaysOnTop -MaximizeBox -MinimizeBox, D4Lister — quét hàng loạt
    Gui, hQuet:Font, s9, Segoe UI

    Gui, hQuet:Add, GroupBox, x10 y8 w330 h112, Rương
    Loop, 7
    {
        i  := A_Index
        cx := 24 + Mod(i - 1, 4) * 78
        cy := 32 + ((i - 1) // 4) * 28
        Gui, hQuet:Add, Checkbox
           , % "voTab" . i . " x" . cx . " y" . cy . " w70"
             . (g_Tab[i] ? " Checked" : "")
             . (i > g_SoTab ? " Disabled" : "")
           , % "Tab " . i
    }
    Gui, hQuet:Add, Text,  x24 y92 w76 h22 +0x200, Rương có:
    Gui, hQuet:Add, Radio, % "voSoTab Group x102 y92 w66 h22 gDoiSoTabQuet"
                             . (g_SoTab = 7 ? " Checked" : ""), 7 tab
    Gui, hQuet:Add, Radio, % "x172 y92 w66 h22 gDoiSoTabQuet"
                             . (g_SoTab = 6 ? " Checked" : ""), 6 tab

    Gui, hQuet:Add, Checkbox, % "voTui x16 y132 w170 h22"
                                . (g_QuetTui ? " Checked" : ""), Túi đồ nhân vật
    Gui, hQuet:Add, Button, x190 y130 w72 h26 gChonHetQuet, Chọn hết
    Gui, hQuet:Add, Button, x268 y130 w72 h26 gBoHetQuet,   Bỏ hết

    Gui, hQuet:Add, Button, x120 y170 w108 h32 +Default gBatDauQuet, Quét
    Gui, hQuet:Add, Button, x232 y170 w108 h32 gHuyQuet,             Huỷ
    Gui, hQuet:Show, w350 h214 Center

    ; Chờ người dùng bấm. Các nút chạy ở luồng riêng nên vòng chờ này
    ; không chặn gì — đồng hồ đọc đường ống vẫn tiếp tục vét như thường.
    while (g_TraLoi = "")
        Sleep, 30
    Gui, hQuet:Destroy

    if (g_TraLoi != "quet")
        return false

    g_SoTab   := (oSoTab = 1) ? 7 : 6
    g_QuetTui := (oTui != 0)
    g_Tab     := []
    Loop, 7
        g_Tab[A_Index] := (oTab%A_Index% != 0 && A_Index <= g_SoTab)
    LuuCauHinhQuet()
    return true
}

; Đổi 7↔6 tab: tab 7 phải tắt hẳn, không chỉ bỏ dấu tick — để bấm nhầm
; cũng không quét sang một tab không tồn tại.
DoiSoTabQuet:
    Gui, hQuet:Submit, NoHide
    if (oSoTab = 1)
        GuiControl, hQuet:Enable, oTab7
    else
    {
        GuiControl, hQuet:, oTab7, 0
        GuiControl, hQuet:Disable, oTab7
    }
return

ChonHetQuet:
    Gui, hQuet:Submit, NoHide
    Loop, 7
        GuiControl, hQuet:, oTab%A_Index%, % (A_Index <= ((oSoTab = 1) ? 7 : 6) ? 1 : 0)
    GuiControl, hQuet:, oTui, 1
return

BoHetQuet:
    Loop, 7
        GuiControl, hQuet:, oTab%A_Index%, 0
    GuiControl, hQuet:, oTui, 0
return

BatDauQuet:
    Gui, hQuet:Submit, NoHide
    g_TraLoi := "quet"
return

HuyQuet:
hQuetGuiClose:
hQuetGuiEscape:
    g_TraLoi := "huy"
return

;=====================================================================
;   DỌN DẸP LÚC THOÁT
;=====================================================================
DongOng()
{
    global g_Pipe, INVALID_HANDLE_VALUE
    if (g_Pipe != 0 && g_Pipe != INVALID_HANDLE_VALUE)
    {
        DllCall("DisconnectNamedPipe", "ptr", g_Pipe)
        DllCall("CloseHandle", "ptr", g_Pipe)
        g_Pipe := 0
    }
}
