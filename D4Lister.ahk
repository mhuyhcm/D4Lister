;=====================================================================
;   D4Lister v4.1.2  -  Hỗ trợ đăng item Diablo 4 lên diablo.trade
;   AutoHotkey v1  |  File độc lập, không #Include gì, chạy được trên máy khác
;
;   Mỗi phím CHỈ ăn ở đúng cửa sổ của nó — ngoài đó bấm không có tác dụng,
;   để lỡ tay chạm phím lúc đang làm việc khác thì không sinh chuyện.
;
;   CHỈ TRONG GAME:
;     F2          Quét hàng loạt cả rương và túi đồ (mở hộp thoại chọn trước)
;     F3          Lấy món đang rê chuột  (đọc thẳng chữ của game, KHÔNG chụp)
;     F10         Chụp & đo các tab — chỉ dùng lúc dò lệch toạ độ
;
;   CHỈ TRÊN TRÌNH DUYỆT:
;     F4          Dán item hiện tại (thay cho Ctrl+V)
;     F5          Sang item kế tiếp
;     F6          Lùi về item trước đó
;
;   GAME HOẶC TRÌNH DUYỆT:
;     F9          Xóa sạch danh sách đang chờ đăng
;
;   Ở ĐÂU CŨNG ĐƯỢC (tổ hợp ba phím, không chạm nhầm được):
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
;   F3 chạy ở chế độ màn hình nào cũng được — nó chỉ đọc chữ.
;   F2 thì KHÁC: nó rê chuột theo toạ độ đo sẵn và đọc điểm ảnh để biết
;   rương đã mở chưa, nên cần đúng cửa sổ mặc định ở màn hình 1920×1080
;   (vùng vẽ 1920×1027). Sai cỡ thì F2 tự dừng và báo, không rê bừa.
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
; AHK v1 mặc định KHÔNG nhận biết DPI. Màn hình để scale > 100% mà không
; bật cái này thì Windows trả về toạ độ và điểm ảnh của một màn hình ảo đã
; thu nhỏ — F2 rê trượt ô, và phép kiểm rương đọc nhầm điểm ảnh.
EnableDpiAwareness()

;=====================================================================
;   CẤU HÌNH  -  sửa ở đây
;=====================================================================
global HK_QUET    := "F2"           ; quét hàng loạt rương + túi đồ
global HK_KIEMTRA := "F10"          ; chụp & đo các tab (chỉ để dò, không quét)
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
;   TOẠ ĐỘ — ĐO THẬT trên ảnh chụp, không dùng công thức quy đổi của D4LF.
;   Đo bằng cách dò các đường kẻ của lưới:
;
;       RƯƠNG   11 đường dọc  x = 42 .. 623   cách đều 58,1
;                6 đường ngang y = 279 .. 740  cách đều 92,2
;       TÚI ĐỒ  x = 1301, ô rộng 52,4  ·  y = 709, ô cao 77,0
;
;   Dải tab KHÔNG theo công thức nào cả — xem TAB_X6 / TAB_X7 bên dưới.
;   Công thức của D4LF thì sai hẳn: họ giãn 63 px, đo thật là 58-59, tab ở
;   hai đầu lệch tới 12-13 px mà ô tab chỉ rộng 53. Bấm hụt ra ngoài panel
;   là bấm vào thế giới, nhân vật chạy đi.
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
; Mép trái đo lại 24/09 trên ảnh chụp thật của máy đang dùng: các đường kẻ
; dọc nằm ở 1402, 1455, 1507 … 1874 (cách đều 52,4), suy ngược ra mép trái
; 1297,2. Số cũ 1301 lệch gần 4 px — không đủ để hỏng, nhưng lệch thì sửa.
global TUI_X    := 1297
global TUI_Y    := 686
global TUI_OW   := 52.4
global TUI_OH   := 77.0
global TUI_COT  := 11
global TUI_HANG := 3

; --- dải tab: số tab chọn trong hộp thoại F2 ---
; Tâm từng ô tab, ĐO THẬT từ ảnh chụp, cho từng trường hợp số tab.
;
; Không dùng công thức nữa. Trước đây tôi tưởng dải tab là một dãy đều
; căn giữa, đo bản 6 tab rồi suy ra bản 7 tab. Đo nốt bản 7 tab thì hỏng
; giả thiết: CẢ bước nhảy LẪN tâm dải đều đổi theo số tab —
;     6 tab: bước 59,10  tâm dải 332,75
;     7 tab: bước 58,33  tâm dải 329,43
; Công thức cũ lệch dồn tới 5 px ở tab ngoài cùng. Ô tab rộng 53 px nên
; chưa đến mức bấm hụt, nhưng đã đủ để thấy con trỏ không vào giữa ô.
global TAB_X6 := [185, 244, 303, 363, 422, 481]
global TAB_X7 := [155, 213, 271, 330, 388, 447, 505]
global TAB_Y  := 162            ; 185 trên màn hình − 23 của thanh tiêu đề

; --- nhịp ---
global CHO_O_MS   := 160        ; chờ tooltip tối đa bao lâu mỗi ô
global CHO_TAB_MS := 400        ; chờ sau khi bấm đổi tab
global LECH_CHUOT := 8          ; con trỏ lệch quá ngần này px = người dùng động vào

; --- vùng vẽ mong đợi. Khác thì dừng, vì mọi toạ độ trên đo ở cỡ này ---
; --- nhìn ô bằng điểm ảnh: ô trống hay ô có đồ (xem khối NHÌN Ô bên dưới) ---
global O_NUA_W    := 18        ; lấy mẫu trong ô: nửa bề rộng, tính bằng px
global O_NUA_H    := 20        ; ...nửa bề cao
global O_BUOC     := 5         ; hai điểm mẫu cách nhau mấy px  -> 72 điểm
global O_CHENH    := 12        ; sáng hơn điểm tối nhất quá ngần này = "điểm lệch"
global O_NGUONG   := 18        ; từ ngần này điểm lệch trở lên = ô có đồ
; Ngưỡng RIÊNG, thấp hơn hẳn, dùng khi quyết định CÓ BỎ QUA ô hay không.
; Hai việc khác nhau nên hai ngưỡng khác nhau:
;   báo cáo "nhìn thấy có đồ"  -> đoán sai chỉ mất một dòng cảnh báo
;   bỏ qua không rê            -> đoán sai là MẤT MÓN, im lặng
; Đo trên 415 ô thật: ô trống nhiều nhất 1 điểm lệch, ô có đồ ít nhất 30.
; Để 6 thì ô trống vẫn bỏ qua hết, mà món nào mờ cũng còn cách xa ngưỡng.
global O_RE       := 6         ; từ ngần này trở lên thì PHẢI rê vào
global SO_O_THU_LAI := 6       ; rê thử mấy ô 'trống' để kiểm phép nhìn
global SOT_KE_TOI_DA := 5      ; báo cáo kể tên tối đa mấy ô sót (sổ vẫn ghi đủ)
global VET_SOT_VONG  := 3      ; vét lại ô "nhìn thấy có đồ mà không đọc ra" mấy lượt

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
global g_FileMonDaLay := "" ; file của chính món đó — để bấm F3 lần nữa là đặt lại giá
global g_DaNoi   := false   ; game đã nối vào đường ống chưa
global g_LanThuOng := 0     ; lần gần nhất thử dựng đường ống (A_TickCount)

; --- quét hàng loạt (F2) ---
global g_SoTab   := 7       ; rương có mấy tab — chọn trong hộp thoại F2
global g_QuetTui := true    ; có quét cả túi đồ nhân vật không
global g_Tab     := []      ; g_Tab[i] = có quét tab i không
global g_DaQuet  := {}      ; các ô đã lấy: "nơi|hàng|cột|nội dung"
global g_TraLoi  := ""      ; hộp thoại F2 trả về: "" chưa chọn / quet / huy
global g_DoLai   := true    ; có dò lại các ô im lặng không
global g_LechTab := 0       ; chỉnh tay dải tab nếu rê trượt (px)
global g_HienLuoi := true   ; vẽ sơ đồ lưới ô trong báo cáo cuối lượt
global g_BoQuaOTrong := false  ; chỉ rê vào ô nhìn thấy có đồ
global g_HoiGia := true        ; lấy món xong thì hỏi giá luôn
global DAU_CANH := 10          ; cạnh ô vuông đánh dấu, px
global DAU_LUI  := 5           ; thụt vào khỏi góc ô cho khỏi đè đường kẻ
global O_TUI_DO := 8           ; "tab" số 8 nghĩa là túi đồ

global g_DauXanh    := {}      ; "tab|hàng|cột" -> true
global g_DauTabDang := -1      ; tab đang vẽ; -1 = chưa vẽ gì
global g_DauHien    := false
global g_DauHwnd    := 0
global g_ReGiaHien := false
global g_ReGiaHwnd := 0
global g_ReGiaO    := ""       ; ô đang hiện giá, để khỏi vẽ lại mỗi nhịp
global g_VienHwnd  := 0
global g_ODangRe   := ""   ; ô con trỏ đang nằm, chốt lúc bấm F3
global g_TabCuoi   := 0    ; tab đọc được gần nhất lúc dải tab còn thấy rõ
global VIEN_MAU    := "2BD94B"  ; xanh lá tươi, như viền của D4LF
global VIEN_DAY    := 3         ; bề dày nét viền, px
global g_DangHoiGia := false
global g_GiaXong    := false   ; form đã bấm xong chưa
global g_GiaHwnd    := 0
global g_GiaX       := ""    ; chỗ người dùng kéo form tới, nhớ qua quet.ini
global g_GiaY       := ""
global g_GiaTenMonDang := ""   ; tên món form đang hỏi giá
global g_GiaChuO       := ""   ; chữ đang nằm trong ô gõ, giữ qua lần dựng lại
global g_DonVi         := "b"  ; đơn vị mặc định — gõ 200 nghĩa là 200b
global g_KyTuTam       := ""   ; ký tự vừa gõ, dùng trong nhãn bắt phím
global GIA_TOI_DA      := 999  ; trần giá, gõ quá thì không ăn phím
; Bộ phím form đặt giá bắt lấy. Nuốt luôn, không cho lọt xuống game.
global PHIM_GIA := "0|1|2|3|4|5|6|7|8|9"
    . "|Numpad0|Numpad1|Numpad2|Numpad3|Numpad4"
    . "|Numpad5|Numpad6|Numpad7|Numpad8|Numpad9"
    . "|.|NumpadDot|BackSpace|Enter|NumpadEnter|Escape"
global g_GiaChon := ""
global g_OTrangThai := []   ; trạng thái từng ô của lưới vừa quét
global g_OCot := 0
global g_OHang := 0
global g_TK      := {}      ; sổ thống kê của lượt quét đang chạy
global g_GhimX   := -1      ; ghim tooltip vào chỗ cố định; -1 = bám con trỏ
global g_GhimY   := -1
global g_DemConLai := 0     ; số giây còn lại của báo cáo cuối lượt
global g_GoiY    := {}      ; chữ gợi ý khi rê chuột trong hộp thoại F2
global g_CuaSoCu := "chua-bat"  ; trạng thái cửa sổ game lần báo gần nhất
global g_TuDat   := false   ; tự đặt thời gian hiện báo cáo
global g_Giay    := 10      ; ...bao nhiêu giây, khi g_TuDat bật
global g_ChoTruoc := false  ; chờ vài giây rồi mới bắt đầu quét
global g_GiayCho  := 5      ; ...chờ mấy giây
global GIAY_MAC_DINH := 10  ; không tự đặt thì dùng số này
global FILE_LOG_QUET := A_ScriptDir . "\nhat-ky-quet.txt"

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
Menu, Tray, Tip, D4Lister v4.1.2`nTrong game: F2 quet ruong / F3 lay mon`nTren trinh duyet: F4 dan / F5 ke / F6 lui

if !FileExist(QUEUE_DIR)
    FileCreateDir, %QUEUE_DIR%

daDonQueueCu := DonQueueCu()

RefreshQueue(true)

NapCauHinhQuet()

; PHÍM TẮT CHỈ ĂN Ở ĐÚNG CỬA SỔ CỦA NÓ.
;
; Trước đây mọi phím đều ăn ở mọi nơi. Đang gõ chữ ở đâu đó mà lỡ chạm F3
; là tool tưởng bạn lấy món, F4 là nó dán nhầm vào chỗ khác. Nay:
;
;   F2 F3 F10  — chỉ trong GAME. Ba phím này rê chuột, chụp màn hình, đọc
;                tooltip của game; ngoài game thì chẳng có nghĩa gì.
;   F4 F5 F6   — chỉ trong TRÌNH DUYỆT. Ba phím này dán vào trang.
;   F9         — game HOẶC trình duyệt. Xoá hàng đợi, chỗ nào cũng hợp lý.
;   Ctrl+Shift+F11/F12 — ở đâu cũng được. Tổ hợp ba phím, không chạm nhầm
;                được, mà lúc cần nạp lại/thoát thì đang ở đâu cũng phải gọi
;                ra được.
GroupAdd, nhomGame, ahk_exe Diablo IV.exe
for iTD, exeTD in ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe"
                 , "opera.exe", "vivaldi.exe", "zen.exe", "arc.exe"]
{
    GroupAdd, nhomWeb,  % "ahk_exe " . exeTD
    GroupAdd, nhomCaHai, % "ahk_exe " . exeTD
}
GroupAdd, nhomCaHai, ahk_exe Diablo IV.exe

Hotkey, IfWinActive, ahk_group nhomGame
Hotkey, %HK_QUET%,    DoQuet
Hotkey, %HK_KIEMTRA%, DoKiemTra
Hotkey, %HK_CAPTURE%, DoCapture

Hotkey, IfWinActive, ahk_group nhomWeb
Hotkey, %HK_PASTE%,   DoPaste
Hotkey, %HK_NEXT%,    DoNext
Hotkey, %HK_PREV%,    DoPrev

Hotkey, IfWinActive, ahk_group nhomCaHai
Hotkey, %HK_CLEAR%,   DoClear

; Bỏ điều kiện đi. PHẢI làm, không thì mọi Hotkey gọi về sau — nhất là
; ~Esc của báo cáo và bộ phím của ô nhập giá — đều dính điều kiện cuối
; cùng còn treo ở đây, bật/tắt không đúng cái mình tưởng.
Hotkey, IfWinActive
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

; Hai đồng hồ của phần đặt giá. Chạy NGAY TỪ ĐẦU chứ không đợi có món nào
; được đánh dấu: chúng còn giữ nhiệm vụ đọc xem rương đang mở tab mấy, mà số
; đó phải có SẴN vào đúng lúc bấm F3 — lúc ấy tooltip của món che mất dải
; tab, không đọc kịp nữa. Ngoài lúc chơi thì cả hai thoát ngay ở dòng đầu,
; gần như không tốn gì.
SetTimer, TheoDoiTabDau, 400
SetTimer, TheoDoiReGia, 120

; Soi cửa sổ game NGAY lúc khởi động, đừng để đến lúc bấm F2 mới biết.
; Game chưa bật thì im lặng — đó là chuyện bình thường, bật sau cũng được;
; đồng hồ dưới đây sẽ để ý và báo khi cửa sổ sai cỡ.
loiCuaSo := ""
WinGet, hwndGame, ID, ahk_exe Diablo IV.exe
if (hwndGame)
    loiCuaSo := KiemCuaSoGame(gxKD, gyKD, cwKD, chKD)

if (daDonQueueCu)
    ShowMsg("Đã dọn danh sách cũ của bản chụp ảnh" . canhBao, "warn")
else if (loiCuaSo != "")
    ShowMsg("F2 chưa dùng được:`n" . loiCuaSo
          . "`n`nF3 vẫn lấy được từng món bình thường.", "err", 7000)
else if (g_Items.Length() > 0)
    ShowMsg("D4Lister v4.1.2 — " . g_Items.Length() . " món đang chờ đăng" . canhBao, "warn")
else if (canhBao != "")
    ShowMsg("D4Lister v4.1.2" . canhBao, "err")
else
    ShowMsg("D4Lister v4.1.2 sẵn sàng", "ok")

