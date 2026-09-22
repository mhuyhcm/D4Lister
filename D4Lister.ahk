;=====================================================================
;   D4Lister  -  Hỗ trợ đăng item Diablo 4 lên diablo.trade
;   AutoHotkey v1  |  File độc lập, không #Include gì, chạy được trên máy khác
;
;   TRONG GAME:
;     F3          Kéo chọn vùng tooltip item -> lưu vào hàng đợi + clipboard
;
;   TRÊN TRÌNH DUYỆT:
;     F4          Dán item hiện tại (thay cho Ctrl+V)
;     F5          Sang item kế tiếp
;     F6          Lùi về item trước đó
;
;   KHÁC:
;     F7               Đổi chế độ xử lý ảnh (0-4), xem khối CẤU HÌNH
;     F8               Đổi hệ số phóng to (2× / 3× / 4×)
;     F9               Xóa sạch hàng đợi
;     Ctrl+Shift+F12   Thoát script (hoặc chuột phải vào icon khay hệ thống)
;
;   YÊU CẦU: Diablo IV để chế độ Borderless Windowed.
;            Chế độ Fullscreen độc quyền sẽ chặn mọi lớp phủ -> không chọn
;            được vùng và không thấy tooltip.
;
;   Phần chụp vùng (đóng băng màn hình) lấy từ "Screen clipping tool.ahk"
;   của chính máy này, đã lược bỏ OCR / dịch thuật / ảnh thu nhỏ / menu
;   chuột phải / Tesseract / HTTP.
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
global HK_CAPTURE := "F3"           ; chụp item
global HK_PASTE   := "F4"           ; dán item hiện tại
global HK_NEXT    := "F5"           ; sang item kế + DÁN LUÔN
global HK_PREV    := "F6"           ; lùi về item trước
global HK_MODE    := "F7"           ; đổi chế độ xử lý ảnh (0 hoặc 2)
global HK_CLEAR   := "F9"           ; xóa sạch hàng đợi
global HK_RELOAD  := "^+F11"        ; nạp lại script (và kiểm tra bản mới)
global HK_EXIT    := "^+F12"        ; thoát script

;---------------------------------------------------------------------
;   TESSERACT  -  đọc chữ trong ảnh, chạy ngay trên máy này
;
;   Chạy NGẦM sau khi chụp xong, nên F3 không chậm đi. Mỗi ảnh 001.png
;   đẻ ra một file 001.txt nằm cạnh. Lúc F4 dán, chữ trong file đó được
;   bỏ vào clipboard cùng với ảnh -> tiện ích Chrome đọc lấy và điền form.
;
;   Đây là chỗ tránh được hết lỗi đọc số của diablo.trade: số đi thẳng từ
;   máy bạn vào ô nhập, không qua bộ quét của họ.
;
;   Tìm không thấy tesseract.exe thì script vẫn chạy bình thường, chỉ là
;   không có chữ -> quay về đúng cách cũ (dán ảnh rồi bấm SCAN).
;---------------------------------------------------------------------
; --- Dò dấu ✳ (Greater Affix) bằng pixel. Đo thật trên 12 dòng của 4 món
;     chụp qua Parsec: affix thường 0.093-0.152, có dấu ✳ 0.311-0.483.
;     Ngưỡng 0.23 nằm giữa, cách hai bên đều rộng.
global SAO_RONG   := 2.2    ; bề rộng ô soi = mấy lần chiều cao chữ
global SAO_SANG   := 150    ; điểm ảnh sáng hơn mức này thì tính là "sáng"
global SAO_NGUONG := 0.25   ; mật độ điểm sáng vượt mức này = có dấu ✳
global SAO_LOG    := true   ; ghi số đo ra queue\_sao.log để dò khi sai

global TESS_EXE := ""               ; để trống = tự dò theo danh sách dưới
; psm 4 = "một cột chữ, cỡ chữ thay đổi" — đúng hình dạng tooltip D4.
; ĐO ĐƯỢC trên 4 ảnh chụp qua Parsec: psm 6 đọc dấu "+" thành số "4"
;   ("+12.5%" -> "412.5%",  "+3,500" -> "43,500")  => sai số mà trông vẫn hợp lệ.
; psm 4 đọc đúng cả hai, lại tự tách chữ dính ("+3to" -> "+3 to") và bớt rác
; đầu dòng. Đừng đổi về 6.
global TESS_PSM := 4

;---------------------------------------------------------------------
;   XỬ LÝ ẢNH trước khi đưa cho diablo.trade quét
;
;   Dòng chữ XÁM MỜ (affix giới hạn theo class, ví dụ "+300 Life on Kill")
;   tương phản rất thấp trên nền tối -> OCR hay bỏ sót.
;   Bấm F7 để đổi chế độ ngay tại chỗ rồi chụp lại, so kết quả:
;
;     0 = Gốc                  giữ nguyên ảnh chụp, không đụng gì
;     2 = Phóng + tăng cường   bicubic 2× + tương phản có điểm tựa  <-- mặc định
;
;   Chỉ còn hai chế độ. Các chế độ cũ (phóng 3×, đen trắng, nét cứng) đã đo
;   thật và đều TỆ HƠN, xóa đi cho gọn.
;
;   Chế độ 2 nhắm vào chữ xám mờ: kéo chữ sáng lên, đẩy nền tối xuống, vẫn giữ
;   kiểu khử răng cưa mượt mà OCR quen thuộc.
;
;   CÒN PHẢI ĐO: giờ Tesseract chạy ngay trên máy này, chưa chắc còn cần chế
;   độ 2 nữa. Bấm F7 để nhảy qua lại 0 và 2, chụp cùng một món rồi so hai file
;   .txt. Nếu chế độ 0 đọc đủ thì bỏ hẳn được, F3 nhanh thêm ~0,7 giây.
;---------------------------------------------------------------------
;---------------------------------------------------------------------
;   MẶC ĐỊNH = cấu hình đã ĐO ĐƯỢC 95% chính xác trên diablo.trade.
;   Đừng đổi nhiều thứ cùng lúc. Mỗi lần chỉ đổi MỘT biến rồi chụp lại
;   đúng một món quen thuộc để so — nếu không sẽ không biết biến nào gây ra.
;
;   ĐÃ THỬ VÀ TỆ HƠN (đo thật, đừng lặp lại):
;     - Phóng 3× hoặc hơn  -> trang quét CHẬM hẳn, đọc thiếu nhiều hơn
;     - Chế độ 4 nét cứng  -> cạnh răng cưa, OCR đọc kém hơn hẳn
;     - Bão hòa 1.4        -> khuếch đại viền màu ở mép chữ
;   Nguyên nhân: OCR của diablo.trade quen với tooltip D4 nguyên bản (khử
;   răng cưa mượt). Càng can thiệp mạnh càng xa cái nó quen.
;---------------------------------------------------------------------
; MẶC ĐỊNH = 2 (phóng 2× + tương phản có điểm tựa).
; Chế độ 0 để nguyên ảnh thì dòng chữ XÁM MỜ (affix giới hạn class, ví dụ
; "+108 Dexterity (Only)") bị OCR bỏ sót — đã gặp thật. Cần chế độ 2 để
; kéo chữ xám sáng lên. Muốn đối chứng ảnh gốc thì bấm F7 ba lần.
global PROC_MODE     := 2      ; chế độ mặc định lúc khởi động (0 hoặc 2)
global PROC_SCALE    := 2      ; hệ số phóng to — đo rồi, 2 là tốt nhất
global PROC_CONTRAST := 2.00   ; hệ số tương phản (1.0 = không đổi)
global PROC_BRIGHT   := 0.00   ; cộng thêm độ sáng (0 = không đổi)
global PROC_SATURATE := 1.00   ; độ bão hòa màu (1.0 = TẮT, giữ nguyên màu)

;---------------------------------------------------------------------
;   ĐIỂM TỰA TƯƠNG PHẢN  -  chìa khóa cứu dòng chữ XÁM MỜ
;       ket qua = (goc - diem_tua) * tuong_phan + diem_tua
;   Tương phản thường kéo sáng CẢ NỀN lên theo nên chữ xám không nổi thêm.
;   Có điểm tựa 0.15 + tương phản 2.0: nền 0.08->0.01, chữ xám 0.45->0.75,
;   chữ trắng 0.95->1.00. Chữ xám lên gần bằng chữ trắng, nền chìm xuống.
;---------------------------------------------------------------------
global PROC_PIVOT := 0.15

