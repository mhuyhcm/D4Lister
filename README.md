# D4Lister v4

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

> **v4** — AutoHotkey **v4**, tiện ích Chrome **7.3**.
>
> **Bỏ hoàn toàn chụp ảnh và OCR.** Diablo 4 có sẵn chức năng đọc item thành
> lời cho người khiếm thị; D4Lister cắm vào đó và lấy **thẳng chữ của game**.
>
> - **Rê chuột lên item rồi bấm F3.** Hết kéo chọn vùng, hết chờ đọc ảnh.
> - **Không bao giờ đọc nhầm số** — chữ là chữ thật của game, không phải đoán
>   từ điểm ảnh.
> - **Dấu ✱ Greater Affix nhận chắc chắn**: dòng nào không in khoảng
>   `[min - max]` thì là ✱. Xem [NHAT-KY-V4.md](NHAT-KY-V4.md).
> - **Tiện ích tự dựng món** trên trang (loại đồ, độ hiếm, tên, Aspect, sức
>   mạnh, ổ ngọc) — vì không còn ảnh cho trang quét.
> - **Không cần Tesseract** (nhẹ đi 164 MB) và **không cần Borderless
>   Windowed**.

Ý tưởng cốt lõi vẫn thế: **tách hai giai đoạn**. Gom hết item trong game
trước (không alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài trên một máy mới

Tải đúng **một file** rồi bấm đúp:

https://raw.githubusercontent.com/mhuyhcm/D4Lister/main/CAI-DAT.bat

*(Chuột phải vào link → Save link as…)*

Nó tự lo hết: tải mã nguồn (~250 KB), **kiểm tra máy đã có AutoHotkey chưa —
thiếu thì tự tải về cài**, rồi chạy. **Không cần cài Git.**

| Cần | Nặng | Bắt buộc? | Lấy ở đâu |
|---|---|---|---|
| AutoHotkey 1.1 | 3 MB | **có** | trang chủ autohotkey.com |

Máy chặn mạng thì mở `_he-thong\TAI-VE-TAY.txt`, trong đó có sẵn đường tải
để làm tay.

Xong nó nhắc bạn **hai việc phải làm tay**.

### Việc 1 — nạp tiện ích vào Chrome

Đường dẫn đã chép sẵn vào clipboard:

1. Gõ vào thanh địa chỉ: `chrome://extensions`
2. Bật **Developer mode** (góc trên bên phải)
3. Bấm **Load unpacked**
4. Trong ô File name bấm **Ctrl+V** rồi **Select Folder**

Chrome bắt buộc chính người dùng bấm — không chương trình nào lách được.

### Việc 2 — mở đường ống TTS (chỉ một lần)

Đây là cách D4Lister đọc item: **game đọc chữ ra thẳng cho tool**.

1. **Thoát hẳn Diablo 4**
2. Chạy `_he-thong\CAI-TTS.cmd` — nó tự tìm thư mục game qua tiến trình đang
   chạy, Registry, Battle.net rồi quét ổ đĩa; không ra mới hỏi bạn gõ tay
3. Bật game, vào Options bật ba công tắc:

   | Mục | Công tắc |
   |---|---|
   | Accessibility | **Use Screen Reader** |
   | Accessibility | **3rd Party Screen Reader** |
   | Gameplay | **Advanced Tooltip Information** |

Script làm đúng ba việc: tải `saapi64.dll` từ repo D4LF (giấy phép MIT), ký
nó bằng một chứng chỉ **tự ký** nằm trong kho cá nhân của tài khoản Windows
(game chỉ nạp DLL có chữ ký), rồi **thêm** file đó vào thư mục game. Không
đụng kho tin cậy hệ thống, không sửa file nào của game.

Muốn huỷ: xoá `saapi64.dll` trong thư mục game, xoá chứng chỉ `D4Lister TTS`
trong `certmgr.msc → Personal → Certificates`.

## Từ đó về sau: bấm đúp `D4Lister.ahk`

Chỉ một file. Mỗi lần chạy nó tự làm hai việc:

```
1. Hỏi GitHub có bản mới không
       có   →  tải về, ghi đè, tự nạp lại  ↺
       không →  đi tiếp
2. Sẵn sàng
```

Bấm **Ctrl+Shift+F11** lúc nào cũng được để nạp lại và kiểm tra bản mới.

Mất mạng thì bỏ qua im lặng. Thư mục `queue\` và file riêng của bạn không bao
giờ bị đè.

## Cập nhật tiện ích Chrome

Chrome **không bao giờ** tự nạp lại tiện ích cài kiểu *Load unpacked*. File trên
đĩa đã mới mà trình duyệt vẫn chạy bản cũ — không ai biết.

Nên D4Lister gửi kèm số hiệu bản trên đĩa mỗi lần bạn dán. Tiện ích so với bản
nó đang chạy, lệch thì **hiện băng đỏ ngay trên trang**:

> **Tiện ích đang chạy bản cũ** — đang chạy 7.2, trên đĩa đã là 7.3.
> Vào chrome://extensions bấm nút xoay vòng, rồi F5 trang này.

Chỉ báo khi **trên đĩa mới hơn**. Dán lại một món chụp từ trước khi nâng bản
thì nó mang số cũ — chuyện bình thường, không báo gì.

Không thể bỏ sót được.

## Sửa code ở máy chính rồi đẩy lên

```
git add -A
git commit -m "mo ta ngan"
git push
```

Các máy khác lần sau chạy `CHAY.bat` là tự có.

Máy khác chưa mở đường ống TTS thì F3 báo *"Game chưa nối vào đường ống"* —
chạy `_he-thong\CAI-TTS.cmd` một lần là xong.

---

## Phím

| Phím | Việc |
|---|---|
| **F2** | *(trong game)* quét cả rương và túi đồ một lượt |
| **F3** | *(trong game)* lấy món đang rê chuột |
| **F4** | *(trên trình duyệt)* dán món hiện tại |
| **F5 / F6** | sang món kế / lùi món trước |
| **F9** | xoá sạch danh sách đang chờ đăng |
| **Ctrl+Shift+F11** | nạp lại script (và kiểm tra bản mới) |
| **Ctrl+Shift+F12** | thoát |

Không còn F7/F8 — đó là hai phím đổi chế độ xử lý ảnh của bản cũ.

---

## Quy trình

**Trong game** — rê chuột lên item rồi `F3`. Lặp cho từng món. Không alt-tab
lần nào. Tooltip hiện `3/3  NEEDLEFLARE HORNED CUDGEL` — liếc một cái là biết
đúng món chưa.

Bấm F3 hai lần cùng một món thì nó báo *"Món này lấy rồi"* chứ không lặng lẽ
thêm bản thứ hai.

**Hoặc `F2` — lấy cả rương một lượt.** Mở rương trong game rồi bấm F2. Một
hộp thoại hiện ra hỏi quét gì:

```
┌ QUÉT HÀNG LOẠT ────────────────────────────┐
│ KHO RƯƠNG                                  │
│ Rương của bạn có: (•) 7 tab  ( ) 6 tab     │
│ ☑Tab 1  ☑Tab 2  ☐Tab 3  ☐Tab 4             │
│ ☐Tab 5  ☐Tab 6  ☐Tab 7                     │
│ TÚI ĐỒ NHÂN VẬT                            │
│ ☑ Quét cả túi đồ đang mang trên người      │
│ TUỲ CHỌN                                   │
│ ☑ Dò lại những ô không thấy gì             │
│ ☐ Chờ vài giây rồi mới bắt đầu quét  [5]   │
│              [ Bắt đầu quét ]  [ Đóng ]    │
└────────────────────────────────────────────┘
```

Nó rê con trỏ qua từng ô, ô nào có đồ thì lấy. Rê nhầm chỗ hay rương chưa mở
thì nó **dừng và báo**, không quét bừa. Bấm `Esc` lúc đang chạy là dừng.

Xong có báo cáo. Mặc định nó **ở lại trên màn cho tới khi bạn bấm Esc** —
muốn tự tắt thì tick *Time hiển thị báo cáo* rồi chọn số giây:

```
QUÉT XONG
12 món mới  ·  3 trùng
Đọc được 15/15 ô có đồ
      Tab 1:   7/7
      Túi đồ:  8/8
Đang chờ đăng: 12 món
```

**Con số bên phải là số ô mà nó NHÌN THẤY có đồ** — đọc bằng điểm ảnh, không
qua chữ của game. Hai nguồn độc lập, nên sót là lộ ra ngay:

```
QUÉT XONG — CẦN XEM LẠI
29 món mới
Đọc được 29/30 ô có đồ
      Tab 1:   29/30

⚠ SÓT 1 ô — nhìn thấy có đồ mà không đọc ra:
   Tab 1: hàng 3 ô 6
```

Chi tiết từng ô nằm trong `nhat-ky-quet.txt` cạnh script — mỗi ô một dòng, để
đối chiếu xem có sót món nào không.

Lựa chọn trong hộp thoại nhớ vào `quet.ini`, lần sau mở lên là thấy nguyên.

**Sang trình duyệt** — mở trang Create ở chế độ **BETA**, để nguyên hộp thoại
`ADD ITEM…`:

```
F4  →  dán món 1  →  ext tự dựng món  →  tự điền  →  tự đăng sau 5 giây
F5  →  dán món 2  →  …
```

---

## Cách nó chạy

```
Diablo 4  →  Tolk.dll (Blizzard đóng sẵn)  →  saapi64.dll (ta cắm vào)
          →  \.\pipe\d4lf  →  D4Lister.ahk  →  clipboard (chỉ chữ)
          →  tiện ích Chrome  →  form diablo.trade
```

Chữ nhận được là **chữ thật của game**, không phải đoán từ điểm ảnh — nên
không có chuyện `+2` thành `42` hay `196` thành `19` như bản OCR.

D4Lister lọc chữ đó bằng cách **neo vào cấu trúc tooltip**, chứ không nuôi
danh sách tên để lọc:

| Loại đồ | Khối chỉ số bắt đầu ở |
|---|---|
| vũ khí | sau dòng `Damage Per Second` ba dòng |
| trang sức | ngay sau dòng `All Resist` |
| khiên | sau dòng `Armor` ba dòng |
| giáp | ngay sau dòng `Armor` |

Nhờ vậy Item Power, DPS, Damage per Hit, Attacks per Second, All Resist tự
rụng. Chi tiết và toàn bộ bẫy đã gỡ: [NHAT-KY-V4.md](NHAT-KY-V4.md).

Con số đi **thẳng từ chữ của game vào ô nhập**, không qua bộ quét ảnh của
diablo.trade. Đó là chỗ tránh được hết lỗi đọc sai số.

---

## Tiện ích tự dựng món

V2 dán ảnh rồi để trang tự dựng món. V3 không còn ảnh, nên tiện ích tự làm:

```
Unique / Mythic :  gõ tên món  →  bấm gợi ý
Rare / Legendary:  bấm nút loại đồ trong lưới 29 nút
                       ↓
                   lưới độ hiếm: thẻ "<độ hiếm> <loại đồ>"
                       ↓
                   Legendary còn một bước: chọn Aspect
```

Chọn Aspect khó nhất: chữ của game **không nói tên Aspect**, chỉ in mô tả, mà
danh sách trên trang lại ảo hoá. Cách đi: lọc danh mục của trang lấy phần
`ASPECT`, khớp **mô tả** ngoại tuyến để ra **tên**, gõ tên vào ô tìm rồi bấm.
Khớp dưới 95% thì không bấm gì — nhường bạn chọn.

Ngoài affix, tiện ích còn đặt: **sức mạnh item**, **Unique Power / Aspect**
(kèm công tắc *Maxxed out*), và **số ổ ngọc**.

---

## Thiết lập

Bấm vào chip **D4Lister** ở góc dưới bên phải là mở bảng thiết lập. Đổi xong
dùng ngay, không phải sửa file, không phải nạp lại.

| Mục | Mặc định | Nghĩa |
|---|---|---|
| Tự đăng | bật | Điền xong, mọi thứ sạch thì tự bấm SUBMIT |
| Đăng cả khi có cảnh báo | **tắt** | Bật lên là số sai vẫn lên sàn mà bạn không biết |
| Tự bấm Scan | bật | Chỉ dùng khi bạn tự dán ảnh — V3 không cần |
| Ghi thẳng vào form | bật | Lấy khoảng hợp lệ từ trang, thêm dòng khỏi gõ chữ |
| Nhảy vào ô giá | bật | Điền xong đặt con trỏ vào ô giá luôn |
| Tự chọn base | bật | Bước chọn hình món đồ |
| **Tự dựng món** | bật | V3: tự chọn loại đồ, độ hiếm, tên, Aspect |
| Tự thêm affix thiếu | bật | Dòng nào trang thiếu thì tự thêm |
| Tự bật dấu sao | bật | Greater Affix — xem mục dưới |
| Ghi cấu trúc ra Console | **tắt** | Chỉ bật khi cần chẩn đoán |
| Ghi file dò | **tắt** | Tải file chẩn đoán về máy |
| Đếm ngược | 5 giây | Thời gian chờ trước khi bấm đăng |

Hai nút ở cuối bảng:

- **Dò lớp phủ** — mở lần lượt các ô chọn rồi ghi cấu trúc ra Console
- **Chép nhật ký** — chép cả xấp nhật ký vào clipboard, khỏi mở F12 lọc tay

Thiết lập lưu trong trình duyệt, mỗi máy một bản riêng.

---

## Tự đăng

Điền xong, nếu **mọi thứ sạch** thì đếm ngược rồi tự bấm SUBMIT. Bạn không
phải bấm gì.

Có cảnh báo (số vượt khoảng, thiếu dòng, tên không khớp) thì **dừng lại** và
chờ bạn xem. Muốn đăng luôn thì bật *Đăng cả khi có cảnh báo* — nhưng bật rồi
thì số sai cũng lên sàn mà không ai biết.

Gõ giá xong bấm **Enter** cũng là đăng.

---

## Dấu sao (Greater Affix)

Dấu ✱ là **hình vẽ**, TTS không gửi. Nhưng không cần nó:

```
+120 Intelligence +[100 - 121]          có ngoặc  → affix thường
+3,500 Poison Resistance                KHÔNG     → ★ GREATER
6.5% Cooldown Reduction [5.0 - 8.0]%    có ngoặc  → thường
```

Affix thường bị chặn cứng trong khoảng của nó nên game **luôn** in được
khoảng. Affix Greater roll ở trần rồi nhân 1,5 nên vượt ra ngoài, in kèm
khoảng sẽ vô lý → game giấu khoảng đi. Đọc ngược "không có khoảng = Greater"
vì thế không sai được.

Một chỗ phải nhớ: **bật dấu sao TRƯỚC khi ghi số**. Trang chỉ cho vượt trần
khi công tắc đang bật; ghi 3500 lúc sao còn tắt thì bị cắt còn 2800, và bật
sao sau đó không kéo lại được.

---

## Hàng đợi

```
queue.txt   ← mỗi món một file chữ
```

Không còn ảnh. Một món nặng khoảng 300 byte thay vì 344 KB, nên qua Parsec
đồng bộ clipboard cũng nhanh hơn hẳn.

Thấy còn `.png`/`.tsv` trong `queue\` là hàng đợi của bản cũ — D4Lister tự
dọn lúc khởi động và báo cho bạn.

---

## Thư mục

```
D4Lister.ahk      ← bấm đúp cái này, hết
CAI-DAT.bat       ← chỉ dùng một lần trên máy mới
NHAT-KY-V4.md     ← nhật ký v4 và toàn bộ bẫy đã gỡ
extension\        ← Chrome trỏ vào đây
queue\            ← chữ đã gom
_he-thong\        ← không cần đụng vào
     CAI-TTS.cmd               mở đường ống TTS (chạy một lần)
     CAI-TTS.ps1               phần việc thật của CAI-TTS.cmd
     d4lister-nen.ps1          cài / cập nhật
     TAI-VE-TAY.txt            đường tải tay, dùng khi máy chặn mạng
     CHAY.bat                  dự phòng nếu không bấm đúp .ahk được
     TAT-HET.bat
     CAI-TIEN-ICH-CHROME.bat
     DONG-GOI.cmd              đóng gói bản hiện tại thành .zip
```

Bản tải về khoảng **250 KB**. V2 còn kéo theo Tesseract 164 MB; V3 bỏ hẳn.

### Đóng gói để dành trên máy

Bấm đúp `_he-thong\DONG-GOI.cmd`. Nó đẻ ra
`_ban-phat-hanh\D4Lister-v4.zip` — giải nén ra đâu cũng chạy, **không cần
mạng, không cần repo còn sống**. Gói kèm cả bộ cài AutoHotkey nên khoảng
3,4 MB; máy trắng bung ra là dùng được.

Script tự đọc số hiệu bản từ mã nguồn, và **dừng lại nếu số bản trong
`manifest.json` lệch với `const BAN` trong `d4lister.js`** — lệch thì trình
duyệt chạy một bản mà báo một bản khác.