SetTimer, CanhCuaSo, 4000

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
    ; Form đặt giá đang mở thì đừng lấy món mới đè lên. Nó chờ người dùng
    ; bấm chứ không tự tắt, nên không chặn là F3 nhấn nhầm sẽ xếp chồng
    ; nhiều form, món nào ra món nào không biết đường lần.
    if (g_Busy || g_DangHoiGia)
        return
    g_Busy := true

    ; Ghi nhớ Ô NGAY BÂY GIỜ, lúc con trỏ còn đang nằm trên món.
    ;
    ; Đây là chỗ đã sai một lần: dấu xanh được đặt theo vị trí chuột lúc
    ; LƯU GIÁ, mà lúc ấy người dùng đã rê chuột xuống form để bấm nút mức
    ; giá rồi — hỏi ra thì chuột đang ở đáy màn, không ô nào cả, nên chẳng
    ; món nào được đánh dấu. Hồi còn bắt phím 1-5 thì chuột không rời món
    ; nên không lộ.
    GhiNhoODangRe()
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
        ; Lấy rồi thì không lấy lần nữa, nhưng ĐẶT LẠI GIÁ thì được —
        ; quét cả rương bằng F2 xong, rê từng món bấm F3 để đặt giá là
        ; đường dùng chính.
        g_Busy := false
        if (g_HoiGia && FileExist(g_FileMonDaLay))
        {
            fCu := g_FileMonDaLay
            giaCu := DocGiaTuFile(fCu)
            giaMoi := HoiGia(TenMonTu(g_MonCuoi), giaCu)
            if (giaMoi != "")
            {
                LuuGiaVaoFile(fCu, giaMoi)
                DatClipboardTuFile(fCu)
                ShowMsg("Đã đặt giá " . giaMoi
                    . (DanhDauMon(giaMoi) ? "" : "`nkhông đánh dấu được ô — " . ViSaoKhongDau())
                    , "ok")
            }
            else
                ShowMsg("Món này lấy rồi — chưa đổi giá", "warn")
            return
        }
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
        ShowMsg("Không lưu được món này", "err")
        return
    }

    ; Món đầu tiên của một đợt mới -> ghi nhớ vị trí bắt đầu đợt
    if (!g_FreshCapture)
        g_BatchStart := g_Items.Length() + 1

    g_Items.Push(outFile)
    g_Cur := g_Items.Length()
    g_FreshCapture := true
    g_MonDaLay := g_MonCuoi
    g_FileMonDaLay := outFile

    if (!DatClipboard(chu))
    {
        g_Busy := false
        ShowMsg("Đã lưu item " . g_Cur . " nhưng LỖI COPY — bấm F5 rồi F6", "err")
        return
    }

    g_Busy := false

    ; Hỏi giá NGAY, lúc tooltip của món vẫn còn trên màn và bạn vẫn đang
    ; nhìn nó. Hỏi sau thì phải nhớ lại món nào ra món nào.
    if (g_HoiGia)
    {
        giaMoi := HoiGia(g_TenCuoi)
        if (giaMoi != "")
        {
            LuuGiaVaoFile(outFile, giaMoi)
            ; Đặt LẠI clipboard từ file. Clipboard được đặt ở trên kia, TRƯỚC
            ; lúc hỏi giá, nên chữ trong đó chưa có dòng #D4L-GIA. Ai dán
            ; bằng Ctrl+V (thay vì F4) là dán phải bản cũ, tiện ích không
            ; thấy giá đâu mà điền.
            DatClipboardTuFile(outFile)
            ShowMsg(g_Cur . "/" . g_Items.Length() . "  " . g_TenCuoi
                . "`ngiá " . giaMoi
                . (DanhDauMon(giaMoi) ? "" : "`nkhông đánh dấu được ô — " . ViSaoKhongDau())
                , "ok")
            return
        }
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
    g_FileMonDaLay := ""
    XoaDauXanh()
    g_DaQuet := {}

    if (n = 0)
        ShowMsg("Chưa có món nào để xoá", "warn")
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
;   msHien  = 0 -> dùng MSG_TIME. Đặt số khác để giữ lâu hơn (báo cáo cuối lượt).
;   demNguoc   -> hiện số giây còn lại, nhỏ, ở góc dưới bên phải.
   ;   Vẽ sơ đồ các lưới đã quét. Trả về toạ độ y của đáy phần vừa vẽ,
   ;   và nới rongNhat nếu lưới rộng hơn khối chữ.
VeLuoiO(dsLuoi, x0, y0, ByRef rongNhat)
{
    global
    local i, d, r, c, tt, mau, canh, khe, fs
    local cot, hangY, cotX, caoHang, rongCot, xx, yy, dayNhat

    canh := Round(12 * A_ScreenDPI / 96)    ; cạnh một ô vuông
    khe  := Round(2 * A_ScreenDPI / 96)     ; khe giữa hai ô
    fs   := Round(8 * A_ScreenDPI / 96)

    ; Xếp HAI LƯỚI MỘT HÀNG NGANG: tab 1-2 một hàng, 3-4 hàng sau, v.v.
    ; Xếp dọc hết thì bảng cao lêu nghêu, bảy tab là quá màn hình.
    ; Cột rộng theo lưới rộng nhất (túi đồ 11 cột) để hai cột thẳng nhau.
    rongCot := 11 * (canh + khe) - khe + Round(22 * A_ScreenDPI / 96)
    hangY   := y0
    dayNhat := y0
    cot     := 0

    for i, d in dsLuoi
    {
        if (!IsObject(d.o) || d.cot < 1 || d.hang < 1)
            continue

        cotX := x0 + cot * rongCot
        yy   := hangY

        Gui, Msg:Font, s%fs% Norm, Segoe UI
        Gui, Msg:Add, Text, % "x" . cotX . " y" . yy
                           . " w" . (rongCot - Round(8 * A_ScreenDPI / 96))
                           . " h" . Round(15 * A_ScreenDPI / 96)
                           . " c707070 BackgroundTrans"
                           , % d.ten . "   " . d.coDo . "/" . d.nhin
        yy += Round(16 * A_ScreenDPI / 96)

        r := 0
        while (r < d.hang)
        {
            c := 0
            while (c < d.cot)
            {
                tt := d.o[r * d.cot + c]
                mau := (tt = 1) ? "2E9E4F" : (tt = 2) ? "C0392B" : "C9C9C9"
                Gui, Msg:Add, Progress, % "x" . (cotX + c * (canh + khe))
                                       . " y" . yy . " w" . canh . " h" . canh
                                       . " Background" . mau . " Disabled"
                c++
            }
            yy += canh + khe
            r++
        }

        if (cotX + d.cot * (canh + khe) - khe > x0 + rongNhat)
            rongNhat := cotX + d.cot * (canh + khe) - khe - x0
        if (yy > dayNhat)
            dayNhat := yy

        ; Sang cột kia; hết hai cột thì xuống hàng mới.
        cot++
        if (cot >= 2)
        {
            cot   := 0
            hangY := dayNhat + Round(9 * A_ScreenDPI / 96)
        }
    }

    ; Lưới cuối nằm một mình ở cột trái thì đáy vẫn là đáy của nó.
    return (cot = 0) ? hangY : (dayNhat + Round(9 * A_ScreenDPI / 96))
}


ShowMsg(text, kind := "ok", msHien := 0, demNguoc := false, dsLuoi := "")
{
    global g_MsgHwnd, MSG_TIME, COL_BG, COL_OK, COL_ERR, COL_WARN
    global g_GhimX, g_GhimY, g_DemConLai
    ; Biến gắn với control GUI (chữ v khi thêm) BẮT BUỘC phải toàn cục.
    ; Để nó thành biến cục bộ của hàm thì AutoHotkey giết luồng lúc chạy,
    ; không hộp lỗi, không stderr — /iLib vẫn báo cú pháp sạch.
    global MsgChu, MsgDem

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
    Gui, Msg:Add, Text, c%col% BackgroundTrans vMsgChu, % mark . text

    g_MsgHwnd := WinExist()

    ; Hiện ngoài màn hình trước để đo kích thước -> không bị nháy hình
    Gui, Msg:Show, NA AutoSize x-32000 y-32000

    ; PHẢI đặt sau Show: trước khi cửa sổ hiện ra thì control chưa có kích
    ; thước, GuiControlGet trả về rỗng, chuỗi toạ độ thành rác và cả luồng
    ; chết im không một lời báo.
    GuiControlGet, p, Msg:Pos, MsgChu
    dayY := pY + pH
    rongNhat := pW

    ; --- SƠ ĐỒ LƯỚI Ô ---
    ; Con số "29/30" nói có thiếu, nhưng không nói THIẾU Ở ĐÂU. Vẽ đúng
    ; hình cái rương ra thì liếc một cái là biết ô nào, khỏi đếm dòng.
    ;   xám  ô trống      xanh  đọc được      đỏ  có đồ mà không đọc ra
    if (IsObject(dsLuoi) && dsLuoi.Length() > 0)
        dayY := VeLuoiO(dsLuoi, pX, dayY + Round(10 * A_ScreenDPI / 96), rongNhat)

    ; Đồng hồ đếm ngược: một số nhỏ nhạt ở góc dưới phải, không phải một
    ; câu chữ trong thân báo cáo — chữ nhiều thì mắt không biết nhìn đâu.
    SetTimer, DemNguocTimer, Off
    Hotkey, ~Esc, DongBaoCao, Off
    if (demNguoc && msHien <= 0)
    {
        ; Giữ nguyên trên màn, Esc mới đóng. Dùng ~Esc (có dấu ngã) để phím
        ; vẫn lọt xuống game — nuốt mất Esc là người dùng đóng menu trong
        ; game không được, mà lỗi kiểu đó rất khó đoán ra là do đâu.
        Gui, Msg:Font, % "s" . Round(9 * A_ScreenDPI / 96) . " Bold", Segoe UI
        Gui, Msg:Add, Text, % "x" . (pX + rongNhat - Round(96 * A_ScreenDPI / 96))
                           . " y" . (dayY + Round(3 * A_ScreenDPI / 96))
                           . " w" . Round(96 * A_ScreenDPI / 96)
                           . " Right c4A4A4A BackgroundTrans vMsgDem"
                           , Esc để đóng
        Hotkey, ~Esc, DongBaoCao, On
    }
    else if (demNguoc && msHien > 0)
    {
        rongDem := Round(46 * A_ScreenDPI / 96)
        Gui, Msg:Font, % "s" . Round(10 * A_ScreenDPI / 96) . " Bold", Segoe UI
        Gui, Msg:Add, Text, % "x" . (pX + rongNhat - rongDem)
                           . " y" . (dayY + Round(3 * A_ScreenDPI / 96))
                           . " w" . rongDem . " Right c4A4A4A BackgroundTrans vMsgDem"
                           , % Round(msHien / 1000) . "s"
        g_DemConLai := Round(msHien / 1000)
        SetTimer, DemNguocTimer, 1000
    }
    Gui, Msg:Show, NA AutoSize x-32000 y-32000   ; nới cửa sổ cho vừa phần vừa thêm
    WinGetPos, , , gw, gh, ahk_id %g_MsgHwnd%

    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79

    ; Bình thường thì bám con trỏ — tiện, vì mắt đang ở đó.
    ; Nhưng lúc quét hàng loạt con trỏ chạy khắp rương, chữ nhảy theo thì
    ; không đọc kịp. Khi ấy F2 ghim một chỗ cố định, căn giữa theo g_GhimX.
    if (g_GhimX >= 0)
    {
        px := g_GhimX - gw // 2
        py := g_GhimY
    }
    else
    {
        MouseGetPos, mx, my
        px := mx + 18
        py := my + 22
    }
    if (px + gw > vx + vw)
        px := vx + vw - gw - 4
    if (py + gh > vy + vh)
        py := (g_GhimX >= 0) ? (vy + vh - gh - 4) : (my - gh - 12)
    if (px < vx)
        px := vx + 4
    if (py < vy)
        py := vy + 4

    ; Lúc đang ghim (tức đang quét) thì giữ lâu hơn: một hàng ô mất vài giây,
    ; để 1,1 giây thì bảng tiến độ cứ tắt rồi bật, nhìn như bị treo.
    WinMove, ahk_id %g_MsgHwnd%, , %px%, %py%
    ; demNguoc + msHien = 0 nghĩa là giữ mãi -> không hẹn giờ tắt.
    if (demNguoc && msHien <= 0)
        SetTimer, HideMsgTimer, Off
    else
        SetTimer, HideMsgTimer
            , % -(msHien > 0 ? msHien : (g_GhimX >= 0 ? 4000 : MSG_TIME))
}

;=====================================================================
;   CANH CỬA SỔ GAME
;
;   Báo MỘT LẦN mỗi khi trạng thái đổi, không nhắc lại. Nhắc mãi một
;   chuyện thì vài phút sau người ta thôi nhìn, và lúc có chuyện thật
;   cũng không nhìn nốt.
;
;   Game chưa bật: im lặng, đó là chuyện bình thường.
;=====================================================================
CanhCuaSo:
    if (g_Busy || g_DangQuet)       ; đang quét thì đừng chen ngang
        return
    WinGet, hwndCanh, ID, ahk_exe Diablo IV.exe
    if (!hwndCanh)
    {
        g_CuaSoCu := "chua-bat"
        return
    }
    loiCanh := KiemCuaSoGame(gxC, gyC, cwC, chC)
    if (loiCanh = g_CuaSoCu)
        return
    if (loiCanh != "")
        ShowMsg("F2 chưa dùng được:`n" . loiCanh, "err", 7000)
    else if (g_CuaSoCu != "" && g_CuaSoCu != "chua-bat")
        ShowMsg("Cửa sổ game đã đúng cỡ — F2 dùng được", "ok")
    g_CuaSoCu := loiCanh
return

HideMsgTimer:
    HideMsgNow()
return

DemNguocTimer:
    g_DemConLai--
    if (g_DemConLai <= 0)
    {
        HideMsgNow()
        return
    }
    GuiControl, Msg:, MsgDem, % g_DemConLai . "s"
return

DongBaoCao:
    ; Cùng một phím Esc, hai việc. Gộp vào MỘT nhãn vì AutoHotkey chỉ giữ
    ; được một nhãn cho mỗi phím — đăng ký hai nhãn thì cái sau đè cái
    ; trước, tắt cái này là tắt luôn cái kia.
    if (g_DangHoiGia)
        XongHoiGia("")
    else
        HideMsgNow()
return

HideMsgNow()
{
    global g_MsgHwnd
    SetTimer, HideMsgTimer, Off
    SetTimer, DemNguocTimer, Off
    Hotkey, ~Esc, DongBaoCao, Off
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
    local doc, ok
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
    ; BẮT BUỘC khai báo cục bộ. Hàm này ở phạm vi toàn cục (có "global" ở
    ; trên) nên mọi biến không khai báo đều là biến TOÀN CỤC — mà nó chạy
    ; mỗi khi một câu TTS về, tức liên tục suốt lượt quét.
    ;
    ; Đã sập vì đúng chỗ này: vòng lặp tab trong DoQuet dùng biến i, hàm
    ; này ghi đè lên, thế là nhãn lưới ghi "Tab 1" cho cả tab 2.
    local d, thap, vt, i, mon
    Loop, Parse, goi, `n, `r
    {
        d := DonCau(A_LoopField)
        if (d = "")
            continue
        if (InStr(d, "Champions who earn the favor of"))
            continue
        if (TTS_LOG)
            GhiTho(d)
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
    cauDaiBoQua := ""   ; câu dài không ai nhận — có thể chính là Aspect
    while (i <= ds.Length())
    {
        d := ds[i]
        if (LaMocDung(d))
            break
        ; SỨC MẠNH RIÊNG của đồ Unique / Aspect của đồ Legendary. Nó không
        ; phải affix — diablo.trade xếp nó ở mục UNIQUE POWER riêng — nhưng
        ; vẫn có một con số phải điền, nên nhặt ra rồi BỎ HẲN DÒNG, đừng để
        ; nó lọt vào danh sách affix.
        ;
        ; Bỏ dòng là phần quan trọng: câu Aspect ngắn như "Your Summons gain
        ; 43% Attack Speed." mà lọt vào danh sách affix thì tiện ích đem nó
        ; đi dò tên affix, không ra cái nào, và món kẹt lại không dựng được.
        dTron := Trim(RegExReplace(RegExReplace(d, "\([^)]*\)", ""), "\s+", " "))
        if (CoSucManhRieng(loai) && LaCauRieng(dTron))
        {
            if (cauRieng = "")
                cauRieng := CatDuoiGiaoDien(dTron)
            i++
            continue
        }
        d := DonChiSo(d, viSaoBo)
        ; Câu dài mà LaCauRieng cũng không nhận thì trước đây RƠI MẤT HẲN:
        ; một luật bảo "không phải Aspect", luật kia bảo "không phải affix",
        ; và dòng đi đâu không ai biết. Giữ lại làm dự bị cho Aspect.
        ; Giữ câu dài CUỐI CÙNG, không phải câu đầu. Tooltip của game xếp
        ; câu Aspect sau hết mọi affix (chữ thô đọc được 25/09/2026):
        ;     +151 Willpower
        ;     +22 Life on Kill +[18 - 22]
        ;     ...
        ;     Lucky Hit: Up to a 37.0% [30.0 - 40.0]% chance for your …
        ;     Requires Level 70.            <- vòng lặp dừng ở đây
        ; Nên nếu có một affix dài (mấy affix "Lucky Hit: …" dài nhất) cũng
        ; rơi vào đây, câu Aspect đứng sau vẫn giành lại được chỗ.
        if (d = "" && viSaoBo = "dai")
            cauDaiBoQua := dTron
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
    ; Món Legendary/Unique nào cũng có đúng MỘT sức mạnh riêng. Không nhặt
    ; được câu nào mà lại có một câu dài bị bỏ thì câu đó chính là nó —
    ; không cần biết câu ấy mở đầu bằng chữ gì.
    if (cauRieng = "" && cauDaiBoQua != "" && CoSucManhRieng(loai))
        cauRieng := CatDuoiGiaoDien(cauDaiBoQua)

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
        ; cauRieng đã bỏ ngoặc tròn từ lúc nhặt: câu của game hay kèm giới
        ; hạn class "(Barbarian Druid Only)" mà mô tả trong danh mục của
        ; trang thì không có, để lại là lệch mất mấy từ.
        ra .= "`n#D4L-ASPECT:" . cauRieng
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
    ; XÉT NGAY TRÊN CHÍNH MÓN NÀY, không đợi đủ ba món liên tiếp.
    ;
    ; Đã dính thật ngày 25/09: người dùng tắt Advanced Tooltip Information,
    ; mọi dòng mất khoảng [min - max], luật "không khoảng = Greater" đóng dấu
    ; sao lên CẢ BỐN dòng của một đôi găng chỉ có hai Greater. Đếm tới ba món
    ; mới chặn thì món đầu tiên đã lên sàn sai rồi.
    ;
    ; Đổi lại: món nào mà MỌI dòng đều là Greater thật thì cũng mất dấu sao.
    ; Chuyện đó hiếm, và sai theo hướng "không đóng dấu" thì sửa tay được,
    ; còn sai theo hướng "đóng bừa" thì lên sàn khai láo.
    ; DÙNG CHÍNH CÂU ASPECT LÀM CHỨNG.
    ;
    ; Luật "mọi dòng đều không có khoảng = công tắc tắt" siết quá tay: có
    ; món cả bốn affix đều Greater thật, và Greater thì không in khoảng.
    ; Dính ngay: ARCHON GAUNTLETS OF FORTUNE ✻✻✻✻ bị bỏ sạch dấu sao.
    ;
    ; Phân biệt được, vì câu Aspect KHÔNG bao giờ là Greater — công tắc bật
    ; thì nó luôn in khoảng:
    ;     bật:  "You gain 18.5%[x] [15.0 - 20.0]% Lucky Hit Chance…"
    ;     tắt:  "Your Summons gain 43% Attack Speed."
    ; Câu Aspect còn khoảng = công tắc đang bật = mấy dòng không khoảng kia
    ; là Greater thật.
    ;
    ; Món không có Aspect (đồ Rare) mà mọi dòng đều không khoảng thì đành
    ; chịu, không có gì làm chứng — giữ nguyên hướng an toàn là không đóng
    ; dấu, thà thiếu còn hơn khai láo.
    coKhoangOAspect := RegExMatch(cauRieng, "\[[0-9.,]+ *- *[0-9.,]+\]") > 0
    nghiTatNay := (soCoSo >= 2 && soKhongNgoac = soCoSo && !coKhoangOAspect)
    if (nghiTatNay)
        g_NghiTatTooltip++
    else
        g_NghiTatTooltip := 0

    ; CỜ BÁO "PHẦN DÒ DẤU SAO ĐÃ CHẠY XONG".
    ; Thiếu cờ này thì tiện ích TẮT NGẦM toàn bộ việc bật/tắt dấu sao — nó
    ; thà không đụng còn hơn xoá nhầm dấu sao trang đã nhận đúng. Bản V2 phát
    ; cờ từ hàm đo pixel; V3 bỏ hàm đó nên phải phát ở đây.
    if (!nghiTatNay)
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
;   Dòng này có phải CÂU sức mạnh riêng không?
;
;   Dấu hiệu chắc hơn hẳn phép đếm từ: affix của D4 luôn mở đầu bằng "+",
;   "x" hoặc một con số. Câu Aspect mở đầu bằng CHỮ.
;
;       affix   "+2,162 Maximum Life"   "x35% Vulnerable Damage Multiplier"
;       aspect  "Your Summons gain 43% Attack Speed."
;               "You gain 185% of your Attack Speed as increased damage…"
;
;   Phép đếm từ cũ bỏ sót hai câu trên — câu đầu chỉ 6 từ. Bỏ sót thì món
;   không dựng được: trang bắt chọn Aspect mới cho dựng đồ Legendary.
;
;   Ngoại lệ DUY NHẤT đã biết: affix "Lucky Hit: Up to a X% chance to…"
;   cũng mở đầu bằng chữ. Chừa nó ra.
;
;   Lấy câu ĐẦU TIÊN chứ không phải cuối: đồ Unique có thêm đoạn văn kể
;   chuyện in nghiêng nằm SAU câu Aspect, mà đoạn đó cũng mở đầu bằng chữ.
;   Cắt phần chữ của GIAO DIỆN dính vào đuôi câu Aspect.
;
;   Lúc Advanced Tooltip Information tắt, đường ống gộp hai dòng làm một:
;       "You gain 185% … but no longer attack faster.. Current Bonus: 0.00%"
;   Cái đuôi đó làm câu lệch hẳn so với mô tả trong danh mục của trang —
;   điểm khớp tụt còn 88%, dưới ngưỡng, và món kẹt lại không dựng được.
CatDuoiGiaoDien(d)
{
    d := RegExReplace(d, "i)\s*\.?\s*(Current Bonus|Requires Level|Sell Value"
                       . "|Durability|Tempers|Unique Equipped|Lord of Hatred)\b.*$", "")
    d := RegExReplace(d, "\.{2,}$", ".")
    return Trim(d)
}

LaCauRieng(d)
{
    d := Trim(d)
    if (d = "")
        return false
    ; Affix LUÔN mở đầu bằng "+", "x" hoặc một con số:
    ;     "+2,162 Maximum Life"   "x35% Vulnerable Damage Multiplier"
    ;     "173 All Resist"        "+2 to Demonology Skills"
    ;
    ; Chữ "x" ở đây là DẤU NHÂN, không phải chữ cái. Bản đầu của hàm này
    ; chỉ hỏi "có mở đầu bằng chữ cái không" nên nhận nhầm mọi dòng x…%
    ; thành câu Aspect — và thế là câu Aspect thật bị đè mất.
    if (RegExMatch(d, "^[+x]?\s*\d"))
        return false
    if (RegExMatch(Format("{:L}", d), "^lucky hit"))
        return false
    ; "Unlocks new Aspect in the Codex of Power and look on salvage" — ghi
    ; chú của game. Nó mở đầu bằng chữ cái nên lọt vào đây, và món nào
    ; KHÔNG đọc ra được câu Aspect thật thì nó chiếm luôn chỗ.
    if (RegExMatch(Format("{:L}", d), "^unlocks\s"))
        return false
    return true
}

;   Loại đồ này có "sức mạnh riêng" (Aspect / Unique power) không.
;   Rare, Magic, Common thì KHÔNG BAO GIỜ có.
CoSucManhRieng(loai)
{
    local l
    l := Format("{:L}", loai)
    return InStr(l, "legendary") || InStr(l, "unique") || InStr(l, "mythic")
}

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
    ; Không có khoảng [min - max] — nhiều Aspect của đồ Legendary là vậy:
    ;   "Your Summons gain 43% Attack Speed."
    ;   "You gain 185% of your Attack Speed as increased damage…"
    ; Lấy CON SỐ ĐẦU làm giá trị. Tiện ích nhận được số mà không có trần thì
    ; chỉ điền số, không đụng tới công tắc "kịch trần".
    if RegExMatch(d, "([0-9]+\.?[0-9]*)", m)
        return m1
    return ""
}

;   Dọn một dòng chỉ số. Trả về "" nếu dòng đó không phải chỉ số.
;   viSao (ByRef) nói vì sao dòng bị bỏ: "ngan" | "unlocks" | "dai" | "".
;   Người gọi cần biết để không đánh rơi câu Aspect — xem bẫy 69.
DonChiSo(d, ByRef viSao := "")
{
    viSao := ""
    ; Bỏ phần trong ngoặc tròn: so sánh với đồ đang mặc "(+8)", giới hạn
    ; class "(Druid Warlock Only)". diablo.trade không có ô cho mấy thứ này.
    d := Trim(RegExReplace(RegExReplace(d, "\([^)]*\)", ""), "\s+", " "))
    if (d = "")
    {
        viSao := "ngan"
        return ""
    }
    if (StrLen(RegExReplace(d, "[^A-Za-z]", "")) < 3)
    {
        viSao := "ngan"
        return ""
    }

    ; "Unlocks new look on salvage" / "Unlocks new Aspect in the Codex of
    ; Power and look on salvage" — ghi chú của game, không phải chỉ số.
    ; Câu thứ hai dài đúng 12 từ nên lọt qua được phép cắt câu dài.
    if (RegExMatch(Format("{:L}", d), "^unlocks\s"))
    {
        viSao := "unlocks"
        return ""
    }

    ; Sức mạnh riêng của đồ Unique và lời văn kể chuyện là những CÂU dài.
    ; diablo.trade xếp chúng ở mục UNIQUE POWER riêng, không phải ô affix.
    ;
    ; Đếm từ thì BỎ khoảng "[min - max]" ra ngoài. Khoảng đó chỉ hiện khi
    ; công tắc Advanced Tooltip Information bật, và nó ngốn tận ba "từ"
    ; ("[8.0", "-", "12.0]%") — không trừ đi thì cùng một dòng affix lúc
    ; bật công tắc dài hơn lúc tắt ba từ, đủ để nhảy qua mốc 12 và bị bỏ.
    ; Nuốt luôn dấu "%" dính đuôi khoảng ("[8.0 - 12.0]%"), không thì bỏ
    ; ngoặc xong còn lại một chữ "%" đứng trơ, vẫn tính là một từ.
    if (SoTu(RegExReplace(d, "\[[^\]]*\]%?", "")) > 12)
    {
        viSao := "dai"
        return ""
    }

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
;=====================================================================
;   CHỤP MỘT VÙNG MÀN HÌNH VÀO BỘ NHỚ
;
;   Vì sao phải làm: PixelGetColor đo được 20 ms MỘT LẦN ĐỌC trên máy này.
;   Một lưới rương cần ~1750 điểm, tức 35 giây — không dùng được. Chụp cả
;   vùng một phát rồi đọc trong bộ nhớ thì chỉ còn một lần gọi hệ thống.
;
;   Ảnh dựng theo kiểu "trên xuống dưới" (chiều cao ÂM trong BITMAPINFO)
;   để dòng 0 là dòng trên cùng — để dương thì ảnh lộn ngược, và đó là
;   loại lỗi chỉ lộ ra khi toạ độ đã sai hết.
;=====================================================================
ChupVung(x, y, w, h)
{
    local hdcMan, hdcMem, hbm, hcu, bits, bi

    hdcMan := DllCall("GetDC", "ptr", 0, "ptr")
    if (!hdcMan)
        return 0
    hdcMem := DllCall("gdi32\CreateCompatibleDC", "ptr", hdcMan, "ptr")

    VarSetCapacity(bi, 40, 0)
    NumPut(40,  bi,  0, "uint")      ; biSize
    NumPut(w,   bi,  4, "int")       ; biWidth
    NumPut(-h,  bi,  8, "int")       ; biHeight âm = trên xuống dưới
    NumPut(1,   bi, 12, "ushort")    ; biPlanes
    NumPut(32,  bi, 14, "ushort")    ; biBitCount
    NumPut(0,   bi, 16, "uint")      ; BI_RGB

    bits := 0
    hbm := DllCall("gdi32\CreateDIBSection", "ptr", hdcMem, "ptr", &bi
                 , "uint", 0, "ptr*", bits, "ptr", 0, "uint", 0, "ptr")
    if (!hbm)
    {
        DllCall("gdi32\DeleteDC", "ptr", hdcMem)
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdcMan)
        return 0
    }

    hcu := DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
    DllCall("gdi32\BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h
          , "ptr", hdcMan, "int", x, "int", y, "uint", 0x00CC0020)   ; SRCCOPY
    DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", hcu)
    DllCall("gdi32\DeleteDC", "ptr", hdcMem)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcMan)

    ; Vùng ảnh còn sống chừng nào hbm chưa bị xoá — nhớ gọi XoaAnh().
    return {bits: bits, hbm: hbm, x: x, y: y, w: w, h: h}
}

XoaAnh(anh)
{
    if (anh && anh.hbm)
        DllCall("gdi32\DeleteObject", "ptr", anh.hbm)
}

;   Độ sáng của một điểm, theo TOẠ ĐỘ MÀN HÌNH. Ngoài vùng đã chụp thì
;   trả về -1 chứ không trả 0 — 0 là màu đen thật, lẫn vào là chẩn sai.
DocSangTaiDiem(anh, mx, my)
{
    local dx, dy, v
    dx := mx - anh.x
    dy := my - anh.y
    if (dx < 0 || dy < 0 || dx >= anh.w || dy >= anh.h)
        return -1
    v := NumGet(anh.bits + 0, (dy * anh.w + dx) * 4, "uint")
    ; trong bộ nhớ thứ tự byte là B, G, R, A
    return (((v >> 16) & 0xFF) * 299 + ((v >> 8) & 0xFF) * 587
          + (v & 0xFF) * 114) // 1000
}


;=====================================================================
;   NHÌN Ô BẰNG ĐIỂM ẢNH  —  ô trống hay ô có đồ
;
;   Vì sao cần: TTS im lặng có hai nghĩa — ô trống thật, hoặc ô có đồ mà
;   đọc hụt. Không phân biệt được thì sót món mà không ai hay. Mắt người
;   nhìn vào rương là biết ngay; máy cũng nhìn được.
;
;   DẤU HIỆU: ô trống là một mảng PHẲNG, ô có đồ thì có nét vẽ. Nên đo độ
;   CHÊNH SÁNG trong lõi ô (sáng nhất − tối nhất), không đo độ sáng.
;
;   Đã thử đo độ sáng trước và HỎNG: cái sáng lên không phải món đồ mà là
;   cái khung của nó, mà khung chỉ sáng khi món được đánh dấu. Ba món
;   không đánh dấu ở hàng cuối túi đồ bị đọc thành ô trống.
;
;   SỐ ĐO trên 166 ô thật (2 ảnh × rương + túi đồ), không sai ô nào:
;       ô trống   chênh sáng   5 .. 14
;       ô có đồ   chênh sáng  77 .. 229
;   Khe hở 5,5 lần. Ngưỡng 40 nằm giữa, lệch về phía an toàn.
;
;   Lấy mẫu: lõi 38% giữa ô, bước 9 px → 35 điểm. Lấy rộng hơn 42% là
;   chạm đường kẻ ô, mà đường kẻ cũng có chênh sáng — ô trống hoá ô có đồ.
;=====================================================================
;   Đếm "điểm lệch" trong một ô: điểm nào sáng hơn ĐIỂM TỐI NHẤT của
;   chính ô đó quá O_CHENH. Ô trống phẳng nên gần như không có điểm nào.
;   Trả về -1 nếu ô nằm ngoài vùng đã chụp.
;
;   Lấy mẫu trong một ô vuông CỐ ĐỊNH TÍNH BẰNG PX quanh tâm, không lấy
;   theo phần trăm bề rộng ô. Lý do: vùng nhỏ và sát tâm thì lệch vài px
;   vẫn nằm gọn trong ô, không chạm đường kẻ. Đo được:
;       lấy rộng 0,34 ô (140 điểm) → chỉ chịu lệch  -1..+4 px
;       lấy ±18×20 px  ( 72 điểm) → chịu lệch     -10..+10 px
;   Ít điểm hơn một nửa mà chịu lệch gấp ba, khe hở lại rộng hơn.
DemLechO(anh, tx, ty)
{
    global
    local x, y, s, nho, n, ds, k

    ds := []
    nho := 999
    x := tx - O_NUA_W
    while (x <= tx + O_NUA_W)
    {
        y := ty - O_NUA_H
        while (y <= ty + O_NUA_H)
        {
            s := DocSangTaiDiem(anh, x, y)
            if (s < 0)
                return -1
            ds.Push(s)
            if (s < nho)
                nho := s
            y += O_BUOC
        }
        x += O_BUOC
    }
    n := 0
    for k, s in ds
        if (s - nho > O_CHENH)
            n++
    return n
}

;   Nhìn cả một lưới: trả về mảng true/false theo thứ tự hàng rồi cột,
;   và đếm số ô có đồ vào soCoDo. Trả về mảng rỗng nếu chụp hỏng.
NhinCaLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang, ByRef soCoDo)
{
    global
    local anh, r, c, tx, ty, cs, ra, vx, vy, vw, vh

    soCoDo := 0
    ra := []

    ; Vùng chụp: trọn lưới, nới mỗi bên vài điểm cho chắc
    vx := gx + Round(x0) - 4
    vy := gy + Round(y0) - 4
    vw := Round(ow * soCot) + 8
    vh := Round(oh * soHang) + 8
    anh := ChupVung(vx, vy, vw, vh)
    if (!anh)
        return ra

    r := 0
    while (r < soHang)
    {
        c := 0
        while (c < soCot)
        {
            tx := gx + Round(x0 + ow * (c + 0.5))
            ty := gy + Round(y0 + oh * (r + 0.5))
            ; Trả về SỐ ĐIỂM LỆCH, không phải true/false: hai nơi dùng hai
            ; ngưỡng khác nhau (xem O_NGUONG và O_RE).
            cs := DemLechO(anh, tx, ty)
            ra[r * soCot + c] := cs
            if (cs >= O_NGUONG)
                soCoDo++
            c++
        }
        r++
    }
    XoaAnh(anh)
    return ra
}

;   Tên ô cho người đọc: "hàng 3 ô 6"
TenOVi(r, c)
{
    return "hàng " . (r + 1) . " ô " . (c + 1)
}


;=====================================================================
;   RƯƠNG ĐANG MỞ HAY KHÔNG
;
;   V3 đã bỏ hết bộ xử lý ảnh, nhưng đọc MỘT ĐIỂM ẢNH thì vẫn rẻ. Chỗ dễ
;   nhận nhất là MÉP TRÁI của lưới rương: một gờ sáng chạy dọc, bên trái
;   nó là dải tối. Đây là khung giao diện nên không phụ thuộc trong rương
;   có đồ hay không.
;
;   Không so màu tuyệt đối — nền game đổi liên tục. So TƯƠNG QUAN: điểm
;   trên gờ phải sáng hơn hẳn điểm cách nó 6 px về bên trái.
;
;   Đo trên hai ảnh rương thật (6 tab và 7 tab, khác class, khác đồ):
;   12/12 và 11/12 điểm đạt. Trên các ảnh không phải rương: 0/12.
;
;   Vì sao chỉ kiểm rương mà không kiểm túi đồ: toạ độ lưới túi đồ đo
;   TRÊN MÀN HÌNH RƯƠNG. Mở túi đồ một mình thì bố cục khác, số đo sai.
;   Nên rương mở là điều kiện cần cho cả hai lưới.
;=====================================================================
RuongDangMo(gx, gy)
{
    global
    local anh, i, y, go, trai, dat, s

    ; Chụp một dải hẹp ôm lấy mép trái lưới rồi đọc trong bộ nhớ.
    ; PixelGetColor đo được 20 ms MỘT LẦN — 48 lần là gần một giây đứng im
    ; mỗi lúc bấm F2. Chụp cả dải chỉ tốn một lần gọi hệ thống.
    anh := ChupVung(gx + RUONG_X - 10, gy + RUONG_Y + 10, 20, 450)
    if (!anh)
        return true                  ; chụp không được thì đừng chặn người dùng

    dat := 0
    i := 0
    while (i < 12)
    {
        y := gy + RUONG_Y + 20 + i * 38

        go := -1
        s := DocSangTaiDiem(anh, gx + RUONG_X - 1, y)
        if (s > go)
            go := s
        s := DocSangTaiDiem(anh, gx + RUONG_X, y)
        if (s > go)
            go := s
        s := DocSangTaiDiem(anh, gx + RUONG_X + 1, y)
        if (s > go)
            go := s

        trai := DocSangTaiDiem(anh, gx + RUONG_X - 6, y)
        if (go >= 35 && trai >= 0 && go - trai >= 28)
            dat++
        i++
    }
    XoaAnh(anh)
    return (dat >= 9)
}


;   Tâm ô tab thứ i khi rương có n tab, theo toạ độ vùng vẽ.
TamTab(i, n)
{
    global
    local ds
    ds := (n = 6) ? TAB_X6 : TAB_X7
    if (i < 1 || i > ds.Length())
        return -1
    return ds[i] + g_LechTab
}


;=====================================================================
;   KIỂM CỬA SỔ GAME
;
;   Trả về "" nếu mọi thứ ổn, ngược lại là câu nói rõ hỏng ở đâu.
;
;   NHẬN DIỆN THEO TỆP THỰC THI, không theo tiêu đề. Trước đây tìm bằng
;   tiêu đề "Diablo IV", mà AutoHotkey mặc định khớp kiểu "bắt đầu bằng" —
;   một cửa sổ Explorer đang mở thư mục tên Diablo IV cũng khớp. F2 sẽ rê
;   chuột và BẤM lên cửa sổ đó theo toạ độ của game. Nhận theo
;   "ahk_exe Diablo IV.exe" thì không thể nhầm sang thứ khác.
;=====================================================================
;=====================================================================
;   CHỈNH CỠ CỬA SỔ GAME VỀ ĐÚNG 1920×1027
;
;   Vì sao cần: vùng vẽ = chiều cao cửa sổ − viền. Viền dày bao nhiêu là
;   do Windows quyết, và nó KHÁC NHAU giữa các máy — khác chủ đề, khác
;   mức phóng DPI, hoặc màn hình ảo của Parsec. Đo được trên hai máy:
;       máy A  viền dọc 39  →  vùng vẽ 1027   (đúng)
;       máy B  viền dọc 49  →  vùng vẽ 1017   (lệch 10 px)
;   Cùng một cửa sổ cao 1066, ra hai vùng vẽ khác nhau.
;
;   Nên không đặt cứng chiều cao cửa sổ. Đo viền TẠI CHỖ rồi cộng vào:
;       cao cửa sổ cần = 1027 + (cao cửa sổ hiện tại − vùng vẽ hiện tại)
;
;   Đặt xong PHẢI ĐO LẠI. Game có thể tự nắn lại cỡ theo ý nó, và lúc ấy
;   báo "đã chỉnh xong" là nói dối. Thử tối đa 3 lượt rồi thôi.
;
;   Trả về "" nếu cuối cùng đúng cỡ, ngược lại là câu nói rõ hỏng ở đâu.
;=====================================================================
ChinhCoCuaSo(dk := "ahk_exe Diablo IV.exe")
{
    global
    local hwnd, tt, wx, wy, ww, wh, cw, ch, gx, gy, vienN, vienD, i

    WinGet, hwnd, ID, %dk%
    if (!hwnd)
        return "Không thấy cửa sổ Diablo IV."

    ; Cửa sổ phóng to hoặc thu nhỏ thì WinMove không ăn — trả về cỡ thường trước.
    WinGet, tt, MinMax, ahk_id %hwnd%
    if (tt != 0)
    {
        WinRestore, ahk_id %hwnd%
        Sleep, 450
    }

    i := 0
    while (i < 3)
    {
        if (!VungVe(gx, gy, cw, ch, dk))
            return "Không đọc được kích thước cửa sổ Diablo IV."
        if (cw = CLIENT_W && ch = CLIENT_H)
            break

        WinGetPos, wx, wy, ww, wh, ahk_id %hwnd%
        vienN := ww - cw
        vienD := wh - ch
        if (vienN < 0 || vienD < 0 || vienD > 200)
            return "Viền cửa sổ đo ra số vô lý (" . vienN . "×" . vienD . ")."

        ; CẢ VÙNG VẼ phải nằm trong màn hình, không riêng góc trên.
        ; Lưới túi đồ chạy tới x = 1851 và dải tab sát đỉnh; phần nào lọt
        ; ra ngoài thì PixelGetColor đọc không ra, mà rê chuột tới đó cũng
        ; không tới được.
        SysGet, manRong, 78
        SysGet, manCao, 79
        SysGet, manX, 76
        SysGet, manY, 77
        if (gx < manX)
            wx += manX - gx
        if (gy < manY)
            wy += manY - gy
        if (gx + CLIENT_W > manX + manRong)
            wx -= (gx + CLIENT_W) - (manX + manRong)
        if (gy + CLIENT_H > manY + manCao)
            wy -= (gy + CLIENT_H) - (manY + manCao)

        WinMove, ahk_id %hwnd%, , %wx%, %wy%
                , % CLIENT_W + vienN, % CLIENT_H + vienD
        Sleep, 550
        i++
    }

    if (!VungVe(gx, gy, cw, ch, dk))
        return "Không đọc được kích thước cửa sổ Diablo IV."
    if (cw != CLIENT_W || ch != CLIENT_H)
        return "Chỉnh không được: vùng vẽ vẫn là " . cw . "×" . ch
             . " chứ không phải " . CLIENT_W . "×" . CLIENT_H . "."
             . "`nGame tự nắn lại cỡ cửa sổ. Thử đổi độ phân giải trong"
             . " Options > Graphics về 1920×1080, chế độ Windowed."
    return ""
}


KiemCuaSoGame(ByRef gx, ByRef gy, ByRef cw, ByRef ch)
{
    global
    local hwnd, tt

    WinGet, hwnd, ID, ahk_exe Diablo IV.exe
    if (!hwnd)
        return "Không thấy cửa sổ Diablo IV."
             . "`nGame chưa bật, hoặc game chạy bằng quyền Quản trị mà"
             . " D4Lister thì không — khi đó Windows giấu cửa sổ game đi."

    WinGet, tt, MinMax, ahk_id %hwnd%
    if (tt = -1)
        return "Cửa sổ Diablo IV đang thu nhỏ dưới thanh tác vụ."
             . "`nMở game lên rồi bấm lại."

    if (!VungVe(gx, gy, cw, ch))
        return "Không đọc được kích thước cửa sổ Diablo IV."

    return LoiCoVungVe(cw, ch)
}

;   Cỡ vùng vẽ có đúng không, và nếu sai thì nhiều khả năng vì sao.
;   Tách riêng để thử được mọi nhánh mà không phải bật game lên đổi
;   chế độ màn hình từng kiểu một.
LoiCoVungVe(cw, ch)
{
    global
    if (cw = CLIENT_W && ch = CLIENT_H)
        return ""

    ; "Sai cỡ" trống không thì người dùng chẳng biết phải sửa gì. Đoán giúp.
    if (cw = CLIENT_W && ch = 1080)
        return "Game đang ở chế độ Toàn màn hình (vùng vẽ " . cw . "×" . ch . ")."
             . "`nMọi toạ độ của F2 đo ở chế độ CỬA SỔ, nên sẽ rê trượt ô."
             . "`nVào Options > Graphics, đổi Display Mode sang Windowed."
    if (cw < CLIENT_W || ch < CLIENT_H)
        return "Cửa sổ game đang nhỏ hơn cỡ đầy đủ (vùng vẽ "
             . cw . "×" . ch . ")."
             . "`nBấm F2, nó sẽ hỏi chỉnh giúp cho đúng "
             . CLIENT_W . "×" . CLIENT_H . "."
    return "Vùng vẽ của game là " . cw . "×" . ch . ", cần "
         . CLIENT_W . "×" . CLIENT_H . "."
         . "`nBấm F2, nó sẽ hỏi chỉnh giúp. Vẫn cần màn hình 1920×1080"
         . " và game ở chế độ Cửa sổ."
}


; dk = cách chỉ ra cửa sổ. Để mặc định là game; đặt khác chỉ dùng lúc chạy thử.
VungVe(ByRef gx, ByRef gy, ByRef rong, ByRef cao, dk := "ahk_exe Diablo IV.exe")
{
    WinGet, hwnd, ID, %dk%
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
;   xTrong  = một điểm trong panel chắc chắn KHÔNG có món, để rê ra cho
;             game xoá tooltip trước khi hỏi lại.
;   monTruoc = nội dung ô liền trước, dùng để phát hiện đọc nhầm.
QuetMotO(x, y, ByRef huy, choMs, ByRef msCho, xTrong, monTruoc := "")
{
    global
    local mon

    ; Con trỏ đang đứng sẵn ở đây thì MouseMove không phải là một cú di
    ; chuyển, game chẳng có cớ gì gửi lại tooltip — ô có đồ hoá ra ô trống.
    MouseGetPos, mx, my
    if (Abs(mx - x) <= LECH_CHUOT && Abs(my - y) <= LECH_CHUOT)
    {
        MouseMove, %xTrong%, %y%, 0
        Sleep, 40
    }

    mon := HoiMotO(x, y, huy, choMs, msCho)
    if (huy != "" || mon = "")
        return mon

    ; Đọc ra đúng y món của ô liền trước thì có hai khả năng, mà hậu quả
    ; khác hẳn nhau:
    ;   - tooltip của ô TRƯỚC về muộn, bị tính nhầm cho ô này  -> đọc sai
    ;   - hai món giống hệt nhau nằm cạnh nhau (hai nhẫn cùng chỉ số)
    ;                                                          -> đúng thật
    ; Không đoán. Rê ra chỗ trống cho game xoá tooltip rồi hỏi lại — lần
    ; này thứ nhận được chắc chắn là của ô này.
    if (mon = monTruoc)
    {
        g_TK.hoiLai++
        MouseMove, %xTrong%, %y%, 0
        Sleep, 70
        mon := HoiMotO(x, y, huy, choMs, msCho)
    }
    return mon
}

;   Rê tới một ô rồi chờ tooltip. Trả về "" nếu ô trống hoặc bị huỷ.
HoiMotO(x, y, ByRef huy, choMs, ByRef msCho)
{
    global
    local het, batDau

    g_MonCuoi := ""
    g_TenCuoi := ""
    g_Dem := []
    VetOng()            ; vét sạch phần còn đọng của ô trước
    g_MonCuoi := ""
    g_Dem := []

    MouseMove, %x%, %y%, 0

    msCho   := 0
    batDau  := A_TickCount
    het     := batDau + choMs
    if (TTS_LOG)
        GhiTho("===== RÊ TỚI (" . x . "," . y . ") · chờ tối đa " . choMs . "ms")
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
        {
            ; Ghi rõ ô này IM. Không ghi thì trong file thô nó y hệt một ô
            ; trống thật — mà hai chuyện đó khác nhau một trời một vực.
            if (TTS_LOG)
                GhiTho("===== IM LẶNG hết " . choMs . "ms, coi như ô trống"
                     . (g_Dem.Length() ? "  (đệm còn " . g_Dem.Length() . " câu dở)" : ""))
            return ""       ; ô trống
        }
        Sleep, 15
    }
    msCho := A_TickCount - batDau
    if (msCho > g_TK.msMax)
        g_TK.msMax := msCho

    ; Tooltip có thể còn đang về dở — đợi nốt một nhịp ngắn
    Sleep, 25
    VetOng()
    return g_MonCuoi
}


;=====================================================================
;   SỔ SÁCH MỘT LƯỢT QUÉT
;
;   Quét hàng loạt mà im lặng thì không ai dám tin: ô im lặng là ô trống
;   thật, hay là tooltip về chậm một nhịp rồi mình ghi nhầm thành trống?
;   Nên mọi ô đều có dòng trong sổ, và cuối lượt đối chiếu được.
;=====================================================================
GhiLog(chu)
{
    global
    FileAppend, %chu%`n, %FILE_LOG_QUET%, UTF-8-RAW
}

;   Ghi chữ THÔ do bộ đọc màn hình gửi về, kèm mốc thời gian.
;
;   Không có mốc thời gian thì file này không trả lời được câu hỏi quan
;   trọng nhất: rê chuột xong bao lâu thì câu đầu về, và một tooltip mất
;   bao lâu mới về hết. Bản trước chỉ ghi trơ mỗi câu chữ.
;
;   Mốc phụ là A_TickCount: giờ đồng hồ chỉ tới giây, mà khoảng cần đo ở
;   đây tính bằng chục mili-giây.
GhiTho(chu)
{
    global
    FileAppend, % A_Hour . ":" . A_Min . ":" . A_Sec . "." . A_MSec
              . "  +" . A_TickCount . "  " . chu . "`n"
              , % QUEUE_DIR . "\_tts.log", UTF-8-RAW
}

TenO(r, c)
{
    return "h" . (r + 1) . "c" . (c + 1)
}

TenMonTu(mon)
{
    local d
    Loop, Parse, mon, `n, `r
    {
        d := Trim(A_LoopField)
        if (d != "")
            return d
    }
    return "(không rõ tên)"
}


;=====================================================================
;   XỬ LÝ MỘT MÓN ĐỌC ĐƯỢC
;
;   Ba ngả kết thúc, và cả ba đều phải vào sổ. Trước đây món "đọc được
;   nhưng không hiểu" bị bỏ im — đúng kiểu sót mà không ai hay.
;=====================================================================
XuLyMon(mon, noi, r, c, ms, laDoLai)
{
    global
    local chu, kq, nhan, tenMon

    g_TK.coDo++
    tenMon := TenMonTu(mon)
    chu    := LocMonTTS(mon)
    if (chu = "")
    {
        g_TK.khongHieu++
        GhiLog("  " . TenO(r, c) . "  !! ĐỌC ĐƯỢC NHƯNG KHÔNG HIỂU: " . tenMon)
        GhiLog("        nguyên văn: " . StrReplace(StrReplace(mon, "`r", ""), "`n", " / "))
        return
    }

    kq := ThemVaoHangDoi(chu, mon, noi, r, c)
    if (kq = "moi")
    {
        g_TK.moi++
        nhan := "mới"
        ShowMsg("✔ " . tenMon . "`nđã lấy " . g_TK.moi . " món   ·   Esc để dừng", "ok")
    }
    else if (kq = "trung")
    {
        g_TK.trung++
        nhan := "trùng"
    }
    else
    {
        g_TK.loi++
        nhan := "!! GHI FILE HỎNG"
    }
    GhiLog("  " . TenO(r, c) . "  " . tenMon . "   [" . nhan . "]  " . ms . "ms"
         . (laDoLai ? "   (cứu ở lượt dò lại)" : ""))
}


;=====================================================================
;   QUÉT MỘT LƯỚI
;=====================================================================
QuetLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang, ten, ByRef huy)
{
    global
    local r, c, i, o, tx, ty, mon, ms, imLang, cuu, xTrong, monTruoc
    local nhinThay, soNhin, daDoc, thieu, thua

    ; Điểm không có món, để rê ra cho game xoá tooltip. Nằm trong nền
    ; panel, bên trái lưới rương — chỗ đó không bao giờ có ô đồ.
    xTrong := gx + RUONG_X - 20
    monTruoc := ""

    ; --- NHÌN TRƯỚC KHI RÊ ---
    ; Rê chuột ra chỗ trống và đợi tooltip tắt hẳn, rồi mới chụp: tooltip
    ; của game che mất mấy ô bên cạnh, chụp lúc đó là đếm thiếu.
    MouseMove, %xTrong%, % gy + Round(y0), 0
    Sleep, 220
    nhinThay := NhinCaLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang, soNhin)
    daDoc := {}

    ; --- CÓ ĐƯỢC PHÉP BỎ QUA Ô TRỐNG KHÔNG ---
    ; Chỉ khi người dùng bật, VÀ lưới nằm đúng chỗ. Toạ độ lưới đo trên một
    ; máy; máy khác cỡ cửa sổ khác thì panel túi đồ xê dịch. Bỏ qua dựa trên
    ; toạ độ sai là mất món mà không ai biết — nên đo lại tại chỗ, lệch quá
    ; thì thà rê đủ còn hơn.
    boQua := 0
    duocBoQua := false
    if (g_BoQuaOTrong && nhinThay.Length() > 0)
    {
        lechLuoi := LechViTriLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang)
        if (lechLuoi >= 0 && lechLuoi <= 6)
            duocBoQua := true
        else
        {
            GhiLog("  !! không bỏ qua ô trống: lưới lệch " . lechLuoi
                 . " px so với chỗ mong đợi — rê đủ mọi ô cho chắc")
            g_TK.canhLuoi++
        }

        ; LỚP CHẮN THỨ HAI, độc lập với phép đo vị trí ở trên.
        ; Phép đo vị trí có thể bị lừa — đã gặp. Nên rê thử vài ô mà mình
        ; ĐỊNH BỎ QUA: nếu một ô trong đó lại ra món thì phép nhìn sai, bỏ
        ; luôn ý định bỏ qua và rê đủ mọi ô.
        if (duocBoQua)
        {
            if (!ThuVaiOTrong(gx, gy, x0, y0, ow, oh, soCot, soHang
                            , nhinThay, huy, xTrong))
            {
                duocBoQua := false
                g_TK.canhLuoi++
                GhiLog("  !! rê thử ô trống lại ra món — phép nhìn sai,"
                     . " rê đủ mọi ô")
            }
            if (huy != "")
                duocBoQua := false
        }
    }

    GhiLog("")
    GhiLog("--- " . ten . "  (" . soHang . "×" . soCot . " = " . (soHang * soCot) . " ô) ---")
    if (duocBoQua && soNhin = 0)
        GhiLog("  nhìn không thấy ô nào có đồ — sẽ bỏ qua cả lưới")
    imLang := []

    r := 0
    while (r < soHang)
    {
        ; Báo tiến độ MỖI HÀNG, không phải mỗi ô: ShowMsg dựng lại cả cửa
        ; sổ GUI nên gọi 83 lần một lượt thì vừa chậm vừa nhấp nháy.
        ShowMsg(ten . " — hàng " . (r + 1) . "/" . soHang
            . "`nđã lấy " . g_TK.moi . " món   ·   Esc để dừng", "warn")
        c := 0
        while (c < soCot)
        {
            tx := gx + Round(x0 + ow * (c + 0.5))
            ty := gy + Round(y0 + oh * (r + 0.5))

            ; Ô nhìn không thấy gì -> bỏ qua, khỏi rê. Ngưỡng ở đây THẤP hơn
            ; ngưỡng báo cáo: thà rê thừa vài ô còn hơn sót một món.
            if (duocBoQua && nhinThay[r * soCot + c] < O_RE)
            {
                boQua++
                g_TK.boQua++
                c++
                continue
            }

            g_TK.oRe++
            mon := QuetMotO(tx, ty, huy, CHO_O_MS, ms, xTrong, monTruoc)
            if (huy != "")
                break
            monTruoc := mon
            if (mon = "")
                imLang.Push([r, c, tx, ty])
            else
            {
                daDoc[r * soCot + c] := true
                XuLyMon(mon, ten, r, c, ms, false)
            }
            c++
        }
        if (huy != "")
            break
        r++
    }

    ; LƯỢT HAI. Ô im lặng có thể là ô trống thật, cũng có thể là tooltip về
    ; chậm hơn ngưỡng chờ — mà cái sau thì mất luôn món đồ, im ru. Hỏi lại
    ; một lần với ngưỡng gấp ba: thà chậm còn hơn sót.
    ;
    ; KHÔNG return ở giữa hàm này nữa, dù huỷ hay không có ô nào im lặng.
    ; Trước đây có, và thế là mất luôn phần đối chiếu ở cuối: tắt "dò lại
    ; ô im lặng" là sơ đồ lưới biến mất, mà chẳng có dấu hiệu gì.
    if (huy = "" && g_DoLai && imLang.Length() > 0)
    {
        ShowMsg(ten . " — dò lại " . imLang.Length() . " ô im lặng…", "warn")
        cuu := 0
        for i, o in imLang
        {
            mon := QuetMotO(o[3], o[4], huy, CHO_O_MS * 3, ms, xTrong)
            if (huy != "")
                break
            if (mon = "")
            {
                g_TK.oTrong++
                GhiLog("  " . TenO(o[1], o[2]) . "  trống")
            }
            else
            {
                cuu++
                g_TK.cuuDuoc++
                daDoc[o[1] * soCot + o[2]] := true
                XuLyMon(mon, ten, o[1], o[2], ms, true)
            }
        }
        if (cuu > 0)
            GhiLog("  >> lượt dò lại cứu được " . cuu
                 . " món mà lượt đầu tưởng là ô trống")
    }
    else
    {
        for i, o in imLang
        {
            g_TK.oTrong++
            GhiLog("  " . TenO(o[1], o[2]) . "  trống")
        }
    }

    ; LƯỢT VÉT SÓT — chạy TRƯỚC phép đối chiếu.
    ;
    ; Khác hẳn "dò lại ô im lặng" ở trên. Chỗ kia mới là NGỜ: ô im lặng có
    ; thể trống thật. Chỗ này đã có BẰNG CHỨNG — ảnh chụp nói ô đó có đồ mà
    ; chữ thì không ra.
    ;
    ; Trước đây phép đối chiếu chỉ GHI SỔ rồi thôi: chương trình biết chắc
    ; nó vừa đánh rơi ba món và vẫn đi tiếp, im ru. Người dùng quét túi đồ
    ; 13 món năm lượt ra 10 / 13 / 13 / 10 / 12 — đúng vì chuyện này.
    ;
    ; Chạy bất kể công tắc "dò lại": công tắc đó để đánh đổi nhanh/chắc khi
    ; còn NGỜ, còn đây là đã biết mình thiếu.
    if (huy = "")
        VetOSot(gx, gy, x0, y0, ow, oh, soCot, soHang, ten
              , nhinThay, daDoc, huy, xTrong)

    DoiChieuNhinVaDoc(nhinThay, daDoc, soNhin, soCot, soHang, ten)
}