;---------------------------------------------------------------------
;   ĐỘ TRỄ TRƯỚC KHI CHỤP  (quan trọng khi chụp qua Parsec / remote)
;   Bộ nén video làm nét DẦN một khung hình đứng yên. Chụp ngay lập tức là
;   chụp đúng lúc ảnh còn mờ nhất. Chơi thẳng trên máy thì đặt 0.
;---------------------------------------------------------------------
global CAPTURE_DELAY := 600         ; ms chờ trước khi đóng băng màn hình

;---------------------------------------------------------------------
;   CHIẾM CHUỘT KHI CHỤP  (bắt buộc bật khi chụp bên trong game)
;   Game khóa con trỏ trong cửa sổ nó. Không chiếm focus thì bấm F3 thấy màn
;   hình đóng băng NHƯNG KHÔNG KÉO CHỌN ĐƯỢC. Bật thì: gỡ khóa con trỏ, lớp
;   phủ chiếm focus, chọn xong TRẢ LẠI focus cho game (túi đồ không bị đóng).
;---------------------------------------------------------------------
global GRAB_FOCUS := true

global MSG_TIME   := 1500           ; thời gian hiện tooltip (ms)
global MIN_SIZE   := 50             ; vùng chọn nhỏ hơn (px) thì coi là hỏng
global SHOW_HINT  := true           ; hiện gợi ý lúc đang kéo chọn vùng
global QUEUE_DIR  := A_ScriptDir . "\queue"

; Màu tooltip: nền trắng, chữ xanh lá / đỏ / cam
global COL_BG   := "FFFFFF"
global COL_OK   := "0A8A0A"
global COL_ERR  := "C00000"
global COL_WARN := "C06000"

;=====================================================================
;   BIẾN TOÀN CỤC
;=====================================================================
global g_Items   := []      ; danh sách đường dẫn file ảnh trong hàng đợi
global g_Cur     := 0       ; vị trí item đang chọn (1-based)
global g_Busy    := false   ; đang chụp -> chặn chụp chồng nhau
global g_MsgHwnd := 0

; Vừa chụp xong thì phím đầu tiên bấm sau đó (F4 / F5 / F6) sẽ
; nhảy về ĐẦU đợt chụp vừa rồi, thay vì đứng ở món cuối cùng vừa chụp.
; Nhờ vậy sang trình duyệt bấm F4 là dán đúng món đầu tiên.
global g_FreshCapture := false  ; true = vừa chụp xong, chưa chuyển sang dán
global g_BatchStart   := 1      ; vị trí món đầu tiên của đợt chụp hiện tại

;=====================================================================
;   KHỞI ĐỘNG
;=====================================================================
Menu, Tray, Icon, C:\WINDOWS\system32\shell32.dll, 44
Menu, Tray, Tip, D4Lister - F3 chụp / F4 dán / F5-F6 chuyển

if !FileExist(QUEUE_DIR)
    FileCreateDir, %QUEUE_DIR%

LoadQueue()

; Lần đầu chạy trên máy mới: bung Tesseract xách tay ra. Làm ở đây chứ không
; ở file .bat, để bấm đúp thẳng D4Lister.ahk là xong, khỏi nhớ file nào.
BungTesseractNeuCan()

TESS_EXE := TimTesseract()

Hotkey, %HK_CAPTURE%, DoCapture
Hotkey, %HK_MODE%,    DoMode
Hotkey, %HK_PASTE%,   DoPaste
Hotkey, %HK_NEXT%,    DoNext
Hotkey, %HK_PREV%,    DoPrev
Hotkey, %HK_CLEAR%,   DoClear
Hotkey, %HK_RELOAD%,  DoReload
Hotkey, %HK_EXIT%,    DoExit

SysGet, scrW, 78
SysGet, scrH, 79
tessText := (TESS_EXE = "") ? "KHÔNG THẤY — chỉ có ảnh, phải bấm SCAN" : "có"
g_StartInfo := "Màn hình " . scrW . "×" . scrH
             . "   |   scale " . Round(A_ScreenDPI / 96 * 100) . "%`n"
             . "Đọc chữ: " . tessText

if (g_Items.Length() > 0)
    ShowMsg("D4Lister sẵn sàng — đã nạp lại " . g_Items.Length() . " item`n" . g_StartInfo, "warn")
else
    ShowMsg("D4Lister sẵn sàng — bấm F3 để chụp item`n" . g_StartInfo, "ok")

; Kiểm tra bản mới, nhưng để script chạy được ngay đã rồi mới đi hỏi mạng.
SetTimer, KiemTraCapNhat, -800
return

;=====================================================================
;   HOTKEY: F3 - CHỤP ITEM
;=====================================================================
DoCapture:
    if (g_Busy)
        return
    g_Busy := true
    ; Quét lại thư mục TRƯỚC khi chụp: nếu máy kia vừa bấm F9 xóa sạch thì
    ; máy này phải biết, để món chụp tiếp theo là "item 1/1" chứ không phải
    ; đếm tiếp từ con số cũ trong bộ nhớ.
    RefreshForCapture()
    HideMsgNow()
    Sleep, 60

    region := ""
    try
    {
        region := FreezeSelectRegion(SHOW_HINT ? "Kéo chọn vùng tooltip item  (Esc để hủy)" : "")
    }
    catch e
    {
        g_Busy := false
        ShowMsg("Lỗi khi chụp: " . e.Message, "err")
        return
    }

    if (region = "")
    {
        g_Busy := false
        ShowMsg("Đã hủy — chưa lưu gì", "err")
        return
    }

    if (region.w < MIN_SIZE || region.h < MIN_SIZE)
    {
        FileDelete, % region.file
        g_Busy := false
        ShowMsg("Vùng chọn quá nhỏ — bấm " . HK_CAPTURE . " làm lại", "err")
        return
    }

    ; Một máy dùng riêng nên đánh số thứ tự cho dễ đọc: 001.png, 002.png...
    ; (Bản cũ đặt tên theo thời điểm chụp vì hai máy dùng chung thư mục đồng
    ;  bộ, đánh số sẽ trùng tên gây xung đột. Giờ một máy thì không còn lo.)
    outFile := QUEUE_DIR . "\" . SoTiepTheo() . ".png"
    rawFile := A_Temp . "\d4lister_raw_" . A_TickCount . ".png"
    try
    {
        GdipCropFile(region.file, region.x - region.ox, region.y - region.oy
                   , region.w, region.h, rawFile)
    }
    catch e
    {
        FileDelete, % region.file
        g_Busy := false
        ShowMsg("Chụp thất bại — bấm " . HK_CAPTURE . " làm lại", "err")
        return
    }
    FileDelete, % region.file

    ; Xử lý ảnh theo chế độ đang chọn. Hỏng thì vẫn dùng ảnh gốc, không bỏ món.
    if (!ProcessImage(rawFile, outFile, PROC_MODE))
        FileCopy, %rawFile%, %outFile%, 1
    FileDelete, %rawFile%

    if !FileExist(outFile)
    {
        g_Busy := false
        ShowMsg("Chụp thất bại — bấm " . HK_CAPTURE . " làm lại", "err")
        return
    }

    ; Món đầu tiên của một đợt chụp mới -> ghi nhớ vị trí bắt đầu đợt
    if (!g_FreshCapture)
        g_BatchStart := g_Items.Length() + 1

    g_Items.Push(outFile)
    g_Cur := g_Items.Length()
    g_FreshCapture := true

    ; Đọc chữ CHẠY NGẦM — không đợi. Bạn rê sang món kế là nó chạy xong rồi.
    ChayOCRNgam(outFile)

    if (!SetClipImage(outFile))
    {
        g_Busy := false
        ShowMsg("Đã lưu item " . g_Cur . " nhưng LỖI COPY — bấm F5 rồi F6 để nạp lại", "err")
        return
    }

    g_Busy := false
    sc := (PROC_MODE = 0) ? 1 : PROC_SCALE
    ShowMsg("Đã lưu item " . g_Cur . "/" . g_Items.Length()
          . "   (" . (region.w * sc) . "×" . (region.h * sc) . " px)", "ok")
return

;=====================================================================
;   HOTKEY: F7 - ĐỔI CHẾ ĐỘ XỬ LÝ ẢNH
;   Đổi xong chụp lại món đó là thấy ngay chế độ nào diablo.trade đọc tốt hơn.
;=====================================================================
DoMode:
    PROC_MODE := (PROC_MODE = 0) ? 2 : 0
    ShowMsg("Chế độ xử lý ảnh " . PROC_MODE . ": " . ModeName(PROC_MODE) . "`n"
          . "Chụp lại đúng món vừa rồi rồi mở 2 file .txt ra so", "warn")
return

;=====================================================================
;   HOTKEY: F4 - DÁN ITEM HIỆN TẠI
;=====================================================================
DoPaste:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item nào — bấm " . HK_CAPTURE . " để chụp", "err")
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
    if (!SetClipImage(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F5 rồi F6 để nạp lại", "err")
        return
    }
    Sleep, 80
    SendInput, ^v
    ShowMsg("Đã dán item " . g_Cur . "/" . g_Items.Length(), "ok")
return

;=====================================================================
;   HOTKEY: F5 / F6  CHUYỂN ITEM
;=====================================================================
DoNext:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item nào — bấm " . HK_CAPTURE . " để chụp", "err")
        return
    }
    if (g_FreshCapture)
    {
        GoToBatchStart()
        return
    }
    if (g_Cur >= g_Items.Length())
    {
        ShowMsg("Đã ở item cuối (" . g_Cur . "/" . g_Items.Length() . ")", "warn")
        return
    }
    g_Cur += 1
    if (!SetClipImage(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F5 lại lần nữa", "err")
        return
    }
    ; Sang món kế là DÁN LUÔN. Đăng xong một món chỉ cần bấm đúng phím này.
    Sleep, 80
    SendInput, ^v
    ShowMsg("Đã dán item " . g_Cur . "/" . g_Items.Length(), "ok")
return

DoPrev:
    RefreshQueue()
    if (g_Items.Length() = 0)
    {
        ShowMsg("Chưa có item nào — bấm " . HK_CAPTURE . " để chụp", "err")
        return
    }
    if (g_FreshCapture)
    {
        GoToBatchStart()
        return
    }
    if (g_Cur <= 1)
    {
        ShowMsg("Đã ở item đầu (1/" . g_Items.Length() . ")", "warn")
        return
    }
    g_Cur -= 1
    if (!SetClipImage(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm F6 lại lần nữa", "err")
        return
    }
    ShowMsg("Item " . g_Cur . "/" . g_Items.Length(), "ok")
return

;=====================================================================
;   HOTKEY: F9 - XÓA SẠCH HÀNG ĐỢI
;=====================================================================
DoClear:
    ; Xóa THẲNG mọi file trong thư mục, không chỉ những file đang có trong
    ; bộ nhớ. Xóa cả .txt đi kèm, nếu không lần chụp sau sẽ nhặt phải chữ cũ.
    n := 0
    Loop, %QUEUE_DIR%\*.png
    {
        FileDelete, % A_LoopFileFullPath
        if (!ErrorLevel)
            n++
    }
    Loop, %QUEUE_DIR%\*.txt
        FileDelete, % A_LoopFileFullPath
    Loop, %QUEUE_DIR%\*.tsv
        FileDelete, % A_LoopFileFullPath
    FileDelete, % QUEUE_DIR . "\_sao.log"

    g_Items := []
    g_Cur := 0
    g_FreshCapture := false
    g_BatchStart := 1

    if (n = 0)
        ShowMsg("Hàng đợi đã trống sẵn", "warn")
    else
        ShowMsg("Đã xóa " . n . " item — lần chụp tới bắt đầu lại từ item 1", "warn")
return

DoExit:
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

    ShowMsg("Đang xem có bản mới không…", "warn")
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
;   Liệt kê file ảnh trong hàng đợi, sắp xếp theo tên.
;   Tên là số thứ tự nên sắp theo tên = sắp theo thứ tự chụp.
;=====================================================================
ScanQueueFiles()
{
    global QUEUE_DIR

    list := ""
    Loop, %QUEUE_DIR%\*.png
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
;   Quét lại trước khi CHỤP.
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
;   VỀ MÓN ĐẦU CỦA ĐỢT CHỤP VỪA RỒI
;   Gọi khi vừa chụp xong mà bấm F5 hoặc F6 — đưa con trỏ về
;   đầu đợt thay vì nhích tới/lui từ món cuối cùng vừa chụp.
;=====================================================================
GoToBatchStart()
{
    global g_Items, g_Cur, g_BatchStart, g_FreshCapture

    g_FreshCapture := false
    g_Cur := g_BatchStart
    if (g_Cur < 1 || g_Cur > g_Items.Length())
        g_Cur := 1
    if (!SetClipImage(g_Items[g_Cur]))
    {
        ShowMsg("Lỗi copy — bấm lại phím vừa bấm", "err")
        return
    }
    ShowMsg("Về đầu đợt — item " . g_Cur . "/" . g_Items.Length(), "ok")
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

ModeName(m)
{
    return (m = 0) ? "Gốc (nhanh hơn ~0,7s)" : "Phóng 2× + tăng cường"
}

;=====================================================================
;   Dựng ColorMatrix 5x5 gộp cả ĐỘ BÃO HÒA, TƯƠNG PHẢN và ĐỘ SÁNG.
;
;   GDI+ đọc ma trận theo kiểu: hàng = kênh VÀO, cột = kênh RA
;     R' = R*m[0][0] + G*m[1][0] + B*m[2][0] + A*m[3][0] + m[4][0]
;
;   Độ bão hòa dùng trọng số độ sáng chuẩn (0.3086 / 0.6094 / 0.0820):
;   s = 1 giữ nguyên màu, s > 1 làm màu rực hơn — giúp dấu ✳ màu cam và
;   chữ màu tách hẳn khỏi nền tối.
;   Sau đó nhân toàn bộ với tương phản c, rồi cộng độ sáng b ở hàng cuối.
;=====================================================================
BuildColorMatrix(ByRef cm, c, b, s)
{
    global PROC_PIVOT
    lr := 0.3086, lg := 0.6094, lb := 0.0820
    VarSetCapacity(cm, 100, 0)

    NumPut(((1 - s) * lr + s) * c, cm, (0 * 5 + 0) * 4, "float")
    NumPut(((1 - s) * lr)     * c, cm, (0 * 5 + 1) * 4, "float")
    NumPut(((1 - s) * lr)     * c, cm, (0 * 5 + 2) * 4, "float")

    NumPut(((1 - s) * lg)     * c, cm, (1 * 5 + 0) * 4, "float")
    NumPut(((1 - s) * lg + s) * c, cm, (1 * 5 + 1) * 4, "float")
    NumPut(((1 - s) * lg)     * c, cm, (1 * 5 + 2) * 4, "float")

    NumPut(((1 - s) * lb)     * c, cm, (2 * 5 + 0) * 4, "float")
    NumPut(((1 - s) * lb)     * c, cm, (2 * 5 + 1) * 4, "float")
    NumPut(((1 - s) * lb + s) * c, cm, (2 * 5 + 2) * 4, "float")

    NumPut(1.0, cm, (3 * 5 + 3) * 4, "float")   ; giữ nguyên alpha
    NumPut(1.0, cm, (4 * 5 + 4) * 4, "float")

    ; Hàng cuối = độ dời. Xoay quanh điểm tựa thay vì quanh 0:
    ;   (x - p) * c + p + b   =   x * c + [ b + p * (1 - c) ]
    off := b + PROC_PIVOT * (1 - c)
    NumPut(off, cm, (4 * 5 + 0) * 4, "float")
    NumPut(off, cm, (4 * 5 + 1) * 4, "float")
    NumPut(off, cm, (4 * 5 + 2) * 4, "float")
}

;=====================================================================
;   XỬ LÝ ẢNH CHO OCR
;   Phóng to bằng bicubic chất lượng cao + (tùy chế độ) chỉnh màu bằng
;   ColorMatrix của GDI+. Trả về true nếu thành công.
;
;   Vì sao phóng to giúp: OCR nhận dạng theo hình dạng nét chữ. Chữ trong
;   tooltip D4 khá nhỏ; phóng 2x bicubic làm nét chữ mượt và dày hơn, engine
;   có nhiều pixel hơn để phân biệt — đặc biệt với dòng chữ xám mờ.
;=====================================================================
ProcessImage(srcFile, outFile, mode)
{
    global PROC_SCALE, PROC_CONTRAST, PROC_BRIGHT

    if (mode = 0)
    {
        FileCopy, %srcFile%, %outFile%, 1
        return !ErrorLevel
    }

    hModule := 0
    pToken := GdipStart(hModule)
    if (!pToken)
    {
        GdipStop(0, hModule)
        return false
    }

    pSrc := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", srcFile, "ptr*", pSrc)
    if (!pSrc)
    {
        GdipStop(pToken, hModule)
        return false
    }
    sw := 0, sh := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pSrc, "uint*", sw)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pSrc, "uint*", sh)
    dw := sw * PROC_SCALE
    dh := sh * PROC_SCALE

    ; --- Dựng ColorMatrix 5x5 (25 float, hàng-major) ---
    VarSetCapacity(cm, 100, 0)
    useAttr := false

    ; Tương phản + độ bão hòa + độ sáng, GIỮ NGUYÊN MÀU SẮC.
    ; Chữ xám mờ được kéo sáng lên, nền tối bị đẩy tối thêm.
    BuildColorMatrix(cm, PROC_CONTRAST, PROC_BRIGHT, PROC_SATURATE)
    useAttr := true

    pAttr := 0
    if (useAttr)
    {
        DllCall("gdiplus\GdipCreateImageAttributes", "ptr*", pAttr)
        DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "ptr", pAttr
            , "int", 0, "int", 1, "ptr", &cm, "ptr", 0, "int", 0)
        ; WrapMode TileFlipXY (3): chặn viền trong suốt khi bicubic lấy mẫu vượt mép
        DllCall("gdiplus\GdipSetImageAttributesWrapMode", "ptr", pAttr, "int", 3, "uint", 0, "int", 0)
    }

    pOut := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", dw, "int", dh, "int", 0
        , "int", 0x26200A, "ptr", 0, "ptr*", pOut)          ; 0x26200A = 32bppARGB
    if (!pOut)
    {
        if (pAttr)
            DllCall("gdiplus\GdipDisposeImageAttributes", "ptr", pAttr)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        GdipStop(pToken, hModule)
        return false
    }

    pG := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pOut, "ptr*", pG)
    ; Nền đen cho hợp với tooltip game (tránh viền sáng lạ quanh mép).
    DllCall("gdiplus\GdipGraphicsClear", "ptr", pG, "uint", 0xFF000000)
    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", pG, "int", 7) ; HighQualityBicubic
    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", pG, "int", 2)   ; HighQuality
    DllCall("gdiplus\GdipDrawImageRectRectI", "ptr", pG, "ptr", pSrc
        , "int", 0, "int", 0, "int", dw, "int", dh
        , "int", 0, "int", 0, "int", sw, "int", sh
        , "int", 2, "ptr", pAttr, "ptr", 0, "ptr", 0)       ; 2 = UnitPixel

    status := GdipSavePng(pOut, outFile)

    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pG)
    if (pAttr)
        DllCall("gdiplus\GdipDisposeImageAttributes", "ptr", pAttr)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pOut)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
    GdipStop(pToken, hModule)

    return (status = 0 && FileExist(outFile))
}