;=====================================================================
;   VÉT LẠI NHỮNG Ô "NHÌN THẤY CÓ ĐỒ MÀ KHÔNG ĐỌC RA"
;
;   Nới ngưỡng chờ dần theo lượt (gấp ba, gấp sáu, gấp chín): tooltip về
;   muộn là lý do hay gặp nhất, mà nới cho MỌI ô thì cả lượt quét chậm đi
;   hẳn — chỉ nới cho mấy ô thật sự cần.
;
;   Dừng sớm khi một lượt không cứu thêm được món nào: ô đó im vì lý do
;   khác, quay lại mấy lần nữa cũng thế.
;=====================================================================
VetOSot(gx, gy, x0, y0, ow, oh, soCot, soHang, ten
      , nhinThay, daDoc, ByRef huy, xTrong)
{
    global
    local vong, con, i, o, r, c, tx, ty, mon, ms, cuu, tongCuu, cho, k

    tongCuu := 0
    vong    := 0
    while (vong < VET_SOT_VONG && huy = "")
    {
        con := []
        k := 0
        while (k < soCot * soHang)
        {
            if (nhinThay[k] >= O_NGUONG && !daDoc[k])
                con.Push(k)
            k++
        }
        if (con.Length() = 0)
            break

        vong++
        cho := CHO_O_MS * 3 * vong
        ShowMsg(ten . " — vét " . con.Length() . " ô còn sót"
            . "`nlượt " . vong . "/" . VET_SOT_VONG . "   ·   Esc để dừng", "warn")
        GhiLog("  -- vét sót lượt " . vong . ": còn " . con.Length()
             . " ô, chờ mỗi ô " . cho . "ms")

        cuu := 0
        for i, o in con
        {
            r  := o // soCot
            c  := Mod(o, soCot)
            tx := gx + Round(x0 + ow * (c + 0.5))
            ty := gy + Round(y0 + oh * (r + 0.5))
            mon := QuetMotO(tx, ty, huy, cho, ms, xTrong)
            if (huy != "")
                break
            if (mon = "")
            {
                GhiLog("  " . TenO(r, c) . "  vẫn im sau " . cho . "ms")
                continue
            }
            daDoc[o] := true
            cuu++
            g_TK.cuuDuoc++
            XuLyMon(mon, ten, r, c, ms, true)
        }
        tongCuu += cuu
        GhiLog("  -- vét sót lượt " . vong . ": cứu được " . cuu . " món")
        if (cuu = 0)
            break
    }
    if (tongCuu > 0)
        GhiLog("  >> vét sót cứu tổng cộng " . tongCuu . " món")
}