; Độ sáng 1 điểm ảnh (trung bình R,G,B) — dùng để đoán nền sáng hay tối.
;=====================================================================
;   ĐẶT ẢNH VÀO CLIPBOARD  (bao bọc có bắt lỗi)
;=====================================================================
SetClipImage(file)
{
    if !FileExist(file)
        return false
    try
    {
        ; Chữ đọc được của đúng món này đi kèm luôn. Chưa có (Tesseract chưa
        ; chạy xong, hoặc máy không có Tesseract) thì chỉ đặt ảnh — vẫn dùng
        ; được theo cách cũ: dán rồi bấm SCAN.
        SetImageClipboard(file, DocChuCuaAnh(file))
    }
    catch e
    {
        return false
    }
    return true
}

;=====================================================================
;   ĐỌC CHỮ TRONG ẢNH  (Tesseract)
;=====================================================================

;   Dò tesseract.exe. Thư mục con "tesseract" cạnh script được ưu tiên —
;   đó là chỗ để bản xách tay khi mang tool sang máy khác.
;   Bung bản xách tay ra nếu chưa có. Mất khoảng 4 giây, chỉ lần đầu.
BungTesseractNeuCan()
{
    if FileExist(A_ScriptDir . "\tesseract\tesseract.exe")
        return
    zip := A_ScriptDir . "\_he-thong\bo-cai\tesseract-portable.zip"
    if !FileExist(zip)
        return
    ShowMsg("Lần đầu chạy — đang bung Tesseract, đợi vài giây…", "warn")
    RunWait, % "powershell -NoProfile -Command ""Expand-Archive -Path '" . zip
             . "' -DestinationPath '" . A_ScriptDir . "' -Force""", , Hide
    HideMsgNow()
}

TimTesseract()
{
    ds := [ A_ScriptDir . "\tesseract\tesseract.exe"
          , "C:\Program Files\Tesseract-OCR\tesseract.exe"
          , "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"
          , "F:\AUTOHOTKEY\for PC\Tools\bin\Tesseract5\tesseract.exe" ]
    for i, p in ds
        if FileExist(p)
            return p
    return ""
}

;   Chạy NGẦM, KHÔNG đợi. Tesseract tự ghi ra <tên>.txt cạnh ảnh.
;   Nhờ không đợi nên F3 trả về ngay, bạn rê sang món kế là nó xong rồi.
;   Xuất CẢ .txt LẪN .tsv trong một lần chạy. File .tsv cho biết TOẠ ĐỘ từng
;   chữ — cần nó để soi dấu ✳ (Greater Affix) nằm bên trái mỗi dòng.
ChayOCRNgam(pngFile)
{
    global TESS_EXE, TESS_PSM
    if (TESS_EXE = "")
        return
    SplitPath, pngFile, , thuMuc, , tenKhongDuoi
    goc := thuMuc . "\" . tenKhongDuoi
    Run, "%TESS_EXE%" "%pngFile%" "%goc%" --psm %TESS_PSM% txt tsv, , Hide
}