;=====================================================================
;   RÊ THỬ VÀI Ô ĐỊNH BỎ QUA
;
;   Trả về false nếu một ô "nhìn thấy trống" lại ra món — tức phép nhìn
;   sai, không được bỏ qua ô nào nữa.
;
;   Chọn ô rải đều khắp lưới chứ không lấy mấy ô đầu: lưới lệch thì sai
;   không rải đều, mà dồn về một phía.
;=====================================================================
ThuVaiOTrong(gx, gy, x0, y0, ow, oh, soCot, soHang, nhinThay, ByRef huy, xTrong)
{
    global
    local tong, buoc, i, k, r, c, tx, ty, mon, ms, ds, soThu

    ds := []
    tong := soCot * soHang
    k := 0
    while (k < tong)
    {
        if (nhinThay[k] < O_RE)
            ds.Push(k)
        k++
    }
    if (ds.Length() = 0)
        return true

    soThu := SO_O_THU_LAI
    if (soThu > ds.Length())
        soThu := ds.Length()
    buoc := ds.Length() / soThu

    i := 0
    while (i < soThu)
    {
        k := ds[Floor(i * buoc) + 1]
        r := k // soCot
        c := Mod(k, soCot)
        tx := gx + Round(x0 + ow * (c + 0.5))
        ty := gy + Round(y0 + oh * (r + 0.5))
        g_TK.oRe++
        g_TK.thuLai++
        mon := QuetMotO(tx, ty, huy, CHO_O_MS, ms, xTrong)
        if (huy != "")
            return true
        if (mon != "")
        {
            GhiLog("  !! " . TenOVi(r, c) . " nhìn thấy trống mà lại ra món:"
                 . " " . TenMonTu(mon))
            return false
        }
        i++
    }
    return true
}


;=====================================================================
;   LƯỚI CÓ NẰM ĐÚNG CHỖ KHÔNG
;
;   Trả về số px lệch giữa chỗ TÌM ĐƯỢC và chỗ đang dùng, lấy cái lớn hơn
;   trong hai chiều. Trả về -1 nếu không đo được.
;
;   Chỉ gọi khi người dùng bật "bỏ qua ô trống". Bỏ qua mà toạ độ lệch thì
;   mất món im lặng, nên phải đo lại tại chỗ chứ đừng tin hằng số.
;=====================================================================
LechViTriLuoi(gx, gy, x0, y0, ow, oh, soCot, soHang)
{
    global
    local anh, ket, p, lx, ly

    anh := ChupVung(gx + Round(x0) - 60, gy + Round(y0) - 60
                  , Round(ow * soCot) + 120, Round(oh * soHang) + 120)
    if (!anh)
        return -1

    ; Quét rộng ±26 px. Từng để ±16 và sập: lưới lệch 20 px nằm NGOÀI tầm
    ; quét, nên nó báo "lệch 3 px" — sai mà lại còn nghe có vẻ yên tâm.
    ket := LuocDoc(anh, gx + Round(x0) - 26, gx + Round(x0) + 26, ow, soCot + 1
                 , gy + Round(y0) + 20, gy + Round(y0 + oh * soHang) - 20)
    StringSplit, p, ket, |
    lx := Abs(p1 - gx - Round(x0))

    ket := LuocNgang(anh, gy + Round(y0) - 26, gy + Round(y0) + 26, oh, soHang + 1
                   , gx + Round(x0) + 20, gx + Round(x0 + ow * soCot) - 20)
    StringSplit, p, ket, |
    ly := Abs(p1 - gy - Round(y0))

    XoaAnh(anh)
    return (lx > ly) ? lx : ly
}


;=====================================================================
;   ĐỐI CHIẾU: NHÌN THẤY vs ĐỌC ĐƯỢC
;
;   Đây là thứ trước đây thiếu. TTS im lặng thì chỉ biết "không có gì",
;   không biết là ô trống thật hay đọc hụt. Giờ có hai nguồn độc lập nên
;   chỉ được đúng ô nào đáng ngờ.
;
;   Hai chiều lệch, ý nghĩa khác hẳn nhau:
;     nhìn thấy mà không đọc được -> SÓT MÓN, chỉ rõ ô cho người dùng kiểm
;     đọc được mà không nhìn thấy -> toạ độ lệch, hoặc luật nhìn ô sai
;=====================================================================
DoiChieuNhinVaDoc(nhinThay, daDoc, soNhin, soCot, soHang, ten)
{
    global
    local r, c, k, thieu, thua, dayDu, nThieu, nThua

    if (!IsObject(nhinThay) || nhinThay.Length() = 0)
    {
        GhiLog("  (không nhìn được lưới bằng điểm ảnh — bỏ phép đối chiếu)")
        return
    }

    ; Bản đồ trạng thái từng ô, để vẽ sơ đồ trong báo cáo:
    ;   0 trống · 1 đọc được · 2 nhìn thấy có đồ mà không đọc ra
    g_OTrangThai := []
    g_OCot  := soCot
    g_OHang := soHang

    thieu := "", thua := "", dayDu := "", nThieu := 0, nThua := 0
    r := 0
    while (r < soHang)
    {
        c := 0
        while (c < soCot)
        {
            k := r * soCot + c
            g_OTrangThai[k] := daDoc[k] ? 1 : ((nhinThay[k] >= O_NGUONG) ? 2 : 0)
            if (nhinThay[k] >= O_NGUONG && !daDoc[k])
            {
                nThieu++
                ; Chỉ kể tên vài ô đầu. Một lưới hỏng cả 23 ô mà kể hết thì
                ; bảng báo cáo rộng 2042 px — rộng hơn màn hình. Sơ đồ lưới
                ; và sổ ghi mới là chỗ xem đủ.
                dayDu .= (dayDu = "" ? "" : ", ") . TenOVi(r, c)
                if (nThieu <= SOT_KE_TOI_DA)
                    thieu .= (thieu = "" ? "" : ", ") . TenOVi(r, c)
                else if (nThieu = SOT_KE_TOI_DA + 1)
                    thieu .= " …"
            }
            else if (nhinThay[k] < O_NGUONG && daDoc[k])
            {
                nThua++
                thua .= (thua = "" ? "" : ", ") . TenOVi(r, c)
            }
            c++
        }
        r++
    }

    GhiLog("  = " . ten . ": nhìn thấy " . soNhin . " ô có đồ, đọc được "
         . (soNhin - nThieu) . "")
    if (nThieu > 0)
    {
        GhiLog("  !! SÓT " . nThieu . " ô — nhìn thấy có đồ mà không đọc ra chữ:")
        GhiLog("     " . dayDu)
        g_TK.sot += nThieu
        g_TK.oSot .= (g_TK.oSot = "" ? "" : "`n   ") . ten . ": " . thieu
                   . (nThieu > SOT_KE_TOI_DA
                      ? "  (" . nThieu . " ô, xem sơ đồ)" : "")
    }
    if (nThua > 0)
        GhiLog("  ?? " . nThua . " ô đọc ra chữ mà nhìn không thấy đồ: " . thua
             . "  (toạ độ có thể lệch)")

    g_TK.nhin += soNhin
}


;=====================================================================
;   DỰNG BÁO CÁO CUỐI LƯỢT
;
;   Tách khỏi F2 để gọi thử được mà không cần mở game.
;=====================================================================
; Số giây báo cáo ở lại trên màn. Trả về 0 nghĩa là GIỮ MÃI cho tới khi
; người dùng bấm Esc — mặc định là vậy, vì bảng này là thứ duy nhất cho
; biết có sót món nào không, tự tắt mất thì coi như chưa từng đọc.
GiayBaoCao()
{
    global
    return g_TuDat ? g_Giay : 0
}

DungBaoCao(huy, ngoTab, ByRef loai)
{
    global
    local vanDe, ghiChu, bc, i, d
    ; VẤN ĐỀ làm cả báo cáo đỏ. GHI CHÚ thì không.
    ; Phân biệt chỗ này quan trọng: tắt "dò lại ô im lặng" là lựa chọn của
    ; người dùng, không phải sự cố. Đỏ vì chuyện bình thường thì vài hôm là
    ; quen mắt, rồi đỏ thật cũng bỏ qua nốt.
    vanDe  := ""
    ghiChu := ""
    if (huy != "")
        vanDe .= "`n⚠ Dừng giữa chừng: " . huy
    if (ngoTab != "")
        vanDe .= "`n⚠ Tab " . ngoTab . " có đồ mà không món nào mới"
               . " — ngờ bấm hụt tab"
    if (g_TK.khongHieu > 0)
        vanDe .= "`n⚠ " . g_TK.khongHieu . " món không đọc hiểu được"
    if (g_TK.loi > 0)
        vanDe .= "`n⚠ " . g_TK.loi . " món ghi file hỏng"
    if (g_TK.sot > 0)
        vanDe .= "`n⚠ SÓT " . g_TK.sot . " ô — nhìn thấy có đồ mà không đọc ra:"
               . "`n   " . g_TK.oSot

    if (g_TK.boQua > 0)
        ghiChu .= "`n· Bỏ qua " . g_TK.boQua . " ô nhìn thấy trống"
    if (g_TK.canhLuoi > 0)
        vanDe .= "`n⚠ " . g_TK.canhLuoi . " lưới nằm lệch chỗ — đã rê đủ mọi ô,"
               . " không bỏ qua ô nào"
    if (g_TK.cuuDuoc > 0)
        ghiChu .= "`n· Dò lại cứu được " . g_TK.cuuDuoc . " món suýt bị bỏ sót"

    loai := (vanDe = "" ? "ok" : "err")
    bc := (huy != "" ? "ĐÃ DỪNG GIỮA CHỪNG"
        : vanDe = "" ? "QUÉT XONG" : "QUÉT XONG — CẦN XEM LẠI")
    bc .= "`n" . g_TK.moi . " món mới"
    if (g_TK.trung > 0)
        bc .= "  ·  " . g_TK.trung . " trùng"
    bc .= "`nĐọc được " . g_TK.coDo . "/" . g_TK.nhin . " ô có đồ"

    ; Tách theo từng nơi, và so ĐỌC ĐƯỢC với NHÌN THẤY. Con số tổng chẳng
    ; đối chiếu được với cái gì; "Tab 1: 29/30" thì thấy ngay là thiếu một.
    ;
    ; Bật sơ đồ lưới thì BỎ mấy dòng này: lưới đã ghi sẵn cùng con số ngay
    ; dưới tên mỗi lưới, in thêm lần nữa chỉ tổ dài.
    if (!g_HienLuoi)
        for i, d in g_TK.chiTiet
            bc .= "`n      " . d.ten . ":  " . d.coDo . "/" . d.nhin

    bc .= "`nĐang chờ đăng: " . g_Items.Length() . " món"
    bc .= ghiChu
    ; Vấn đề nằm cuối, ngay cạnh chỗ tra cứu — đó là nơi mắt dừng lại.
    if (vanDe != "")
        bc .= "`n" . vanDe . "`nChi tiết từng ô: nhat-ky-quet.txt"

    return bc
}