;   Đọc file .txt đi kèm ảnh rồi lọc sạch. Lọc lúc này chứ không lọc lúc
;   chụp — đỡ phải hẹn giờ chờ Tesseract, mà cũng chỉ tốn vài mili giây.
DocChuCuaAnh(pngFile)
{
    SplitPath, pngFile, , thuMuc, , tenKhongDuoi
    f := thuMuc . "\" . tenKhongDuoi . ".txt"
    if !FileExist(f)
        return ""
    FileRead, raw, *P65001 %f%
    chu := DanhDauSao(LocChu(raw), pngFile)
    if (chu = "")
        return ""
    ; Gửi kèm số hiệu bản tiện ích ĐANG NẰM TRÊN ĐĨA.
    ;
    ; Chrome không tự nạp lại tiện ích cài kiểu Load unpacked. Nên sau khi
    ; cập nhật, file trên đĩa là bản mới mà trình duyệt vẫn chạy bản cũ —
    ; không ai biết. Tiện ích so số này với số của chính nó; lệch thì nó tự
    ; hiện cảnh báo to ngay trên trang, đúng chỗ bạn đang làm việc.
    ban := BanExtTrenDia()
    if (ban != "")
        chu .= "`n#D4L-EXT:" . ban
    return chu
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
;   DẤU ✳  (Greater Affix)
;
;   Dấu này là HÌNH VẼ, không phải chữ — Tesseract không đọc được, và
;   diablo.trade cũng hay bỏ sót. Nhưng đo được bằng pixel: dấu ✳ là ngôi sao
;   TRẮNG TO, còn affix thường là hình thoi XÁM NHỎ.
;
;   Cách làm: file .tsv cho toạ độ từng chữ -> lấy ô bên TRÁI con số đầu dòng
;   -> đếm số điểm sáng -> chia cho bình phương chiều cao chữ (để không phụ
;   thuộc cỡ ảnh).
;
;   ĐO THẬT trên 12 dòng của 4 món chụp qua Parsec:
;       affix thường   0.093 - 0.152
;       có dấu ✳       0.311 - 0.483
;   Cách nhau hơn gấp đôi, nên ngưỡng 0.23 nằm giữa rất an toàn.
;
;   Dòng có dấu ✳ được đánh dấu bằng "**" ở đầu; tiện ích Chrome đọc dấu đó
;   rồi bật công tắc Greater Affix trên form.
;=====================================================================
DanhDauSao(chuDaLoc, pngFile)
{
    global SAO_RONG, SAO_SANG, SAO_NGUONG
    if (chuDaLoc = "")
        return chuDaLoc
    SplitPath, pngFile, , thuMuc, , tenKhongDuoi
    ftsv := thuMuc . "\" . tenKhongDuoi . ".tsv"
    if (!FileExist(ftsv) || !FileExist(pngFile))
        return chuDaLoc

    hM := 0
    pTok := GdipStart(hM)
    if (!pTok)
    {
        GdipStop(0, hM)
        return chuDaLoc
    }
    pBm := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", pngFile, "ptr*", pBm)
    if (!pBm)
    {
        GdipStop(pTok, hM)
        return chuDaLoc
    }
    rongAnh := 0, caoAnh := 0
    DllCall("gdiplus\GdipGetImageWidth",  "ptr", pBm, "uint*", rongAnh)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pBm, "uint*", caoAnh)

    ; gom chữ theo dòng, tìm con số mở đầu mỗi dòng affix
    FileRead, tsv, *P65001 %ftsv%
    dong := {}
    Loop, Parse, tsv, `n, `r
    {
        if (A_Index = 1 || A_LoopField = "")
            continue
        c := StrSplit(A_LoopField, A_Tab)
        if (c.Length() < 12 || c[1] != 5 || Trim(c[12]) = "")
            continue
        k := c[3] . "|" . c[4] . "|" . c[5]
        if (!dong.HasKey(k))
            dong[k] := []
        dong[k].Push(c)
    }

    coSao := {}
    for k, ws in dong
    {
        ; --- chỉ đo ĐÚNG dòng affix ---------------------------------------
        ; Không lọc thì đo trúng cả "Requires Level 70", "helm by 39%",
        ; "Sell Value: 115,350" — mấy dòng đó sáng rực, số của chúng lọt vào
        ; danh sách và làm mọi dòng đều bị đánh dấu (đã gặp thật).
        chuCaDong := ""
        for i2, c2 in ws
            chuCaDong .= c2[12] . " "
        if RegExMatch(chuCaDong, "i)Toughness|Item Power|Sell Value|Durabil|Temper|All Resist"
                               . "|Requires|Unlocks|Equipped|Socket|Lord of"
                               . "|Attacks per Second|Damage Per Second|Block Chance")
            continue

        soDau := "", wDau := "", tenSau := ""
        for i, c in ws
        {
            ; cho phép tối đa 2 ký tự rác dính trước số:  "=+12.5%"  "#+3,500"
            if RegExMatch(c[12], "^[^\d]{0,2}([\d][\d.,]*)%?$", m)
            {
                ; Mọi từ ĐỨNG TRƯỚC con số phải là MỘT ký tự. Dòng affix
                ; thật chỉ có đúng một ký tự đứng trước: dấu chấm đầu dòng ◆
                ; (OCR đọc thành © e ¢ @ ®) hoặc dấu sao ✳ (đọc thành # *).
                ; Có từ THẬT đứng trước nghĩa là dòng này là CÂU VĂN, không
                ; phải dòng affix. Ô soi nằm bên TRÁI con số, gặp câu văn thì
                ; nó trùm lên chữ -> sáng rực -> báo có sao oan. Đã đo thật:
                ; "costs 33 Primary Resource." 0.517, "they are 70% more
                ; potent." 0.490, "dealing 300% of their damage over 5" 0.257
                ; — đều vượt ngưỡng, đều không phải affix.
                cauVan := false
                Loop, % i - 1
                    if (StrLen(Trim(ws[A_Index][12])) > 2)
                        cauVan := true
                if (cauVan)
                    break
                ; ngay sau số phải là CHỮ -> mới là affix.
                ; Chặn "Requires Level 70", "helm by 39%" (số đứng cuối).
                if (i + 1 > ws.Length() || !RegExMatch(ws[i + 1][12], "^[A-Za-z]{2}"))
                    break
                soDau := m1, wDau := c, tenSau := ws[i + 1][12]
                break
            }
        }
        if (soDau = "")
            continue
        x0 := wDau[7] + 0, y0 := wDau[8] + 0, hh := wDau[10] + 0
        if (hh < 6)
            continue
        bx0 := Round(x0 - hh * SAO_RONG), bx1 := Round(x0 - hh * 0.15)
        if (bx0 < 0)
            bx0 := 0
        by0 := y0 - 3, by1 := y0 + hh + 3
        if (by0 < 0)
            by0 := 0
        if (by1 > caoAnh - 1)
            by1 := caoAnh - 1
        if (bx1 - bx0 < 5 || by1 - by0 < 5)
            continue

        sang := 0, tong := 0
        yy := by0
        while (yy <= by1)
        {
            xx := bx0
            while (xx < bx1)
            {
                argb := 0
                DllCall("gdiplus\GdipBitmapGetPixel", "ptr", pBm
                      , "int", xx, "int", yy, "uint*", argb)
                v := (((argb >> 16) & 0xFF) + ((argb >> 8) & 0xFF) + (argb & 0xFF)) // 3
                if (v > SAO_SANG)
                    sang++
                tong++
                xx++
            }
            yy++
        }
        if (tong = 0)
            continue
        matDo := sang / (hh * hh)
        if (SAO_LOG)
        {
            chuDong := ""
            for i2, c2 in ws
                chuDong .= c2[12] . " "
            FileAppend, % Format("{:.3f}", matDo) . "   h=" . hh . " o=" . (bx1 - bx0)
                       . "x" . (by1 - by0) . "   " . SubStr(Trim(chuDong), 1, 40) . "`n"
                       , % thuMuc . "\_sao.log", UTF-8
        }
        ; Khoá = SỐ + 3 chữ đầu của tên affix. Chỉ dùng số thì hai dòng cùng
        ; số (vd hai dòng "+3") sẽ lẫn vào nhau.
        if (matDo > SAO_NGUONG)
            coSao[KhoaAffix(soDau, tenSau)] := true
    }

    DllCall("gdiplus\GdipDisposeImage", "ptr", pBm)
    GdipStop(pTok, hM)

    ; gắn dấu "**" vào những dòng khớp cả SỐ lẫn TÊN
    ra := ""
    Loop, Parse, chuDaLoc, `n, `r
    {
        d := A_LoopField
        ; Phai nhan ca dau "x" va truong hop so dinh lien chu, giong het
        ; cho doc dong. Thieu chu "x" thi moi affix Damage Multiplier do
        ; duoc la co sao nhung khong bao gio gan duoc dau.
        if (RegExMatch(d, "^[+x]?\s*([\d][\d.,]*)%?\s*([A-Za-z]\S*)", m)
            && coSao.HasKey(KhoaAffix(m1, m2)))
            d := "**" . d
        ra .= d . "`n"
    }
    ; Dấu hiệu "phần dò ĐÃ CHẠY". Thiếu Tesseract / thiếu .tsv thì hàm này
    ; thoát sớm và không có dòng này -> tiện ích Chrome sẽ KHÔNG đụng vào
    ; công tắc Greater Affix, thay vì xoá nhầm dấu sao trang đã nhận đúng.
    return ra . "#D4L-SAO-OK"
}

KhoaAffix(so, ten)
{
    s := RegExReplace(so, "[^\d]", "")
    t := RegExReplace(ten, "[^A-Za-z]", "")
    StringLower, t, t
    return s . "|" . SubStr(t, 1, 3)
}

;=====================================================================
;   LỌC CHỮ THÔ CỦA TESSERACT
;
;   Tesseract nhả ra kèm rác: dấu bullet (*), viền khung (|), mảnh icon
;   ("oe", "C >"), và chữ dính liền ("+3toImbuement").
;
;   Lọc theo TỪ chứ không theo ký tự: bỏ những từ ở đầu/cuối dòng mà ngắn
;   dưới 2 chữ cái, không chứa số, và không phải từ thật.
;   Lọc theo ký tự sẽ ăn mất dấu ")" của "(+14,106.1% Toughness)".
;=====================================================================
LocChu(raw)
{
    ds := []
    Loop, Parse, raw, `n, `r
    {
        d := LocMotDong(A_LoopField)
        if (d = "")
            continue
        ; phải có ít nhất 3 chữ cái mới coi là dòng thật
        if (StrLen(RegExReplace(d, "[^A-Za-z]", "")) < 3)
            continue
        ds.Push(d)
    }
    if (ds.Length() = 0)
        return ""

    ; TÊN MÓN không phải lúc nào cũng ở dòng đầu — đã gặp ảnh mà Tesseract
    ; nhả "900 Item Power" lên trước. Neo vào dòng LOẠI ĐỒ ("Ancestral Unique
    ; Helm") rồi lấy dòng ngay TRƯỚC nó. Không thấy thì mới đành lấy dòng 1.
    ; CHỈ dò trong 4 dòng đầu. Cuối tooltip còn có "Unique Equipped" — không
    ; chặn thì có ảnh nó chạy tuốt xuống dưới rồi tưởng "Requires Level 70"
    ; là tên món (đã gặp thật).
    viTriTen := 1
    hetDo := (ds.Length() < 4) ? ds.Length() : 4
    Loop, % hetDo
    {
        if (A_Index > 1
            && RegExMatch(ds[A_Index], "i)\b(Unique|Legendary|Rare|Magic|Mythic|Common)\b\s+\S"))
        {
            viTriTen := A_Index - 1
            break
        }
    }
    ; TÊN CÓ THỂ NẰM TRÊN NHIỀU DÒNG: tên dài thì game tự xuống dòng
    ; ("ROYALTY" / "DOWNFALL"). Gộp mọi dòng TRƯỚC dòng loại đồ lại.
    if (viTriTen > 1)
    {
        gop := ""
        Loop, % viTriTen
            gop .= (gop = "" ? "" : " ") . ds[A_Index]
        Loop, % viTriTen - 1
            ds.RemoveAt(1)
        ds[1] := gop
        viTriTen := 1
    }
    ds[viTriTen] := LocTenMon(ds[viTriTen])

    ; ĐƯA DÒNG TÊN LÊN ĐẦU. Tiện ích Chrome lấy dòng 1 làm tên món để đối
    ; chiếu với form; có ảnh Tesseract nhả "900 Item Power" lên trước tên,
    ; không dời thì tiện ích tưởng sai món và từ chối điền.
    if (viTriTen > 1)
    {
        ten := ds[viTriTen]
        ds.RemoveAt(viTriTen)
        ds.InsertAt(1, ten)
    }

    ra := ""
    for i, d in ds
        ra .= d . "`n"
    return RTrim(ra, "`n")
}

;   Dòng đầu là TÊN MÓN. Font tên trong game rất cách điệu nên Tesseract hay
;   đọc chữ O thành @ ("LE@RIC'S CROWN"). Không sửa thì chốt kiểm tên của
;   tiện ích Chrome sẽ tưởng sai món và từ chối điền.
LocTenMon(d)
{
    StringUpper, d, d
    ; Ký tự Tesseract hay nhầm với chữ O trong font tên món (đã gặp thật:
    ; "LE@RIC'S CROWN" và "LE®RIC'S CROWN"). Không sửa thì chốt kiểm tên của
    ; tiện ích Chrome tưởng sai món và từ chối điền.
    ; KHÔNG được thêm số 0 vào đây: có ảnh Tesseract nhả "900 Item Power"
    ; lên dòng đầu, map 0->O sẽ biến nó thành "OO ITEM POWER".
    d := RegExReplace(d, "[@€Ø®©]", "O")
    d := RegExReplace(d, "[^A-Z' \-]", " ")
    return Trim(RegExReplace(d, "\s+", " "))
}

LocMotDong(d)
{
    ; Rac "=" dinh truoc dau: "=+1,813" -> "+1,813",  "=x35%" -> "x35%"
    ; PHAI bat ca dau "x": moi affix Damage Multiplier deu viet kieu "x35%".
    d := RegExReplace(d, "=\s*([+x])", "$1")
    ; Mảnh icon bullet hay dính liền vào số: "*+1,813", "T+12.5%".
    ; Chỉ cắt chữ cái khi nó dính NGAY trước dấu +, vì "x50% Critical..."
    ; là cách viết THẬT của D4 (chữ x rồi tới số) — không được đụng vào.
    d := RegExReplace(d, "^\s*[A-Za-z]{1,2}(?=\+)", "")
    d := RegExReplace(d, "^\s*[*|_~\[\]{}<>]+", "")
    ; "+3toImbuement" -> "+3 to Imbuement",  "+2to AllSkills" -> "+2 to AllSkills"
    ; Phải bắt cả khi sau "to" là DẤU CÁCH: không tách thì con số dính liền chữ,
    ; dòng không còn dạng "<số> <chữ>" nữa và bị bỏ luôn.
    d := RegExReplace(d, "(\d)to(?=[A-Za-z\s])", "$1 to ")
    ; --- Cắt đuôi GIỚI HẠN THEO CLASS ---------------------------------
    ; Trong game viết "+111 Dexterity (🗡 🛡 Only)". Mấy cái icon đó OCR đọc
    ; ra rác, và dấu "(" có khi thành ";". Đã gặp thật:
    ;     "+111 Dexterity; %% Only)"
    ;     "+282LifeonKill (i @ 9 PD @O HY |"
    ;
    ; ĐO ĐƯỢC: trong 638 tên affix thật của diablo.trade, KHÔNG tên nào
    ; chứa chữ "Only" hay dấu "(" ";" "[". Nên cắt ở đó là an toàn tuyệt đối.
    d := RegExReplace(d, "i)\s*[^A-Za-z0-9]*\bOnly\b.*$", "")

    ; Cắt phần trong ngoặc NẾU nó không có từ thật nào (từ >= 4 chữ cái).
    ; Giữ lại "1,603 Armor (+37.4% Toughness)" vì "Toughness" là từ thật —
    ; dòng đó cần nguyên vẹn để bên tiện ích còn nhận ra là chỉ số GỐC.
    if RegExMatch(d, "^(.*?)([(;\[{].*)$", p)
    {
        if !RegExMatch(p2, "[A-Za-z]{4}")
            d := p1
    }
    d := RegExReplace(d, "\s+", " ")
    d := RegExReplace(d, "\s+", " ")
    d := Trim(d)
    if (d = "")
        return ""

    toks := StrSplit(d, " ")
    dau := 1, cuoi := toks.Length()
    while (dau <= cuoi && LaRac(toks[dau]))
        dau++
    while (cuoi >= dau && LaRac(toks[cuoi]))
        cuoi--
    if (dau > cuoi)
        return ""

    ra := ""
    Loop, % (cuoi - dau + 1)
        ra .= (ra = "" ? "" : " ") . toks[dau + A_Index - 1]
    return Trim(ra, " _|")
}

LaRac(tok)
{
    t := RegExReplace(tok, "[|_~\[\]{}<>*]", "")
    if (t = "")
        return true
    if RegExMatch(t, "\d")          ; có số thì chắc chắn là dữ liệu thật
        return false
    if (StrLen(t) > 2)
        return false
    StringLower, tl, t
    ; từ ngắn nhưng CÓ THẬT trong tooltip D4 -> không được bỏ
    return !InStr("|to|of|in|by|a|as|is|at|on|or|x|hp|up|all|", "|" . tl . "|")
}

;=====================================================================
;   Số thứ tự tiếp theo cho file ảnh: 001, 002, ...
;=====================================================================
SoTiepTheo()
{
    global QUEUE_DIR
    n := 0
    Loop, %QUEUE_DIR%\*.png
    {
        SplitPath, A_LoopFileName, , , , ten
        if (RegExMatch(ten, "^\d+$") && (ten + 0 > n))
            n := ten + 0
    }
    return SubStr("000" . (n + 1), -2)
}

;=====================================================================
;=====================================================================
;   PHẦN LÕI CHỤP VÙNG — lấy từ "Screen clipping tool.ahk" của bạn
;   Đóng băng màn hình rồi kéo chọn vùng, giống Snipping Tool.
;   Ưu điểm: bắt được cả tooltip đang hiện, và vùng chọn đứng yên
;   để kéo cho chính xác.
;=====================================================================
;=====================================================================

; Tạo 1 lớp phủ (màu đặc 'color', độ mờ 'trans' 0-255 hoặc "" = đặc).
; +E0x08000000 = WS_EX_NOACTIVATE: không cướp focus.
FzOverlay(name, color, trans)
{
    Gui, %name%:Destroy
    Gui, %name%:+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000 +LastFound
    Gui, %name%:Color, %color%
    hwnd := WinExist()
    Gui, %name%:Show, NA x-32000 y-32000 w1 h1
    if (trans != "")
        WinSet, Transparent, %trans%, ahk_id %hwnd%
    return hwnd
}

; Di chuyển/đổi kích thước 1 lớp phủ. w/h <= 0 -> giấu ra ngoài màn hình.
FzMove(hwnd, x, y, w, h)
{
    if (w <= 0 || h <= 0)
        WinMove, ahk_id %hwnd%, , -32000, -32000, 1, 1
    else
        WinMove, ahk_id %hwnd%, , x, y, w, h
}

; 4 dải làm mờ bao quanh vùng chọn (vùng chọn KHÔNG bị mờ -> sáng lên).
FzDimUpdate(dT, dB, dL, dR, vx, vy, vw, vh, sx, sy, sw, sh)
{
    FzMove(dT, vx, vy, vw, sy - vy)
    byy := sy + sh
    FzMove(dB, vx, byy, vw, (vy + vh) - byy)
    FzMove(dL, vx, sy, sx - vx, sh)
    rxx := sx + sw
    FzMove(dR, rxx, sy, (vx + vw) - rxx, sh)
}

; 4 đường viền quanh vùng chọn.
FzBorderUpdate(bT, bB, bL, bR, sx, sy, sw, sh)
{
    th := 2
    if (sw <= 0 || sh <= 0)
    {
        FzMove(bT, 0, 0, 0, 0)
        FzMove(bB, 0, 0, 0, 0)
        FzMove(bL, 0, 0, 0, 0)
        FzMove(bR, 0, 0, 0, 0)
        return
    }
    FzMove(bT, sx - th, sy - th, sw + th * 2, th)
    FzMove(bB, sx - th, sy + sh, sw + th * 2, th)
    FzMove(bL, sx - th, sy - th, th, sh + th * 2)
    FzMove(bR, sx + sw, sy - th, th, sh + th * 2)
}

FzCleanup()
{
    Gui, FzBase:Destroy
    Gui, FzDimT:Destroy
    Gui, FzDimB:Destroy
    Gui, FzDimL:Destroy
    Gui, FzDimR:Destroy
    Gui, FzBrdT:Destroy
    Gui, FzBrdB:Destroy
    Gui, FzBrdL:Destroy
    Gui, FzBrdR:Destroy
}

; Đóng băng màn hình + kéo chọn. Trả về object {x,y,w,h,file,ox,oy}
; (tọa độ màn hình; file = ảnh đóng băng toàn màn hình ảo; ox,oy = góc ảnh)
; hoặc "" nếu hủy / vùng quá nhỏ.
FreezeSelectRegion(hintText := "")
{
    ToolTip
    FzCleanup()

    ; Chờ tới khi menu chuột phải (#32768) và tooltip (tooltips_class32) đang
    ; hiện BIẾN MẤT rồi mới chụp. Không có gì thì chụp gần như tức thì.
    tCap := A_TickCount + 400
    Loop
    {
        if (!WinExist("ahk_class #32768") && !WinExist("ahk_class tooltips_class32"))
            break
        if (A_TickCount >= tCap)
            break
        Sleep, 15
    }

    ; Chờ luồng video remote (Parsec) gửi xong khung hình sắc nét.
    ; Trong lúc chờ, ĐỪNG động vào chuột — mọi chuyển động đều bắt bộ nén
    ; phải chia lại bit và làm ảnh mờ trở lại.
    if (CAPTURE_DELAY > 0)
        Sleep, %CAPTURE_DELAY%

    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79

    frozen := A_Temp . "\d4lister_frozen_" . A_TickCount . ".png"
    CaptureScreenArea(vx, vy, vw, vh, frozen)

    ; Nhớ cửa sổ đang active (thường là game) để trả focus lại sau khi chọn xong
    prevWin := 0
    if (GRAB_FOCUS)
    {
        WinGet, prevWin, ID, A
        ; Gỡ khóa con trỏ: game hay giới hạn chuột trong cửa sổ của nó bằng
        ; ClipCursor. Không gỡ thì không rê chuột lên lớp phủ được.
        DllCall("ClipCursor", "ptr", 0)
    }

    ; Lớp nền: ảnh đóng băng, phủ kín
    Gui, FzBase:Destroy
    if (GRAB_FOCUS)
        Gui, FzBase:+AlwaysOnTop -Caption +ToolWindow -DPIScale +LastFound
    else
        Gui, FzBase:+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000 +LastFound
    Gui, FzBase:Margin, 0, 0
    Gui, FzBase:Add, Picture, x0 y0 w%vw% h%vh%, %frozen%
    hBase := WinExist()
    if (GRAB_FOCUS)
    {
        ; Hiện có kích hoạt -> game mất focus -> game nhả chuột ra
        Gui, FzBase:Show, x%vx% y%vy% w%vw% h%vh%
        WinActivate, ahk_id %hBase%
        DllCall("ClipCursor", "ptr", 0)   ; gỡ lần nữa phòng khi game vừa khóa lại
    }
    else
        Gui, FzBase:Show, NA x%vx% y%vy% w%vw% h%vh%

    dT := FzOverlay("FzDimT", "000000", 130)
    dB := FzOverlay("FzDimB", "000000", 130)
    dL := FzOverlay("FzDimL", "000000", 130)
    dR := FzOverlay("FzDimR", "000000", 130)
    bT := FzOverlay("FzBrdT", "33AAFF", "")
    bB := FzOverlay("FzBrdB", "33AAFF", "")
    bL := FzOverlay("FzBrdL", "33AAFF", "")
    bR := FzOverlay("FzBrdR", "33AAFF", "")

    FzDimUpdate(dT, dB, dL, dR, vx, vy, vw, vh, vx, vy, 0, 0)

    if (hintText != "")
        ToolTip, %hintText%

    ; Đợi nhấn chuột trái (Esc để hủy)
    Loop
    {
        if FzDown("Escape")
        {
            ToolTip
            FzCleanup()
            FzRestoreFocus(prevWin)
            FileDelete, %frozen%
            return ""
        }
        if FzDown("LButton")
            break
        Sleep, 10
    }
    ToolTip

    MouseGetPos, sx0, sy0
    while FzDown("LButton")
    {
        if FzDown("Escape")
        {
            FzCleanup()
            FzRestoreFocus(prevWin)
            FileDelete, %frozen%
            return ""
        }
        MouseGetPos, cx, cy
        x := FzMin(sx0, cx)
        y := FzMin(sy0, cy)
        w := Abs(cx - sx0)
        h := Abs(cy - sy0)
        FzDimUpdate(dT, dB, dL, dR, vx, vy, vw, vh, x, y, w, h)
        FzBorderUpdate(bT, bB, bL, bR, x, y, w, h)
        Sleep, 10
    }
    MouseGetPos, cx, cy
    x := FzMin(sx0, cx)
    y := FzMin(sy0, cy)
    w := Abs(cx - sx0)
    h := Abs(cy - sy0)

    FzCleanup()
    FzRestoreFocus(prevWin)

    if (w < 10 || h < 10)
    {
        FileDelete, %frozen%
        return ""
    }
    return { x: x, y: y, w: w, h: h, file: frozen, ox: vx, oy: vy }
}

;=====================================================================
;   ĐỌC TRẠNG THÁI PHÍM/CHUỘT — chấp nhận CẢ input do phần mềm gửi vào
;
;   QUAN TRỌNG: chỉ dùng chế độ "vật lý" (cờ "P") thì chuột do phần mềm
;   gửi vào KHÔNG được ghi nhận — mà chuột Parsec chuyển từ máy remote sang
;   máy game chính là loại đó. Hậu quả: bấm F3 thấy màn hình đóng băng
;   nhưng KÉO CHỌN KHÔNG ĂN.
;
;   Nhận cả hai kiểu thì chạy được cả khi ngồi trực tiếp lẫn khi điều khiển
;   từ xa qua Parsec / Remote Desktop / phần mềm giả lập chuột.
;=====================================================================
FzDown(key)
{
    return GetKeyState(key, "P") || GetKeyState(key)
}

; Trả focus về cửa sổ trước đó (thường là game) để túi đồ không bị đóng,
; và để bấm F3 món kế tiếp là chụp được ngay.
FzRestoreFocus(prevWin)
{
    if (!prevWin)
        return
    WinActivate, ahk_id %prevWin%
    Sleep, 30
}

FzMin(a, b)
{
    return a < b ? a : b
}

;=====================================================================
;   GDI+  -  gdiplus.dll có sẵn trên mọi Windows, không phải cài gì
;=====================================================================

GdipStart(ByRef hModule)
{
    hModule := DllCall("LoadLibrary", "str", "gdiplus.dll", "ptr")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "uint")
    if (DllCall("gdiplus\GdiplusStartup", "ptr*", pToken, "ptr", &si, "ptr", 0) != 0)
        return 0
    return pToken
}

GdipStop(pToken, hModule)
{
    if (pToken)
        DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
    if (hModule)
        DllCall("FreeLibrary", "ptr", hModule)
}

; Chụp vùng (x,y,w,h) trên màn hình -> bitmap GDI+ (0 = thất bại).
GdipCaptureScreen(x, y, w, h)
{
    hdcScreen := DllCall("GetDC", "ptr", 0, "ptr")
    hdcMem    := DllCall("CreateCompatibleDC", "ptr", hdcScreen, "ptr")
    hbm       := DllCall("CreateCompatibleBitmap", "ptr", hdcScreen, "int", w, "int", h, "ptr")
    obm       := DllCall("SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
    ; SRCCOPY | CAPTUREBLT (bắt cả cửa sổ layered/trong suốt)
    DllCall("BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h
        , "ptr", hdcScreen, "int", x, "int", y, "uint", 0x00CC0020 | 0x40000000)
    DllCall("SelectObject", "ptr", hdcMem, "ptr", obm)
    DllCall("DeleteDC", "ptr", hdcMem)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScreen)
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", pBitmap)
    DllCall("DeleteObject", "ptr", hbm)
    return pBitmap
}

GdipSavePng(pImage, outFile)
{
    VarSetCapacity(clsid, 16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", &clsid)
    return DllCall("gdiplus\GdipSaveImageToFile", "ptr", pImage, "wstr", outFile, "ptr", &clsid, "ptr", 0)
}

; Chụp vùng màn hình ra file PNG.
CaptureScreenArea(x, y, w, h, outFile)
{
    hModule := 0
    pToken := GdipStart(hModule)
    if (!pToken)
    {
        GdipStop(0, hModule)
        throw Exception("GDI+ startup failed.")
    }

    pBitmap := GdipCaptureScreen(x, y, w, h)
    if (!pBitmap)
    {
        GdipStop(pToken, hModule)
        throw Exception("GDI+ could not capture screen region.")
    }

    status := GdipSavePng(pBitmap, outFile)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    GdipStop(pToken, hModule)

    if (status != 0)
        throw Exception("GDI+ could not save image.", , "Status: " . status)
    if !FileExist(outFile)
        throw Exception("GDI+ did not create image.", , outFile)
}

; Cắt vùng (cx,cy,cw,ch) từ file ảnh 'srcFile' -> lưu PNG 'outFile'.
GdipCropFile(srcFile, cx, cy, cw, ch, outFile)
{
    hModule := 0
    pToken := GdipStart(hModule)
    if (!pToken)
    {
        GdipStop(0, hModule)
        throw Exception("GDI+ startup failed.")
    }
    pSrc := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", srcFile, "ptr*", pSrc)
    if (!pSrc)
    {
        GdipStop(pToken, hModule)
        throw Exception("GDI+ could not load frozen image.", , srcFile)
    }
    pCrop := 0
    DllCall("gdiplus\GdipCloneBitmapAreaI", "int", cx, "int", cy, "int", cw, "int", ch
        , "int", 0x26200A, "ptr", pSrc, "ptr*", pCrop)   ; 0x26200A = 32bppARGB
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
    if (!pCrop)
    {
        GdipStop(pToken, hModule)
        throw Exception("GDI+ could not crop region.")
    }
    status := GdipSavePng(pCrop, outFile)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCrop)
    GdipStop(pToken, hModule)
    if (status != 0 || !FileExist(outFile))
        throw Exception("GDI+ could not save crop.", , "status " . status)
}

;=====================================================================
;   ĐẶT ẢNH VÀO CLIPBOARD bằng API Windows
;
;   QUAN TRỌNG: phải dùng CF_DIB + global memory, KHÔNG dùng CF_BITMAP.
;   CF_BITMAP là handle GDI thuộc tiến trình -> tiến trình chết thì handle
;   chết theo, clipboard báo "có ảnh" nhưng dán ra rỗng. Global memory thì
;   hệ thống sở hữu nên sống sót. Windows tự sinh CF_BITMAP từ CF_DIB.
;=====================================================================
SetImageClipboard(imageFile, chu := "")
{
    hModule := 0
    pToken := GdipStart(hModule)
    if (!pToken)
    {
        GdipStop(0, hModule)
        throw Exception("GDI+ startup failed.")
    }

    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", imageFile, "ptr*", pBitmap)
    if (!pBitmap)
    {
        GdipStop(pToken, hModule)
        throw Exception("Could not load image for Clipboard.", , imageFile)
    }
    w := 0, h := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", w)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", h)
    hbm := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hbm, "uint", 0xFFFFFFFF)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    GdipStop(pToken, hModule)
    if (!hbm)
        throw Exception("Could not convert image for Clipboard.")

    ; BITMAPINFOHEADER 24bpp (tương thích rộng nhất khi dán)
    stride := ((w * 3) + 3) & ~3
    sizeImage := stride * h
    VarSetCapacity(bi, 40, 0)
    NumPut(40, bi, 0, "uint")            ; biSize
    NumPut(w, bi, 4, "int")              ; biWidth
    NumPut(h, bi, 8, "int")              ; biHeight (dương = bottom-up, chuẩn DIB)
    NumPut(1, bi, 12, "ushort")          ; biPlanes
    NumPut(24, bi, 14, "ushort")         ; biBitCount
    NumPut(0, bi, 16, "uint")            ; biCompression = BI_RGB
    NumPut(sizeImage, bi, 20, "uint")    ; biSizeImage

    hGlobal := DllCall("GlobalAlloc", "uint", 0x0042, "ptr", 40 + sizeImage, "ptr")
    if (!hGlobal)
    {
        DllCall("DeleteObject", "ptr", hbm)
        throw Exception("Could not allocate memory for Clipboard.")
    }
    pGlobal := DllCall("GlobalLock", "ptr", hGlobal, "ptr")
    DllCall("RtlMoveMemory", "ptr", pGlobal, "ptr", &bi, "ptr", 40)
    hdc := DllCall("GetDC", "ptr", 0, "ptr")
    ok := DllCall("GetDIBits", "ptr", hdc, "ptr", hbm, "uint", 0, "uint", h
        , "ptr", pGlobal + 40, "ptr", pGlobal, "uint", 0)   ; 0 = DIB_RGB_COLORS
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
    DllCall("GlobalUnlock", "ptr", hGlobal)
    DllCall("DeleteObject", "ptr", hbm)
    if (!ok)
    {
        DllCall("GlobalFree", "ptr", hGlobal)
        throw Exception("Could not read image bits for Clipboard.")
    }

    ; Chuẩn bị thêm bản PNG nguyên gốc để đặt kèm lên clipboard.
    ; Win+Shift+S cũng đặt PNG, và Chrome ưu tiên lấy PNG hơn bitmap thô
    ; -> ảnh dán vào diablo.trade giữ đúng chất lượng gốc.
    hPng := LoadFileToGlobal(imageFile)

    if (!DllCall("OpenClipboard", "ptr", 0))
    {
        DllCall("GlobalFree", "ptr", hGlobal)
        if (hPng)
            DllCall("GlobalFree", "ptr", hPng)
        throw Exception("Could not open Clipboard.")
    }
    DllCall("EmptyClipboard")

    ; Định dạng "PNG" (đăng ký động). Đặt trước để Chrome thấy và ưu tiên dùng.
    if (hPng)
    {
        fmtPng := DllCall("RegisterClipboardFormat", "str", "PNG", "uint")
        if (!fmtPng || !DllCall("SetClipboardData", "uint", fmtPng, "ptr", hPng, "ptr"))
            DllCall("GlobalFree", "ptr", hPng)   ; đặt hụt -> mình vẫn sở hữu, phải giải phóng
    }

    ; CF_DIB = 8. Thành công -> HỆ THỐNG sở hữu hGlobal, không được GlobalFree nữa.
    if (!DllCall("SetClipboardData", "uint", 8, "ptr", hGlobal, "ptr"))
    {
        DllCall("CloseClipboard")
        DllCall("GlobalFree", "ptr", hGlobal)
        throw Exception("Could not copy image to Clipboard.")
    }

    ; CF_UNICODETEXT = 13. Đây là chỗ nối với tiện ích Chrome.
    ; Một lần Ctrl+V: diablo.trade nhặt ẢNH để nhận ra món đồ, còn tiện ích
    ; nhặt CHỮ này để ghi đè các ô chỉ số. Hai bên không giẫm chân nhau.
    if (chu != "")
    {
        soByte := (StrLen(chu) + 1) * 2
        hTxt := DllCall("GlobalAlloc", "uint", 0x0042, "ptr", soByte, "ptr")
        if (hTxt)
        {
            pTxt := DllCall("GlobalLock", "ptr", hTxt, "ptr")
            StrPut(chu, pTxt, StrLen(chu) + 1, "UTF-16")
            DllCall("GlobalUnlock", "ptr", hTxt)
            if (!DllCall("SetClipboardData", "uint", 13, "ptr", hTxt, "ptr"))
                DllCall("GlobalFree", "ptr", hTxt)
        }
    }
    DllCall("CloseClipboard")
}

;=====================================================================
;   Đọc nguyên file vào global memory (cho clipboard).
;   Trả về handle, hoặc 0 nếu hỏng -> nơi gọi tự bỏ qua, không làm chết luồng.
;=====================================================================
LoadFileToGlobal(path)
{
    FileGetSize, fsz, %path%
    if (!fsz)
        return 0

    f := FileOpen(path, "r")
    if (!IsObject(f))
        return 0
    VarSetCapacity(buf, fsz, 0)
    got := f.RawRead(buf, fsz)
    f.Close()
    if (got != fsz)
        return 0

    hMem := DllCall("GlobalAlloc", "uint", 0x0042, "ptr", fsz, "ptr")
    if (!hMem)
        return 0
    pMem := DllCall("GlobalLock", "ptr", hMem, "ptr")
    if (!pMem)
    {
        DllCall("GlobalFree", "ptr", hMem)
        return 0
    }
    DllCall("RtlMoveMemory", "ptr", pMem, "ptr", &buf, "ptr", fsz)
    DllCall("GlobalUnlock", "ptr", hMem)
    return hMem
}