;=====================================================================
;   HOTKEY: F2  -  QUÉT HÀNG LOẠT
;=====================================================================
DoQuet:
    if (g_Busy || g_DangQuet)
        return
    HideMsgNow()
    ; Ẩn dấu xanh đi đã: nó nằm ĐÈ LÊN rương, mà cả F2 lẫn F10 đều đọc
    ; rương bằng ảnh chụp màn hình — để nguyên là ô trống nào có dấu
    ; cũng bị đọc thành ô có đồ. Đồng hồ TheoDoiTabDau vẽ lại sau.
    AnDauXanh()

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
    loiCuaSo := KiemCuaSoGame(gx, gy, cw, ch)
    if (loiCuaSo != "" && cw > 0 && ch > 0 && (cw != CLIENT_W || ch != CLIENT_H))
    {
        ; Sai cỡ thì chỉnh hộ được — nhưng HỎI trước. Đây là cửa sổ game
        ; đang chạy của người ta, tự ý kéo co là chuyện không nên làm im.
        ;
        ; Khoá F2 NGAY: hộp thoại hỏi chặn luồng này, mà phím tắt thì vẫn
        ; nhận — không khoá thì bấm F2 lần nữa là mở chồng hộp thoại thứ hai.
        g_DangQuet := true
        HideMsgNow()
        MsgBox, 0x34, D4Lister
            , % loiCuaSo . "`n`nChỉnh giúp cỡ cửa sổ luôn không?"
            . "`n(Chỉ đổi cỡ cửa sổ, không đụng thiết lập nào của game.)"
        IfMsgBox, No
        {
            g_DangQuet := false
            return
        }
        loiCuaSo := ChinhCoCuaSo()
        if (loiCuaSo = "")
        {
            loiCuaSo := KiemCuaSoGame(gx, gy, cw, ch)
            if (loiCuaSo = "")
                ShowMsg("Đã chỉnh cửa sổ về " . CLIENT_W . "×" . CLIENT_H, "ok")
        }
        g_DangQuet := false
    }
    if (loiCuaSo != "")
    {
        ShowMsg(loiCuaSo, "err", 6000)
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
    WinActivate, ahk_exe Diablo IV.exe
    WinWaitActive, ahk_exe Diablo IV.exe,, 2
    if (ErrorLevel)
    {
        ShowMsg("Không đưa được cửa sổ Diablo IV lên trước", "err")
        g_DangQuet := false
        return
    }
    Sleep, 250                         ; chờ game vẽ lại rồi mới rê

    ; Ghim thông báo lên đỉnh cửa sổ game, căn giữa — đặt trước cả lúc đếm
    ; ngược để con số đứng yên một chỗ ngay từ đầu.
    g_GhimX := gx + cw // 2
    g_GhimY := gy + 36

    ; Đếm ngược trước khi rê. Đặt TRƯỚC lúc kiểm rương, không phải sau:
    ; mấy giây này chính là lúc người dùng kịp mở rương ra.
    if (g_ChoTruoc)
    {
        conLai := g_GiayCho
        while (conLai > 0)
        {
            if (GetKeyState("Escape", "P"))
            {
                ShowMsg("Đã huỷ", "warn")
                g_GhimX := -1, g_GhimY := -1
                g_DangQuet := false
                return
            }
            ShowMsg("BẮT ĐẦU SAU " . conLai . " GIÂY`nEsc để huỷ", "warn", 1200)
            Sleep, 1000
            conLai--
        }
        HideMsgNow()
    }

    ; Kiểm lại cửa sổ. Hộp thoại mở bao lâu là tuỳ người dùng, và trong
    ; từng ấy thời gian họ có thể đã đổi chế độ màn hình hoặc kéo cửa sổ.
    loiCuaSo := KiemCuaSoGame(gx, gy, cw, ch)
    if (loiCuaSo != "")
    {
        ShowMsg(loiCuaSo, "err", 6000)
        g_GhimX := -1, g_GhimY := -1
        g_DangQuet := false
        return
    }

    ; Rương chưa mở thì mọi toạ độ bên dưới đều trỏ vào thế giới, rê qua
    ; 83 ô chỉ tổ mất công — mà bấm đổi tab còn làm nhân vật chạy đi.
    if (!RuongDangMo(gx, gy))
    {
        ShowMsg("CHƯA MỞ RƯƠNG`nMở rương trong game rồi bấm F2 lại.", "err")
        g_GhimX := -1, g_GhimY := -1
        g_DangQuet := false
        return
    }

    g_Busy := true
    MouseGetPos, chuotX, chuotY
    RefreshForCapture()

    huy := ""
    ngoTab := ""                   ; tab nào ngờ là bấm hụt
    g_TK := {oRe: 0, coDo: 0, moi: 0, trung: 0, loi: 0
           , khongHieu: 0, oTrong: 0, cuuDuoc: 0, msMax: 0, hoiLai: 0
           , chiTiet: [], nhin: 0, sot: 0, oSot: ""
           , boQua: 0, canhLuoi: 0, thuLai: 0}
    SetTimer, DocOng, Off          ; chỉ một nơi được đọc đường ống

    FormatTime, gioBatDau,, dd/MM/yyyy HH:mm:ss
    GhiLog("")
    GhiLog("========================================================")
    GhiLog("LƯỢT QUÉT " . gioBatDau)
    GhiLog("  rương " . g_SoTab . " tab · quét tab [" . dsTab . "]"
         . (g_QuetTui ? " + túi đồ" : "") . " · lệch ngang " . g_LechTab . "px"
         . " · dò lại ô im lặng: " . (g_DoLai ? "có" : "không"))

    ; --- các tab rương ---
    Loop, Parse, dsTab, `,
    {
        if (huy != "")
            break
        ; Tên riêng, không dùng lại i. Vòng lặp này gọi qua cả chục hàm;
        ; chỉ cần MỘT hàm ở phạm vi toàn cục đụng vào i là số tab hỏng.
        soTabNay := A_LoopField + 0
        i := soTabNay
        tabX := TamTab(soTabNay, g_SoTab)
        if (tabX < 0)
            continue
        tabX += gx
        tabY := gy + TAB_Y
        ShowMsg("Đổi sang tab " . soTabNay . "…", "warn")
        MouseMove, %tabX%, %tabY%, 0
        Sleep, 60
        Click
        Sleep, %CHO_TAB_MS%

        truocCoDo := g_TK.coDo
        truocMoi  := g_TK.moi
        truocRe   := g_TK.oRe
        truocNhin := g_TK.nhin
        QuetLuoi(gx, gy, RUONG_X, RUONG_Y, RUONG_OW, RUONG_OH
               , RUONG_COT, RUONG_HANG, "Rương tab " . soTabNay, huy)
        tabCoDo := g_TK.coDo - truocCoDo
        tabMoi  := g_TK.moi  - truocMoi
        g_TK.chiTiet.Push({ten: "Tab " . soTabNay, coDo: tabCoDo
                         , oRe: g_TK.oRe - truocRe
                         , nhin: g_TK.nhin - truocNhin
                         , o: g_OTrangThai, cot: g_OCot, hang: g_OHang})
        GhiLog("  = tab " . soTabNay . ": " . tabCoDo . " ô có đồ, " . tabMoi . " món mới")

        ; Bấm hụt dải tab thì game vẫn hiện tab cũ, và ta quét lại y nguyên
        ; tab vừa rồi — mọi món đều "trùng". Không có cách nào nhìn thấy điều
        ; đó, nhưng dấu vết thì rõ: có đồ mà tuyệt nhiên không món nào mới.
        if (tabCoDo > 0 && tabMoi = 0)
        {
            ngoTab .= (ngoTab = "" ? "" : ", ") . soTabNay
            GhiLog("  !! tab " . soTabNay . " không ra món mới nào — ngờ là bấm hụt tab")
        }
    }

    ; --- túi đồ ---
    if (huy = "" && g_QuetTui)
    {
        truocCoDo := g_TK.coDo
        truocRe   := g_TK.oRe
        truocNhin := g_TK.nhin
        QuetLuoi(gx, gy, TUI_X, TUI_Y, TUI_OW, TUI_OH
               , TUI_COT, TUI_HANG, "Túi đồ", huy)
        g_TK.chiTiet.Push({ten: "Túi đồ", coDo: g_TK.coDo - truocCoDo
                         , oRe: g_TK.oRe - truocRe
                         , nhin: g_TK.nhin - truocNhin
                         , o: g_OTrangThai, cot: g_OCot, hang: g_OHang})
    }

    MouseMove, %chuotX%, %chuotY%, 0
    SetTimer, DocOng, %NHIP_ONG%
    g_Busy := false
    g_DangQuet := false

    GhiLog("")
    GhiLog("TỔNG: rê " . g_TK.oRe . " ô · " . g_TK.coDo . " ô có đồ · "
         . g_TK.oTrong . " ô trống")
    GhiLog("      " . g_TK.moi . " món mới vào hàng đợi · " . g_TK.trung . " trùng"
         . " · " . g_TK.khongHieu . " không hiểu · " . g_TK.loi . " ghi hỏng")
    GhiLog("      lượt dò lại cứu " . g_TK.cuuDuoc . " món"
         . " · hỏi lại vì trùng ô trước " . g_TK.hoiLai . " lần"
         . " · tooltip chậm nhất " . g_TK.msMax . "ms / ngưỡng chờ " . CHO_O_MS . "ms")
    if (huy != "")
        GhiLog("      DỪNG GIỮA CHỪNG: " . huy)

    ; BÁO CÁO CUỐI LƯỢT. Giữ lâu hơn hẳn các tooltip khác — đây là thứ duy
    ; nhất cho biết có sót món nào không, đọc không kịp thì coi như không có.
    ; Vẫn ghim tại chỗ, không bám con trỏ.
    ;
    ; Chỉ hai màu: XANH là xong xuôi, ĐỎ là có chuyện cần nhìn. Cam ở giữa
    ; chỉ làm người ta lưỡng lự, mà lưỡng lự thì bỏ qua.
    ; GiayBaoCao() = 0 -> ShowMsg giữ nguyên bảng, chỉ Esc mới đóng.
    ShowMsg(DungBaoCao(huy, ngoTab, loaiBC), loaiBC, GiayBaoCao() * 1000, true
          , g_HienLuoi ? g_TK.chiTiet : "")
    g_GhimX := -1          ; hết lượt, tooltip bám con trỏ lại như thường
    g_GhimY := -1
return

;=====================================================================
;   THÊM MỘT MÓN VÀO HÀNG ĐỢI
;
;   Tách ra khỏi F3 để F2 dùng chung. Chống trùng bằng cách so NỘI DUNG
;   món, không phải "món cuối" như F3 — quét hàng loạt thì con trỏ đi qua
;   lại, rất dễ đọc lại một món đã có.
;=====================================================================
;   Khoá chống trùng là VỊ TRÍ Ô, không phải nội dung món.
;
;   Trước đây so nội dung trên cả lượt quét, và thế là sai: hai món giống
;   hệt nhau nằm ở hai ô khác nhau — hai chiếc nhẫn cùng chỉ số chẳng hạn —
;   là HAI MÓN, hai món hàng để bán. Món thứ hai bị vứt đi im lặng, đếm ra
;   thiếu mà chẳng ai biết vì sao.
;
;   Một ô chỉ chứa một món, nên vị trí ô mới là thứ xác định món. Kèm cả
;   nội dung vào khoá để quét lại lần nữa sau khi đã đổi đồ trong rương thì
;   vẫn nhận ra là món khác.
ThemVaoHangDoi(chu, monGoc, noi, r, c)
{
    global
    local khoa, f

    khoa := noi . "|" . r . "|" . c . "|" . monGoc
    if (g_DaQuet.HasKey(khoa))
        return "trung"

    f := QUEUE_DIR . "\" . SoTiepTheo() . ".txt"
    FileDelete, %f%
    FileAppend, %chu%, %f%, UTF-8-RAW
    if !FileExist(f)
        return "loi"

    if (!g_FreshCapture)
        g_BatchStart := g_Items.Length() + 1
    g_Items.Push(f)
    g_Cur := g_Items.Length()
    g_FreshCapture := true
    g_DaQuet[khoa] := true
    return "moi"
}


;=====================================================================
;   LỰA CHỌN QUÉT GÌ  —  đọc/ghi quet.ini
;
;   Hỏi trong hộp thoại F2 chứ không bắt sửa mã: mỗi buổi bạn muốn quét
;   tab khác nhau. Lưu vào quet.ini cạnh script nên lần sau mở vẫn nhớ.
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
    local v, dsTab, i
    IniRead, v, %FILE_CAU_HINH%, quet, soTab, 7
    g_SoTab := (v = 6) ? 6 : 7
    IniRead, v, %FILE_CAU_HINH%, quet, tui, 1
    g_QuetTui := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, dolai, 1
    g_DoLai := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, lech, 0
    g_LechTab := (v + 0 >= -60 && v + 0 <= 60) ? v + 0 : 0
    IniRead, v, %FILE_CAU_HINH%, quet, tudat, 0
    g_TuDat := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, giay, %GIAY_MAC_DINH%
    g_Giay := (v + 0 >= 3 && v + 0 <= 120) ? v + 0 : GIAY_MAC_DINH
    IniRead, v, %FILE_CAU_HINH%, quet, chotruoc, 0
    g_ChoTruoc := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, giaycho, 5
    g_GiayCho := (v + 0 >= 1 && v + 0 <= 30) ? v + 0 : 5
    IniRead, v, %FILE_CAU_HINH%, quet, luoi, 1
    g_HienLuoi := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, boqua, 0
    g_BoQuaOTrong := (v != 0)
    IniRead, v, %FILE_CAU_HINH%, quet, hoigia, 1
    g_HoiGia := (v != 0)
    ; Ghi nguyên văn từng dòng game đọc ra, vào queue\_tts.log. Chỉ bật lúc
    ; đi tìm lỗi đọc item — file này lớn dần mãi, không tự dọn.
    IniRead, v, %FILE_CAU_HINH%, quet, ttslog, 0
    TTS_LOG := (v != 0)
    ; Ghi sẵn mục [gia] ra file lần đầu. IniRead có giá trị mặc định nhưng
    ; không tạo khoá, mà không thấy trong file thì không ai biết là sửa được.
    IniRead, v, %FILE_CAU_HINH%, gia, donvi, %A_Space%
    if (Trim(v) = "")
        IniWrite, b, %FILE_CAU_HINH%, gia, donvi
    IniRead, v, %FILE_CAU_HINH%, gia, x, %A_Space%
    g_GiaX := (Trim(v) = "" || Trim(v) = "ERROR") ? "" : v + 0
    IniRead, v, %FILE_CAU_HINH%, gia, y, %A_Space%
    g_GiaY := (Trim(v) = "" || Trim(v) = "ERROR") ? "" : v + 0
    IniRead, v, %FILE_CAU_HINH%, gia, donvi, b
    v := Format("{:L}", Trim(v))
    g_DonVi := RegExMatch(v, "^[a-z]{1,2}$") ? v : "b"
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
    IniWrite, % (g_DoLai ? 1 : 0), %FILE_CAU_HINH%, quet, dolai
    IniWrite, % g_LechTab, %FILE_CAU_HINH%, quet, lech
    IniWrite, % (g_TuDat ? 1 : 0), %FILE_CAU_HINH%, quet, tudat
    IniWrite, % g_Giay, %FILE_CAU_HINH%, quet, giay
    IniWrite, % (g_ChoTruoc ? 1 : 0), %FILE_CAU_HINH%, quet, chotruoc
    IniWrite, % g_GiayCho, %FILE_CAU_HINH%, quet, giaycho
    IniWrite, % (g_HienLuoi ? 1 : 0), %FILE_CAU_HINH%, quet, luoi
    IniWrite, % (g_BoQuaOTrong ? 1 : 0), %FILE_CAU_HINH%, quet, boqua
    IniWrite, % (g_HoiGia ? 1 : 0), %FILE_CAU_HINH%, quet, hoigia
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

    ; Mỗi dòng chữ thừa là một thứ mắt phải bỏ qua. Nên hộp thoại chỉ để
    ; lại nhãn và đơn vị; phần giải thích chuyển sang GỢI Ý KHI RÊ CHUỘT.
    DatGoiY()

    Gui, hQuet:New, +AlwaysOnTop -MaximizeBox -MinimizeBox, D4Lister — quét hàng loạt
    Gui, hQuet:Color, F4F4F4

    ; --- thanh tiêu đề ---
    ; Một dải Progress bị vô hiệu hoá là cách rẻ nhất để có mảng màu đặc
    ; trong Gui của AutoHotkey v1 — không có control "panel" nào sẵn.
    Gui, hQuet:Add, Progress, x0 y0 w452 h56 Background23211F Disabled
    Gui, hQuet:Font, s12 Bold, Segoe UI
    Gui, hQuet:Add, Text, x18 y9 w416 h24 BackgroundTrans cD8B172, QUÉT HÀNG LOẠT
    Gui, hQuet:Font, s8 Norm, Segoe UI
    Gui, hQuet:Add, Text, x18 y33 w416 h16 BackgroundTrans c9C968C
                        , Rê chuột lên từng mục để xem nó làm gì.

    ; --- phần 1: kho rương ---
    Gui, hQuet:Font, s8 Bold, Segoe UI
    Gui, hQuet:Add, Text, x18 y70 w200 h16 c8C2F2F, KHO RƯƠNG
    Gui, hQuet:Add, Text, x18 y88 w416 h1 +0x10
    Gui, hQuet:Font, s9 Norm, Segoe UI

    Gui, hQuet:Add, Text,  x18 y98 w132 h22 +0x200, Rương của bạn có:
    Gui, hQuet:Add, Radio, % "voSoTab Group x152 y98 w64 h22 gDoiSoTabQuet"
                             . (g_SoTab = 7 ? " Checked" : ""), 7 tab
    Gui, hQuet:Add, Radio, % "x218 y98 w64 h22 gDoiSoTabQuet"
                             . (g_SoTab = 6 ? " Checked" : ""), 6 tab
    Gui, hQuet:Add, Button, x298 y96 w136 h26 gReThuTab, Test tab

    Loop, 7
    {
        i  := A_Index
        cx := 20 + Mod(i - 1, 4) * 104
        cy := 130 + ((i - 1) // 4) * 26
        Gui, hQuet:Add, Checkbox
           , % "voTab" . i . " x" . cx . " y" . cy . " w96 h22"
             . (g_Tab[i] ? " Checked" : "")
             . (i > g_SoTab ? " Disabled" : "")
           , % "Tab " . i
    }
    Gui, hQuet:Add, Button, x20 y186 w104 h26 gChonHetQuet, Chọn tất cả
    Gui, hQuet:Add, Button, x130 y186 w104 h26 gBoHetQuet,  Bỏ chọn hết

    ; --- phần 2: túi đồ ---
    Gui, hQuet:Font, s8 Bold, Segoe UI
    Gui, hQuet:Add, Text, x18 y226 w200 h16 c8C2F2F, TÚI ĐỒ NHÂN VẬT
    Gui, hQuet:Add, Text, x18 y244 w416 h1 +0x10
    Gui, hQuet:Font, s9 Norm, Segoe UI
    Gui, hQuet:Add, Checkbox, % "voTui x20 y254 w414 h22"
                                . (g_QuetTui ? " Checked" : "")
                              , Quét cả túi đồ

    ; --- phần 3: tuỳ chọn ---
    Gui, hQuet:Font, s8 Bold, Segoe UI
    Gui, hQuet:Add, Text, x18 y292 w200 h16 c8C2F2F, TUỲ CHỌN
    Gui, hQuet:Add, Text, x18 y310 w416 h1 +0x10
    Gui, hQuet:Font, s9 Norm, Segoe UI

    Gui, hQuet:Add, Checkbox, % "voDoLai x20 y320 w414 h22"
                                . (g_DoLai ? " Checked" : "")
                              , Dò lại những ô không thấy gì

    Gui, hQuet:Add, Checkbox, % "voBoQua x20 y350 w414 h22"
                                . (g_BoQuaOTrong ? " Checked" : "")
                              , Bỏ qua ô trống — nhanh hơn nhiều

    Gui, hQuet:Add, Checkbox, % "voChoTruoc x20 y380 w250 h22 gDoiChoTruoc"
                                . (g_ChoTruoc ? " Checked" : "")
                              , Time bắt đầu quét sau:
    Gui, hQuet:Add, Edit, % "voCho x272 y379 w56 h22 Center"
                           . (g_ChoTruoc ? "" : " Disabled")
    Gui, hQuet:Add, UpDown, % "voChoUD Range1-30" . (g_ChoTruoc ? "" : " Disabled")
                           , % g_GiayCho
    Gui, hQuet:Add, Text, x334 y384 w40 h18, giây

    Gui, hQuet:Add, Checkbox, % "voTuDat x20 y410 w250 h22 gDoiTuDatGio"
                                . (g_TuDat ? " Checked" : "")
                              , Time hiển thị báo cáo
    Gui, hQuet:Add, Edit, % "voGiay x272 y409 w56 h22 Center"
                           . (g_TuDat ? "" : " Disabled")
    Gui, hQuet:Add, UpDown, % "voGiayUD Range3-120" . (g_TuDat ? "" : " Disabled")
                           , % g_Giay
    Gui, hQuet:Add, Text, x334 y414 w40 h18, giây

    Gui, hQuet:Add, Checkbox, % "voHienLuoi x20 y440 w414 h22"
                                . (g_HienLuoi ? " Checked" : "")
                              , Vẽ sơ đồ lưới ô trong báo cáo

    Gui, hQuet:Add, Checkbox, % "voHoiGia x20 y470 w414 h22"
                                . (g_HoiGia ? " Checked" : "")
                              , Lấy món xong thì hỏi giá luôn (F3)

    Gui, hQuet:Add, Text, x20 y500 w132 h22 +0x200, Chỉnh lệch vị trí tab:
    Gui, hQuet:Add, Edit, voLech x154 y499 w56 h22 Center
    Gui, hQuet:Add, UpDown, Range-60-60, % g_LechTab
    Gui, hQuet:Add, Text, x216 y504 w40 h18, px
    Gui, hQuet:Add, Button, x272 y498 w162 h26 gChinhCuaSo, Chỉnh cỡ cửa sổ game

    ; --- thanh nút ---
    Gui, hQuet:Add, Progress, x0 y532 w452 h58 BackgroundE6E4E1 Disabled
    Gui, hQuet:Add, Button, x188 y546 w136 h32 +Default gBatDauQuet, Scan
    Gui, hQuet:Add, Button, x332 y546 w102 h32 gHuyQuet,             Đóng

    OnMessage(0x200, "ReChuotHopQuet")          ; WM_MOUSEMOVE
    Gui, hQuet:Show, w452 h590 Center

    ; Chờ người dùng bấm. Các nút chạy ở luồng riêng nên vòng chờ này
    ; không chặn gì — đồng hồ đọc đường ống vẫn tiếp tục vét như thường.
    while (g_TraLoi = "")
        Sleep, 30
    OnMessage(0x200, "")
    ToolTip
    Gui, hQuet:Destroy

    if (g_TraLoi != "quet")
        return false

    g_SoTab   := (oSoTab = 1) ? 7 : 6
    g_QuetTui := (oTui != 0)
    g_DoLai   := (oDoLai != 0)
    g_TuDat   := (oTuDat != 0)
    g_Giay    := (oGiayUD + 0 >= 3 && oGiayUD + 0 <= 120) ? oGiayUD + 0 : 10
    g_ChoTruoc := (oChoTruoc != 0)
    g_GiayCho := (oChoUD + 0 >= 1 && oChoUD + 0 <= 30) ? oChoUD + 0 : 5
    g_HienLuoi := (oHienLuoi != 0)
    g_BoQuaOTrong := (oBoQua != 0)
    g_HoiGia  := (oHoiGia != 0)
    g_LechTab := (oLech + 0 >= -60 && oLech + 0 <= 60) ? oLech + 0 : 0
    g_Tab     := []
    Loop, 7
        g_Tab[A_Index] := (oTab%A_Index% != 0 && A_Index <= g_SoTab)
    LuuCauHinhQuet()
    return true
}


;=====================================================================
;   GỢI Ý KHI RÊ CHUỘT
;
;   Chỗ để giải thích. Nhét hết vào hộp thoại thì mỗi lần mở lại phải đọc
;   lướt qua một bức tường chữ chỉ để tick hai ô.
;
;   Khoá là TÊN BIẾN của control (đặt bằng chữ v khi thêm), còn nút không
;   có tên biến thì AutoHotkey trả về chính dòng chữ trên nút.
;=====================================================================
DatGoiY()
{
    global
    g_GoiY := {}
    Loop, 7
        g_GoiY["oTab" . A_Index] := "Tick những tab cần quét."
            . "`nKhông tick tab nào thì bỏ qua rương, chỉ quét túi đồ."
    g_GoiY["oSoTab"] := "Chọn đúng số tab rương của bạn."
        . "`nVị trí các tab đổi theo số này — chọn sai là bấm trượt."
    g_GoiY["Test tab"] := "Rê con trỏ qua từng ô tab, KHÔNG bấm."
        . "`nNhìn xem con trỏ có vào giữa ô tab không."
        . "`nTrượt thì chỉnh ở ô ""Chỉnh lệch vị trí tab""."
    g_GoiY["Chọn tất cả"]  := "Tick hết số tab đang có, và cả túi đồ."
    g_GoiY["Bỏ chọn hết"]  := "Bỏ tick tất cả."
    g_GoiY["oTui"] := "Quét cả 33 ô túi đồ hiện bên phải khi đang mở rương."
    g_GoiY["oDoLai"] := "Rê xong một lượt, những ô không thấy gì sẽ được hỏi"
        . "`nlại một lần nữa, chờ lâu gấp đôi."
        . "`n`nBẬT:  quét lâu hơn, nhưng món nào hiện chậm cũng không sót."
        . "`nTẮT:  quét nhanh hơn, đổi lại có thể sót món."
    g_GoiY["Chỉnh cỡ cửa sổ game"] := "Kéo cửa sổ game cho vùng vẽ đúng "
        . CLIENT_W . "×" . CLIENT_H . "."
        . "`nMọi toạ độ của F2 đo ở cỡ đó, sai cỡ là rê trượt ô."
        . "`n`nChỉ đổi cỡ cửa sổ, không đụng thiết lập nào của game."
    g_GoiY["oBoQua"] := "Nhìn cả lưới trước bằng điểm ảnh, rồi CHỈ rê vào"
        . "`nnhững ô có đồ. Ô trống bỏ qua luôn."
        . "`n`nTab 1 món ở ô cuối: ~31 giây  ->  ~0,2 giây."
        . "`nTab trống: bỏ qua cả lưới."
        . "`n`nĐã đo trên 415 ô thật, không sai ô nào. Trước khi bỏ qua nó"
        . "`ncòn đo lại vị trí lưới; lệch quá 6 px thì tự rê đủ mọi ô."
    g_GoiY["oHoiGia"] := "Bấm F3 lấy món xong, một ô nhập giá hiện ra."
        . "`nGõ số rồi Enter là xong. Esc thì bỏ qua."
        . "`n`n   gõ 300  ->  lưu là 300b"
        . "`n`nÔ này KHÔNG giành bàn phím: game vẫn là cửa sổ đang hoạt"
        . "`nđộng nên tooltip của món còn nguyên trên màn, vừa nhìn chỉ"
        . "`nsố vừa gõ giá được. Chuột cũng không phải rời món."
        . "`nĐổi lại, lúc ô đang mở thì phím 0-9 bị giữ lại, không lọt"
        . "`nxuống game — đóng ô là trả lại ngay."
        . "`n`nKéo ô đi đâu tuỳ ý, lần sau nó mở lại đúng chỗ đó."
        . "`n`nMón đã đặt giá được đánh dấu xanh trong rương; rê chuột vào"
        . "`nthì món đó hiện viền xanh kèm con số giá."
        . "`n`nBấm F3 lần nữa lên chính món vừa lấy = đặt lại giá."
        . "`nĐổi đơn vị tiền trong quet.ini, mục [gia] donvi."
    g_GoiY["oHienLuoi"] := "Vẽ đúng hình cái rương trong báo cáo cuối lượt:"
        . "`n   xám  = ô trống"
        . "`n   xanh = đọc được"
        . "`n   đỏ   = nhìn thấy có đồ mà không đọc ra chữ"
        . "`n`nLiếc một cái là biết ô nào hỏng, khỏi ngồi đếm dòng."
    g_GoiY["oChoTruoc"] := "Bấm ""Scan"" xong thì đếm ngược rồi mới rê."
        . "`nĐể bạn kịp bỏ tay khỏi chuột, hoặc kịp mở rương ra."
        . "`n`nĐang đếm mà bấm Esc thì huỷ."
    g_GoiY["oCho"] := g_GoiY["oChoTruoc"]
    g_GoiY["oTuDat"] := "KHÔNG tick: báo cáo ở lại trên màn cho tới khi"
        . "`nbạn bấm Esc. Đọc xong rồi mới tắt."
        . "`n`nTick vào: tự tắt sau số giây bạn chọn (3 đến 120)."
    g_GoiY["oGiay"] := g_GoiY["oTuDat"]
    g_GoiY["oLech"] := "Chỉ dùng khi bấm ""Test tab"" thấy con trỏ"
        . "`nkhông vào giữa ô. Số dương đẩy sang phải, số âm sang trái."
    g_GoiY["Scan"] := "Đóng hộp thoại và bắt đầu rê."
        . "`nBấm Esc lúc đang quét để dừng."
    g_GoiY["Đóng"] := "Đóng, không quét. Lựa chọn vẫn được nhớ."
}

ReChuotHopQuet()
{
    global g_GoiY
    static truoc := "|chua|"
    if (A_Gui != "hQuet")
        return
    if (A_GuiControl = truoc)
        return
    truoc := A_GuiControl
    if (g_GoiY.HasKey(A_GuiControl))
        ToolTip, % g_GoiY[A_GuiControl]
    else
        ToolTip
}


;=====================================================================
;   RÊ THỬ TAB
;
;   Vị trí dải tab là thứ DUY NHẤT trong bộ toạ độ mà tôi chưa đo được
;   tận nơi cho trường hợp 7 tab — số 6 tab đo từ ảnh thật, số 7 tab suy
;   ra từ cùng một công thức. Nên thay vì bắt tin, cho xem: rê con trỏ
;   qua từng tab, KHÔNG bấm, để mắt người xác nhận.
;=====================================================================
ReThuTab:
    Gui, hQuet:Submit, NoHide
    loiT := KiemCuaSoGame(gxT, gyT, cwT, chT)
    if (loiT != "")
    {
        MsgBox, 48, D4Lister, % loiT
        return
    }
    nT := (oSoTab = 1) ? 7 : 6
    lechCu := g_LechTab
    g_LechTab := (oLech + 0 >= -60 && oLech + 0 <= 60) ? oLech + 0 : 0
    MouseGetPos, oxT, oyT
    Loop, %nT%
    {
        txT := gxT + TamTab(A_Index, nT)
        tyT := gyT + TAB_Y
        MouseMove, %txT%, %tyT%, 0
        Sleep, 650
    }
    MouseMove, %oxT%, %oyT%, 0
    g_LechTab := lechCu     ; chỉ mượn để xem trước, chốt lại lúc bấm Quét
return

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

ChinhCuaSo:
    loiCS := ChinhCoCuaSo()
    if (loiCS = "")
        MsgBox, 0x40, D4Lister
            , % "Cửa sổ game đã về đúng " . CLIENT_W . "×" . CLIENT_H . "."
    else
        MsgBox, 48, D4Lister, % loiCS
return

DoiChoTruoc:
    Gui, hQuet:Submit, NoHide
    GuiControl, % "hQuet:" . (oChoTruoc ? "Enable" : "Disable"), oCho
    GuiControl, % "hQuet:" . (oChoTruoc ? "Enable" : "Disable"), oChoUD
return

DoiTuDatGio:
    Gui, hQuet:Submit, NoHide
    ; Tên Gui đứng trước thì cả tham số phải là biểu thức, không ghép
    ; nửa chữ nửa % được.
    GuiControl, % "hQuet:" . (oTuDat ? "Enable" : "Disable"), oGiay
    GuiControl, % "hQuet:" . (oTuDat ? "Enable" : "Disable"), oGiayUD
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
;   CHỤP & ĐO CÁC TAB  —  F10
;
;   Không quét, không lấy món, không đụng vào hàng đợi. Chỉ:
;     1. bấm sang từng tab đã chọn
;     2. chụp màn hình lại thành ảnh
;     3. TÌM vị trí lưới bằng cách dò cả dãy đường kẻ
;     4. đo từng ô rồi ghi hết ra một file chữ
;
;   Để làm gì: toạ độ lưới đo trên một máy, còn máy khác có thể lệch —
;   panel rương neo theo đỉnh cửa sổ, túi đồ neo theo đáy, nên chiều cao
;   vùng vẽ đổi là túi đồ xê dịch. Đo trên cả hai máy rồi so mới biết.
;=====================================================================

;   Đếm điểm "gờ" của một cột: sáng hơn hẳn phía bên trái.
GoDoc(anh, x, y0, y1)
{
    local y, s, t, n
    n := 0
    y := y0
    while (y < y1)
    {
        s := DocSangTaiDiem(anh, x, y)
        t := DocSangTaiDiem(anh, x - 5, y)
        if (s >= 0 && t >= 0 && s - t >= 18 && s >= 28)
            n++
        y += 5
    }
    return n
}

GoNgang(anh, y, x0, x1)
{
    local x, s, t, n
    n := 0
    x := x0
    while (x < x1)
    {
        s := DocSangTaiDiem(anh, x, y)
        t := DocSangTaiDiem(anh, x, y - 5)
        if (s >= 0 && t >= 0 && s - t >= 18 && s >= 28)
            n++
        x += 5
    }
    return n
}

;   Tìm gốc lưới bằng cách DÒ CẢ DÃY đường kẻ cùng lúc: cộng điểm gờ tại
;   mọi đường. Một món đồ có thể giả được một đường, không giả được cả dãy
;   cách đều.  Trả về "gốc|điểm|gốc_nhì|điểm_nhì".
LuocDoc(anh, xTu, xDen, buoc, soDuong, y0, y1)
{
    local x, k, t, tot, totX, nhi, nhiX
    tot := -1, totX := xTu, nhi := -1, nhiX := xTu
    x := xTu
    while (x <= xDen)
    {
        t := 0
        k := 0
        while (k < soDuong)
        {
            t += GoDoc(anh, Round(x + buoc * k), y0, y1)
            k++
        }
        if (t > tot)
        {
            nhi := tot, nhiX := totX
            tot := t, totX := x
        }
        else if (t > nhi)
            nhi := t, nhiX := x
        x++
    }
    return totX . "|" . tot . "|" . nhiX . "|" . nhi
}

LuocNgang(anh, yTu, yDen, buoc, soDuong, x0, x1)
{
    local y, k, t, tot, totY, nhi, nhiY
    tot := -1, totY := yTu, nhi := -1, nhiY := yTu
    y := yTu
    while (y <= yDen)
    {
        t := 0
        k := 0
        while (k < soDuong)
        {
            t += GoNgang(anh, Round(y + buoc * k), x0, x1)
            k++
        }
        if (t > tot)
        {
            nhi := tot, nhiY := totY
            tot := t, totY := y
        }
        else if (t > nhi)
            nhi := t, nhiY := y
        y++
    }
    return totY . "|" . tot . "|" . nhiY . "|" . nhi
}


DoMotLuoi(f, nhan, gx, gy, x0, y0, ow, oh, soCot, soHang, xTu, xDen, yTu, yDen)
{
    global
    local anh, r, c, tx, ty, n, dong, ket, p, sang, tong

    anh := ChupVung(gx + Round(x0) - 40, gy + Round(y0) - 40
                  , Round(ow * soCot) + 80, Round(oh * soHang) + 80)
    if (!anh)
    {
        FileAppend, % nhan . ": CHUP HONG`n", %f%, UTF-8-RAW
        return
    }

    ; tìm gốc lưới
    ket := LuocDoc(anh, gx + xTu, gx + xDen, ow, soCot + 1
                 , gy + Round(y0) + 20, gy + Round(y0 + oh * soHang) - 20)
    StringSplit, p, ket, |
    FileAppend, % "`n" . nhan . "`n"
        . "   mep trai TIM DUOC : x=" . (p1 - gx) . " (diem " . p2 . ")"
        . "   nhi: x=" . (p3 - gx) . " (diem " . p4 . ")"
        . "   dang dung: x=" . Round(x0) . "`n", %f%, UTF-8-RAW

    ket := LuocNgang(anh, gy + yTu, gy + yDen, oh, soHang + 1
                   , gx + Round(x0) + 20, gx + Round(x0 + ow * soCot) - 20)
    StringSplit, p, ket, |
    FileAppend, % "   mep tren TIM DUOC : y=" . (p1 - gy) . " (diem " . p2 . ")"
        . "   nhi: y=" . (p3 - gy) . " (diem " . p4 . ")"
        . "   dang dung: y=" . Round(y0) . "`n", %f%, UTF-8-RAW

    ; đo từng ô
    tong := 0
    r := 0
    while (r < soHang)
    {
        dong := ""
        c := 0
        while (c < soCot)
        {
            tx := gx + Round(x0 + ow * (c + 0.5))
            ty := gy + Round(y0 + oh * (r + 0.5))
            n := DemLechO(anh, tx, ty)
            dong .= "  " . Format("{:3}", n)
            if (n >= 10)
                tong++
            c++
        }
        FileAppend, % "   h" . (r + 1) . dong . "`n", %f%, UTF-8-RAW
        r++
    }
    FileAppend, % "   => nhin thay " . tong . " o co do"
               . "   (>=10 diem lech = co do)`n", %f%, UTF-8-RAW
    XoaAnh(anh)
}

DoKiemTra:
    if (g_Busy || g_DangQuet)
        return
    HideMsgNow()
    ; Ẩn dấu xanh đi đã: nó nằm ĐÈ LÊN rương, mà cả F2 lẫn F10 đều đọc
    ; rương bằng ảnh chụp màn hình — để nguyên là ô trống nào có dấu
    ; cũng bị đọc thành ô có đồ. Đồng hồ TheoDoiTabDau vẽ lại sau.
    AnDauXanh()
    loiKT := KiemCuaSoGame(gxK, gyK, cwK, chK)
    if (loiKT != "")
    {
        ShowMsg(loiKT, "err", 6000)
        return
    }
    if (!RuongDangMo(gxK, gyK))
    {
        ShowMsg("CHƯA MỞ RƯƠNG`nMở rương rồi bấm F10 lại.", "err")
        return
    }

    g_DangQuet := true
    thuMuc := A_ScriptDir . "\_kiem-tra"
    FileCreateDir, %thuMuc%
    fKT := thuMuc . "\ket-qua.txt"
    FileDelete, %fKT%
    FormatTime, gioKT,, dd/MM/yyyy HH:mm:ss
    FileAppend, % "D4Lister — chup & do cac tab`n" . gioKT . "`n"
        . "vung ve " . cwK . "x" . chK . "   goc " . gxK . "," . gyK . "`n"
        . "ruong " . g_SoTab . " tab`n"
        . "============================================================`n"
        , %fKT%, UTF-8-RAW

    dsKT := DocDsTab()
    MouseGetPos, cxKT, cyKT
    Loop, Parse, dsKT, `,
    {
        iKT := A_LoopField + 0
        txKT := TamTab(iKT, g_SoTab)
        if (txKT < 0)
            continue
        ShowMsg("Đang chụp tab " . iKT . "…", "warn")
        MouseMove, % gxK + txKT, % gyK + TAB_Y, 0
        Sleep, 60
        Click
        Sleep, %CHO_TAB_MS%
        MouseMove, % gxK + RUONG_X - 20, % gyK + RUONG_Y, 0
        Sleep, 250
        ChupManHinh(thuMuc . "\tab-" . iKT . ".png")
        DoMotLuoi(fKT, "TAB " . iKT, gxK, gyK, RUONG_X, RUONG_Y, RUONG_OW, RUONG_OH
                , RUONG_COT, RUONG_HANG, RUONG_X - 14, RUONG_X + 14
                , RUONG_Y - 16, RUONG_Y + 16)
    }
    ShowMsg("Đang chụp túi đồ…", "warn")
    DoMotLuoi(fKT, "TUI DO", gxK, gyK, TUI_X, TUI_Y, TUI_OW, TUI_OH
            , TUI_COT, TUI_HANG, TUI_X - 14, TUI_X + 14, TUI_Y - 16, TUI_Y + 16)

    MouseMove, %cxKT%, %cyKT%, 0
    g_DangQuet := false
    ShowMsg("Xong. Kết quả trong thư mục _kiem-tra", "ok", 8000)
    Run, %thuMuc%
return

;   Chụp cả màn hình ra file PNG. Dùng PowerShell cho gọn — việc này chạy
;   một lần mỗi tab, không phải chỗ cần nhanh.
ChupManHinh(f)
{
    local lenh
    lenh := "powershell -NoProfile -Command ""Add-Type -AssemblyName System.Drawing;"
          . " $b = New-Object Drawing.Bitmap " . A_ScreenWidth . "," . A_ScreenHeight . ";"
          . " $g = [Drawing.Graphics]::FromImage($b);"
          . " $g.CopyFromScreen(0,0,0,0,$b.Size);"
          . " $b.Save('" . f . "')"""
    RunWait, %lenh%, , Hide
}


;=====================================================================
;   HỎI GIÁ SAU KHI LẤY MÓN
;
;   Lấy món xong thì hỏi luôn giá, lưu thẳng vào file của món. Sau đó trên
;   trình duyệt không còn việc gì cần tay người: tiện ích điền cả giá rồi
;   tự đăng. Gõ giá chính là thứ DUY NHẤT còn phá vỡ tự động hoá.
;
;   FORM BẤM CHUỘT, KHÔNG PHẢI BẮT PHÍM. Bản đầu bắt phím 1-5 để game khỏi
;   mất tiêu điểm; người dùng thấy không hợp lý, muốn thấy các mức giá và
;   bấm thẳng vào. Giữ được cả hai: form hiện ra ở chế độ NoActivate nên
;   bấm nút vẫn ăn mà game vẫn là cửa sổ hoạt động, tooltip còn nguyên.
;
;   Biến của phần này nằm ở khối hằng số trên đầu file. Đặt "global X := …"
;   ở dưới đây thì phép gán KHÔNG BAO GIỜ chạy — chỗ này nằm sau cái return
;   của khối tự chạy — mà AutoHotkey vẫn nhận cái tên, nên biến rỗng một
;   cách lặng lẽ.
;=====================================================================

;   Hiện ô nhập giá rồi chờ. Trả về chuỗi giá, hoặc "" nếu bỏ qua.
;
;   CHỖ NÀY ĐÃ SAI MỘT LẦN, và đây là lý do nó làm theo kiểu lạ.
;
;   Bản trước cho ô nhập giành bàn phím để con trỏ nằm sẵn trong đó. Chạy
;   thì lộ ra: Diablo chỉ vẽ tooltip của món khi CỬA SỔ GAME đang hoạt
;   động. Ô nhập giành bàn phím = game thôi hoạt động = tooltip tắt ngay,
;   mà đó đúng là thứ đang cần nhìn để định giá.
;
;   Nên form này KHÔNG bao giờ giành bàn phím. Thay vào đó nó BẮT THẲNG
;   PHÍM SỐ: 0-9, dấu chấm, Backspace, Enter, Esc. Người dùng vẫn gõ số
;   rồi Enter y như gõ vào một ô bình thường, còn game thì vẫn là cửa sổ
;   đang hoạt động suốt — tooltip đứng nguyên.
;
;   Nuốt luôn phím, không cho lọt xuống game: 0-9 trong game là ô kỹ năng.
;   Đổi lại phải tắt cho bằng hết lúc đóng form.
;
;   Đơn vị mặc định là tỉ: gõ 300, lưu ra "300b". Ô chỉ hiện con số, chữ b
;   không hiện. Đổi đơn vị trong quet.ini, mục [gia] donvi.
HoiGia(tenMon, giaCu := "")
{
    global

    g_GiaTenMonDang := tenMon
    ; Món đã có giá thì bỏ chữ đơn vị đi, ô chỉ giữ con số.
    g_GiaChuO       := RegExReplace(Trim(giaCu), "[A-Za-z]+$", "")
    ; Giá cũ lưu từ trước lúc có trần thì kéo về trần. Không kéo thì ô hiện
    ; số vượt trần mà gõ thêm lại không được — nhìn như hỏng bàn phím.
    if (QuaTranGia(g_GiaChuO))
        g_GiaChuO := GIA_TOI_DA . ""
    g_GiaChon       := ""
    g_GiaXong       := false
    g_DangHoiGia    := true

    VeFormGia()
    BatPhimGia(true)
    ; Kéo form: không có thanh tiêu đề nên bắt cú bấm rồi bảo Windows "coi
    ; như vừa bấm vào thanh tiêu đề".
    OnMessage(0x201, "KeoFormGia")          ; WM_LBUTTONDOWN

    while (!g_GiaXong)
        Sleep, 30

    OnMessage(0x201, "")
    BatPhimGia(false)
    NhoChoForm()
    Gui, hGia:Destroy
    g_DangHoiGia := false
    return g_GiaChon
}

VeFormGia()
{
    global
    local mg, ew, eh, y, w, h, fs, px, py

    mg := Round(14 * A_ScreenDPI / 96)
    ew := Round(216 * A_ScreenDPI / 96)
    eh := Round(36 * A_ScreenDPI / 96)
    w  := mg * 2 + ew

    Gui, hGia:Destroy
    Gui, hGia:New, +Hwndg_GiaHwnd +AlwaysOnTop -Caption +Border +ToolWindow +E0x08000000 -DPIScale
    Gui, hGia:Color, %COL_BG%
    Gui, hGia:Margin, 0, 0

    y := mg
    fs := Round(11 * A_ScreenDPI / 96)
    Gui, hGia:Font, s%fs% Bold, Segoe UI
    Gui, hGia:Add, Text, % "x" . mg . " y" . y . " w" . ew
                        . " c1A1A1A vGiaTenMon", % g_GiaTenMonDang
    y += Round(24 * A_ScreenDPI / 96)

    ; Ô chỉ để NHÌN. Chữ vào ô bằng đường bắt phím, không phải bằng tiêu
    ; điểm — ReadOnly cho rõ ý, và để bấm vào cũng không đòi bàn phím.
    fs := Round(14 * A_ScreenDPI / 96)
    Gui, hGia:Font, s%fs% Bold, Segoe UI
    Gui, hGia:Add, Edit, % "x" . mg . " y" . y . " w" . ew . " h" . eh
                        . " Center ReadOnly -TabStop vGiaChuNhap", % g_GiaChuO
    h := y + eh + mg

    ViTriForm(w, h, px, py)
    Gui, hGia:Show, % "NoActivate x" . px . " y" . py . " w" . w . " h" . h
}

;   Bật/tắt bộ phím của form. Tắt cho bằng hết là việc bắt buộc: để sót
;   một phím số là trong game bấm kỹ năng đó không ăn nữa, mà lỗi kiểu đó
;   rất khó đoán ra là do đâu.
BatPhimGia(bat)
{
    global
    local k, tt
    tt := bat ? "On" : "Off"
    Loop, Parse, PHIM_GIA, |
    {
        k := A_LoopField
        Hotkey, %k%, GiaPhim, %tt% UseErrorLevel
    }
}

;   Chuỗi đang gõ có vượt trần giá không?
;
;   Chuỗi giữa chừng chưa phải số hợp lệ: "." (vừa gõ dấu chấm đầu tiên),
;   "12." (chấm ở cuối). Đắp cho thành số rồi mới so — so thẳng thì AHK
;   đem chuỗi đi so theo bảng chữ cái, "1000" lại nhỏ hơn "999".
QuaTranGia(chu)
{
    global GIA_TOI_DA
    so := RegExReplace(chu, "^\.", "0.")        ; ".5"  -> "0.5"
    so := RegExReplace(so,  "\.$", ".0")        ; "12." -> "12.0"
    if (!RegExMatch(so, "^\d+(\.\d+)?$"))       ; không ra số thì đừng chặn
        return false
    return ((so + 0) > GIA_TOI_DA)
}

;   Đổi tên phím thành ký tự. Trả về "" nếu phím đó không phải chữ số.
KyTuTuPhim(k)
{
    k := RegExReplace(k, "^(~|\*|\$)+", "")
    if (k = "NumpadDot" || k = ".")
        return "."
    k := RegExReplace(k, "^Numpad", "")
    return RegExMatch(k, "^\d$") ? k : ""
}

GiaPhim:
    if (A_ThisHotkey = "Escape")
    {
        XongHoiGia("")
        return
    }
    if (A_ThisHotkey = "Enter" || A_ThisHotkey = "NumpadEnter")
    {
        XongHoiGia(GhepDonVi(g_GiaChuO, g_DonVi))
        return
    }
    if (A_ThisHotkey = "BackSpace")
        g_GiaChuO := SubStr(g_GiaChuO, 1, StrLen(g_GiaChuO) - 1)
    else
    {
        g_KyTuTam := KyTuTuPhim(A_ThisHotkey)
        ; Một dấu chấm là đủ, và đừng cho gõ dài vô tận.
        if (g_KyTuTam = "." && InStr(g_GiaChuO, "."))
            g_KyTuTam := ""
        ; Dấu chấm mà đằng sau không còn nhét nổi con số nào (đang là 999)
        ; thì đừng nhận: ô sẽ đứng ở "999." — chấm cụt, gõ tiếp không ăn,
        ; mà ghép đơn vị lại ra "999.b".
        if (g_KyTuTam = "." && QuaTranGia(g_GiaChuO . ".1"))
            g_KyTuTam := ""
        ; Trần 999. Gõ quá thì BỎ CÚ GÕ, không cắt bớt chữ đã có — cắt thì
        ; người gõ không nhìn ra mình vừa mất con số nào.
        if (g_KyTuTam != "" && StrLen(g_GiaChuO) < 12
            && QuaTranGia(g_GiaChuO . g_KyTuTam) = false)
            g_GiaChuO .= g_KyTuTam
    }
    GuiControl, hGia:, GiaChuNhap, % g_GiaChuO
return

;   Kéo form: cửa sổ không có thanh tiêu đề, nên lừa Windows rằng cú bấm
;   vừa rồi rơi vào thanh tiêu đề (HTCAPTION = 2).
KeoFormGia()
{
    global
    if (A_Gui != "hGia")
        return
    PostMessage, 0xA1, 2, , , % "ahk_id " . g_GiaHwnd    ; WM_NCLBUTTONDOWN
}

;   Ghi lại chỗ người dùng vừa kéo form tới, để lần sau mở đúng chỗ đó.
NhoChoForm()
{
    global
    local fx, fy
    WinGetPos, fx, fy, , , % "ahk_id " . g_GiaHwnd
    if (fx = "")
        return
    g_GiaX := fx
    g_GiaY := fy
    IniWrite, %fx%, %FILE_CAU_HINH%, gia, x
    IniWrite, %fy%, %FILE_CAU_HINH%, gia, y
}

;   Chỗ đứng của form: chỗ lần trước người dùng kéo tới. Chưa kéo lần nào
;   thì đáy cửa sổ game, căn giữa ngang.
ViTriForm(w, h, ByRef px, ByRef py)
{
    global
    local gx, gy, cw, ch, vx, vy, vw, vh

    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79
    if (g_GiaX != "" && g_GiaY != "")
    {
        px := g_GiaX + 0
        py := g_GiaY + 0
    }
    else if (KiemCuaSoGame(gx, gy, cw, ch) = "")
    {
        px := gx + (cw - w) // 2
        py := gy + ch - h - Round(70 * A_ScreenDPI / 96)
    }
    else
    {
        px := vx + (vw - w) // 2
        py := vy + vh - h - Round(70 * A_ScreenDPI / 96)
    }
    if (px + w > vx + vw)
        px := vx + vw - w - 4
    if (py + h > vy + vh)
        py := vy + vh - h - 4
    if (px < vx)
        px := vx + 4
    if (py < vy)
        py := vy + 4
}

XongHoiGia(gia)
{
    global
    g_GiaChon := gia
    g_GiaXong := true
}

;   Ghép đơn vị tiền vào con số.
;
;   "300"             ->  "300b"
;   "300b"            ->  giữ nguyên, không thành "300bb"
;   rỗng              ->  rỗng, tức là bỏ qua
GhepDonVi(chu, dv)
{
    chu := Trim(chu)
    if (chu = "" || dv = "")
        return chu
    if RegExMatch(chu, "i)[a-z]$")               ; đã có chữ đơn vị ở cuối
        return chu
    if !RegExMatch(chu, "^[\d]+([.,][\d]+)?$")   ; không phải số thuần
        return chu
    return chu . dv
}

;   Ghi giá vào file của món. Thay dòng cũ nếu đã có.
;
;   KHÔNG dùng "m)^...$" ở đây. File món có thể lẫn hai kiểu xuống dòng
;   (FileAppend lúc dịch `n thành `r`n lúc không), mà PCRE trong AHK mặc
;   định chỉ coi `r`n là hết dòng — gặp một `n trơ là ^ không bám được,
;   dòng giá cũ không bị xoá, đọc lại ra rỗng. \R khớp mọi kiểu xuống dòng
;   nên không phụ thuộc chuyện đó nữa.
LuuGiaVaoFile(f, gia)
{
    local noiDung
    if (!FileExist(f))
        return false
    FileRead, noiDung, *P65001 %f%
    noiDung := RegExReplace(noiDung, "(?:\R|^)#D4L-GIA:[^\r\n]*", "")
    noiDung := RTrim(noiDung, "`r`n")
    if (gia != "")
        noiDung .= "`r`n#D4L-GIA:" . gia
    FileDelete, %f%
    FileAppend, %noiDung%, %f%, UTF-8-RAW
    return FileExist(f) ? true : false
}

;   Đọc giá đang lưu trong file của món.
DocGiaTuFile(f)
{
    local noiDung, m
    if (!FileExist(f))
        return ""
    FileRead, noiDung, *P65001 %f%
    ;   Dạng "O)" trả về ĐỐI TƯỢNG. Dạng thường ghi ra m1, m2… mà trong hàm
    ;   có khai báo local thì m1 lại rơi ra biến toàn cục, còn chữ m1 viết
    ;   trong hàm lại đọc biến cục bộ — khớp được mà vẫn ra rỗng.
    if (RegExMatch(noiDung, "O)(?:\R|^)#D4L-GIA:([^\r\n]*)", m))
        return Trim(m.Value(1))
    return ""
}


;=====================================================================
;   DẤU XANH — món nào đã đặt giá rồi
;
;   Nỗi lo chính khi tự đặt giá: không nhớ món nào đã đặt, đặt lại lần nữa
;   là mất công. Nên đặt xong thì dán một ô vuông xanh lên đúng ô đó trong
;   rương, liếc một cái là biết.
;
;   Không vẽ được vào trong game, nên treo một cửa sổ trong suốt đè lên.
;   Cửa sổ đó KHÔNG ăn chuột (E0x20) và KHÔNG giành tiêu điểm (E0x08000000)
;   — thiếu một trong hai là game mất chuột, không chơi được.
;
;   Dấu chỉ nằm trong bộ nhớ. Món bán xong là xoá hàng đợi, dấu đi theo.
;=====================================================================
; Các biến của phần này nằm ở khối hằng số trên đầu file — đặt "global X
; := ..." ở dưới này thì phép gán không bao giờ chạy, g_DauXanh sẽ là chuỗi
; rỗng chứ không phải object, và .Count() trên chuỗi rỗng giết luôn luồng.

;   Tab rương đang mở. Trả về 0 nếu không đọc ra.
;
;   Ô tab đang mở sáng hơn hẳn: đo trên ba ảnh chụp thật, tab mở có điểm
;   sáng nhất 74-77 còn tab đóng chỉ 12-14. Cách nhau năm lần nên lấy 40
;   làm mốc là rộng rãi.
TabDangMo(gx, gy)
{
    global
    local anh, i, tx, s, x, y, nhat, tot, iTot

    anh := ChupVung(gx + 60, gy + TAB_Y - 14, 540, 28)
    if (!anh)
        return 0

    tot := 0, iTot := 0
    i := 1
    while (i <= g_SoTab)
    {
        tx := TamTab(i, g_SoTab)
        if (tx < 0)
        {
            i++
            continue
        }
        nhat := 0
        x := gx + tx - 14
        while (x <= gx + tx + 14)
        {
            y := gy + TAB_Y - 10
            while (y <= gy + TAB_Y + 10)
            {
                s := DocSangTaiDiem(anh, x, y)
                if (s > nhat)
                    nhat := s
                y += 4
            }
            x += 4
        }
        if (nhat > tot)
            tot := nhat, iTot := i
        i++
    }
    XoaAnh(anh)
    return (tot >= 40) ? iTot : 0
}

;   Con trỏ đang nằm ở ô nào. Trả về false nếu không nằm trong lưới nào.
;
;   tabBiet: đã biết sẵn tab nào đang mở thì truyền vào, khỏi phải chụp lại
;   dải tab. Cái đồng hồ rê chuột gọi hàm này mấy lần một giây, chụp mỗi lần
;   là phí.
TimOCuaChuot(gx, gy, ByRef tab, ByRef hang, ByRef cot, tabBiet := -1)
{
    global
    local mx, my, c, h

    MouseGetPos, mx, my
    mx -= gx
    my -= gy

    c := Floor((mx - RUONG_X) / RUONG_OW)
    h := Floor((my - RUONG_Y) / RUONG_OH)
    if (c >= 0 && c < RUONG_COT && h >= 0 && h < RUONG_HANG)
    {
        tab := (tabBiet >= 1) ? tabBiet : TabDangMo(gx, gy)
        if (tab < 1)
            return false
        hang := h, cot := c
        return true
    }

    c := Floor((mx - TUI_X) / TUI_OW)
    h := Floor((my - TUI_Y) / TUI_OH)
    if (c >= 0 && c < TUI_COT && h >= 0 && h < TUI_HANG)
    {
        tab := O_TUI_DO, hang := h, cot := c
        return true
    }
    return false
}

;   Chốt lại ô mà con trỏ đang nằm. Gọi lúc BẤM F3, không phải lúc lưu giá:
;   giữa hai thời điểm đó người dùng đã rê chuột xuống form để bấm nút.
GhiNhoODangRe()
{
    global
    local gx, gy, cw, ch, tab, hang, cot

    g_ODangRe := ""
    if (!g_HoiGia)
        return
    if (KiemCuaSoGame(gx, gy, cw, ch) != "")
        return
    ; Truyền g_TabCuoi vào để hàm khỏi đi đọc dải tab: ngay lúc này tooltip
    ; của món đang che nó.
    if (!TimOCuaChuot(gx, gy, tab, hang, cot, g_TabCuoi))
        return
    g_ODangRe := tab . "|" . hang . "|" . cot
}

;   Vì sao không đánh dấu được. Nói thẳng ra thay vì im lặng — dấu không
;   hiện mà không biết vì sao thì chỉ còn nước đoán.
ViSaoKhongDau()
{
    global
    local gx, gy, cw, ch, loi

    loi := KiemCuaSoGame(gx, gy, cw, ch)
    if (loi != "")
        return "cửa sổ game không đạt"
    if (g_ODangRe = "")
        return "lúc bấm F3 con trỏ không nằm trong ô nào của rương/túi"
    return "chưa rõ"
}

;   Đánh dấu cái ô đã chốt lúc bấm F3.
;
;   Lưu luôn GIÁ vào bản đồ chứ không chỉ đánh dấu có/không: rê chuột vào ô
;   đó lần sau thì hiện ra ngay đã để bao nhiêu, khỏi phải nhớ.
DanhDauMon(gia)
{
    global
    local gx, gy, cw, ch

    if (gia = "" || g_ODangRe = "")
        return false
    if (KiemCuaSoGame(gx, gy, cw, ch) != "")
        return false

    g_DauXanh[g_ODangRe] := gia
    g_DauTabDang := -1              ; ép vẽ lại
    VeDauXanh(gx, gy)
    return true
}

XoaDauXanh()
{
    global
    g_DauXanh := {}
    g_DauTabDang := -1
    AnDauXanh()
    AnGiaRe()
}

AnDauXanh()
{
    global
    if (!g_DauHien)
        return
    Gui, hDau:Hide
    g_DauHien := false
    AnGiaRe()
}

;   Vẽ lại toàn bộ dấu cho tab đang mở.
VeDauXanh(gx, gy)
{
    global
    local tab, k, v, p, x, y, so

    tab := g_TabCuoi
    g_DauTabDang := tab

    Gui, hDau:Destroy
    Gui, hDau:New, +Hwndg_DauHwnd +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000
    Gui, hDau:Color, 010101
    Gui, hDau:Margin, 0, 0

    so := 0
    for k, v in g_DauXanh
    {
        StringSplit, p, k, |
        ; Dấu của rương chỉ hiện khi đúng tab đó đang mở. Dấu túi đồ luôn
        ; hiện, vì túi đồ nằm cạnh rương suốt.
        if (p1 + 0 != O_TUI_DO && p1 + 0 != tab)
            continue
        ; Dán ở góc DƯỚI TRÁI của ô.
        ;
        ; Phải chừa dải mà RuongDangMo đọc để biết rương có đang mở: nó soi
        ; các điểm x = 36 và 41-43. Dấu ở cột 1 bắt đầu tại x = 42 + 5 = 47,
        ; qua khỏi chỗ đó rồi. Đừng hạ DAU_LUI xuống dưới 3.
        if (p1 + 0 = O_TUI_DO)
        {
            x := Round(TUI_X + TUI_OW * p3 + DAU_LUI)
            y := Round(TUI_Y + TUI_OH * (p2 + 1) - DAU_CANH - DAU_LUI)
        }
        else
        {
            x := Round(RUONG_X + RUONG_OW * p3 + DAU_LUI)
            y := Round(RUONG_Y + RUONG_OH * (p2 + 1) - DAU_CANH - DAU_LUI)
        }
        Gui, hDau:Add, Progress, % "x" . x . " y" . y
                                 . " w" . DAU_CANH . " h" . DAU_CANH
                                 . " Background2E9E4F Disabled"
        so++
    }

    if (so = 0)
    {
        AnDauXanh()
        return
    }

    Gui, hDau:Show, % "NoActivate x" . gx . " y" . gy
                    . " w" . CLIENT_W . " h" . CLIENT_H
    WinSet, TransColor, 010101, % "ahk_id " . g_DauHwnd
    g_DauHien := true
}

;   Người dùng tự bấm sang tab khác thì không có sự kiện nào báo — phải
;   ngó chừng. Một lần ngó tốn một cú chụp dải tab hẹp, không đáng kể.
;   Con trỏ có đang nằm trong vùng lưới rương không. Lúc nó nằm trong đó là
;   game đang vẽ tooltip của món, mà tooltip ấy CHE MẤT dải tab — đọc tab
;   lúc đó thì đọc phải chữ của tooltip.
ChuotTrenLuoiRuong(gx, gy)
{
    global
    local mx, my
    MouseGetPos, mx, my
    mx -= gx
    my -= gy
    return (mx >= RUONG_X - 30 && mx <= RUONG_X + RUONG_OW * RUONG_COT + 30
         && my >= RUONG_Y - 30 && my <= RUONG_Y + RUONG_OH * RUONG_HANG + 30)
}

TheoDoiTabDau:
    if (g_Busy || g_DangQuet || g_DangHoiGia)
        return
    ; KHÔNG đòi game phải là cửa sổ đang hoạt động. Bỏ theo yêu cầu người
    ; dùng. Vẫn không có chuyện dấu xanh nổi lên đè màn hình khi đang làm
    ; việc khác: RuongDangMo() ở dưới đọc điểm ảnh chỗ mép rương, cửa sổ
    ; khác che mất là nó thấy ngay và cất dấu đi.
    if (KiemCuaSoGame(gxD, gyD, cwD, chD) != "")
    {
        AnDauXanh()
        g_DauTabDang := -1
        return
    }
    if (!RuongDangMo(gxD, gyD))
    {
        AnDauXanh()
        g_DauTabDang := -1
        return
    }
    ; Chỉ đọc dải tab lúc con trỏ ở ngoài lưới. Người dùng bấm sang tab khác
    ; thì lúc bấm con trỏ đang ở trên dải tab, đọc được ngay — chẳng lần nào
    ; lỡ. Còn lúc con trỏ nằm trong lưới thì cứ giữ số đọc được lần trước.
    if (!ChuotTrenLuoiRuong(gxD, gyD))
    {
        tabD := TabDangMo(gxD, gyD)
        if (tabD >= 1)
            g_TabCuoi := tabD
    }
    if (g_DauXanh.Count() = 0)
    {
        AnDauXanh()
        return
    }
    if (g_TabCuoi != g_DauTabDang || !g_DauHien)
        VeDauXanh(gxD, gyD)
return

;=====================================================================
;   RÊ CHUỘT VÀO MÓN ĐÃ ĐẶT GIÁ  —  VIỀN XANH + NHÃN GIÁ
;
;   Làm theo đúng kiểu D4LF: rê vào món nó nhận ra thì món đó được đóng
;   khung màu, kèm một nhãn chữ nhỏ nói món đó là gì. Ở đây nhãn nói GIÁ.
;
;   Khác D4LF một chỗ: họ đóng khung quanh cái TOOLTIP, muốn vậy phải đi
;   dò xem tooltip đang vẽ ở đâu trên màn. Mình đóng khung quanh Ô — toạ độ
;   ô thì đã đo sẵn và tin được, khỏi phải đoán.
;
;   Hai cửa sổ nhỏ, cùng không ăn chuột và không giành tiêu điểm:
;     hVien   — bốn thanh mảnh ghép thành cái khung
;     hReGia  — con số giá, nền tối cho dễ đọc trên nền gì cũng được
;=====================================================================
; Các biến g_ReGia* / g_VienHwnd nằm ở khối hằng số trên đầu file — xem bẫy 30/37.

AnGiaRe()
{
    global
    if (!g_ReGiaHien)
        return
    Gui, hVien:Hide
    Gui, hReGia:Hide
    g_ReGiaHien := false
    g_ReGiaO := ""
}

;   Khung viền quanh ô. Không vẽ được hình rỗng ruột bằng một control, nên
;   ghép bốn thanh: trên, dưới, trái, phải.
VeVienO(x, y, w, h)
{
    global
    local d

    d := Round(VIEN_DAY * A_ScreenDPI / 96)
    Gui, hVien:Destroy
    Gui, hVien:New, +Hwndg_VienHwnd +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale
    Gui, hVien:Color, 010101
    Gui, hVien:Margin, 0, 0
    Gui, hVien:Add, Progress, % "x0 y0 w" . w . " h" . d . " Background" . VIEN_MAU . " Disabled"
    Gui, hVien:Add, Progress, % "x0 y" . (h - d) . " w" . w . " h" . d . " Background" . VIEN_MAU . " Disabled"
    Gui, hVien:Add, Progress, % "x0 y0 w" . d . " h" . h . " Background" . VIEN_MAU . " Disabled"
    Gui, hVien:Add, Progress, % "x" . (w - d) . " y0 w" . d . " h" . h . " Background" . VIEN_MAU . " Disabled"
    Gui, hVien:Show, % "NA x" . x . " y" . y . " w" . w . " h" . h
    WinSet, TransColor, 010101, % "ahk_id " . g_VienHwnd
}

;   Hiện viền + nhãn giá cho ô đang rê chuột.
HienGiaRe(gia, gx, gy, tab, hang, cot)
{
    global
    local x, y, w, h, ow, oh, lw, lh, fs, vx, vy, vw, vh

    if (tab = O_TUI_DO)
    {
        ow := TUI_OW , oh := TUI_OH
        x := gx + Round(TUI_X + TUI_OW * cot)
        y := gy + Round(TUI_Y + TUI_OH * hang)
    }
    else
    {
        ow := RUONG_OW , oh := RUONG_OH
        x := gx + Round(RUONG_X + RUONG_OW * cot)
        y := gy + Round(RUONG_Y + RUONG_OH * hang)
    }
    w := Round(ow)
    h := Round(oh)

    VeVienO(x, y, w, h)

    ; --- nhãn giá: góc dưới phải cái khung, y như D4LF dán chữ ---
    Gui, hReGia:Destroy
    Gui, hReGia:New, +Hwndg_ReGiaHwnd +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale
    Gui, hReGia:Color, 0E2A16
    fs := Round(10 * A_ScreenDPI / 96)
    Gui, hReGia:Margin, % Round(7 * A_ScreenDPI / 96), % Round(3 * A_ScreenDPI / 96)
    Gui, hReGia:Font, s%fs% Bold, Segoe UI
    Gui, hReGia:Add, Text, % "c" . VIEN_MAU . " BackgroundTrans vReGiaChu", % gia
    Gui, hReGia:Show, NA AutoSize x-32000 y-32000
    WinGetPos, , , lw, lh, % "ahk_id " . g_ReGiaHwnd

    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79
    ; Nhãn nằm đè lên mép dưới khung, thò sang phải một chút.
    x := x + w - lw + Round(4 * A_ScreenDPI / 96)
    y := y + h - Round(2 * A_ScreenDPI / 96)
    if (x + lw > vx + vw)
        x := vx + vw - lw - 2
    if (y + lh > vy + vh)
        y := vy + vh - lh - 2
    if (x < vx)
        x := vx + 2
    Gui, hReGia:Show, % "NA x" . x . " y" . y

    g_ReGiaHien := true
}

;   Đồng hồ rê chuột. Chỉ tra bản đồ trong bộ nhớ, KHÔNG chụp màn hình —
;   số tab thì lấy cái mà TheoDoiTabDau đã đọc sẵn.
TheoDoiReGia:
    if (g_Busy || g_DangQuet || g_DangHoiGia || !g_DauHien)
    {
        AnGiaRe()
        return
    }
    if (KiemCuaSoGame(gxR, gyR, cwR, chR) != "")
    {
        AnGiaRe()
        return
    }
    if (!TimOCuaChuot(gxR, gyR, tabR, hangR, cotR, g_TabCuoi))
    {
        AnGiaRe()
        return
    }
    khoaR := tabR . "|" . hangR . "|" . cotR
    if (!g_DauXanh.HasKey(khoaR))
    {
        AnGiaRe()
        return
    }
    if (khoaR != g_ReGiaO)
    {
        g_ReGiaO := khoaR
        HienGiaRe(g_DauXanh[khoaR], gxR, gyR, tabR, hangR, cotR)
    }
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
