# D4Lister v4 — nhật ký và các bẫy đã gỡ

Ngày chốt: **24/09/2026**
AutoHotkey `D4Lister.ahk` **v4** · tiện ích Chrome `d4lister.js` **7.3**

---

## V4 đổi cái gì

V3 lấy **một món** mỗi lần rê chuột. V4 thêm **F2 — quét cả rương và túi đồ
một lượt**, đúng phần `B1` trong `Y-TUONG-V4.md`.

| | V3 | V4 |
|---|---|---|
| Lấy một món | F3 | F3 (giữ nguyên) |
| Lấy cả rương | không có | **F2** |
| Chọn quét gì | — | hộp thoại hai phần, nhớ lựa chọn |
| Biết có sót không | — | sổ ghi từng ô + báo cáo cuối lượt |
| Biết rương mở chưa | — | đọc một đường kẻ, 12/12 điểm |
| Thiết lập tiện ích | 11 ô tick đổ liền | hai tab: dùng hằng ngày / nhà phát triển |

**F2 làm gì.** Rê con trỏ qua từng ô rương (5×10) và túi đồ (3×11), ô nào có
đồ thì game gửi tooltip ra đường ống, ô trống thì game im lặng. Chọn tab nào,
có quét túi đồ không, chờ mấy giây rồi mới chạy — hỏi trong hộp thoại ngay
lúc bấm, và nhớ vào `quet.ini`.

**Chống sót.** Đây là phần tốn công nhất, vì sót một món thì không ai biết:

* ô im lặng được **hỏi lại một lượt nữa** với ngưỡng chờ gấp ba;
* món đọc được mà không hiểu được **đếm riêng** thay vì bỏ im;
* chống trùng khoá theo **vị trí ô**, không theo nội dung — hai món giống hệt
  nhau ở hai ô là hai món hàng (xem bẫy 28);
* tooltip của ô trước về muộn thì **hỏi lại cho chắc** chứ không đoán;
* mọi ô đều có một dòng trong `nhat-ky-quet.txt`, cuối lượt đối chiếu được.

**Toạ độ.** Đo thật từ ảnh chụp, không dùng công thức quy đổi của D4LF — công
thức của họ sai 12–13 px ở dải tab. Và công thức của **chính tôi** cũng sai:
xem mục *Dải tab KHÔNG phải một dãy đều căn giữa* ở phần **Đo được**.

---

## V3 đổi cái gì

Bỏ **hoàn toàn** chụp ảnh và OCR. Diablo 4 có sẵn chức năng đọc item thành
lời cho người khiếm thị; ta cắm một file khách vào đó và lấy thẳng chữ của
game.

| | V2 (chụp + OCR) | V3 (TTS) |
|---|---|---|
| Số dòng mã AHK | 1.895 | 926 |
| Thao tác mỗi món | rê chuột → F3 → **kéo chọn vùng** | rê chuột → **F3** |
| Chờ đọc chữ | Tesseract ~1,04 s | 0 |
| Nhận dấu ✱ | đo độ sáng pixel, ngưỡng 0,25 | có ngoặc `[min - max]` hay không |
| Cần Tesseract | có (164 MB) | **không** |
| Cần Borderless Windowed | có | **không** |
| Clipboard | ảnh ~344 KB + chữ | chỉ chữ (~300 byte) |
| Dựng món trên trang | trang quét ảnh rồi tự dựng | **ext tự dựng** |

---

## Đường ống TTS

```
Diablo 4  →  Tolk.dll (Blizzard đóng sẵn)  →  saapi64.dll (ta cắm vào)
          →  \\.\pipe\d4lf  →  D4Lister.ahk
```

`saapi64.dll` lấy từ repo D4LF (giấy phép MIT). Game chỉ nạp DLL **có chữ
ký**, nên `_he-thong\CAI-TTS.cmd` tạo một chứng chỉ **tự ký** trong kho cá
nhân của tài khoản Windows rồi ký file. Không đụng kho tin cậy hệ thống,
không sửa file nào của game — chỉ **thêm** một file.

Bật trong game: *Options → Accessibility →* **Use Screen Reader** +
**3rd Party Screen Reader**; *Options → Gameplay →* **Advanced Tooltip
Information**.

---

## Thủ thuật quan trọng nhất: nhận dấu ✱ Greater Affix

Dấu ✱ là **hình vẽ**, TTS không gửi. Nhưng không cần nó:

```
+120 Intelligence +[100 - 121]          có ngoặc  → affix thường
+3,500 Poison Resistance                KHÔNG     → ★ GREATER
6.5% Cooldown Reduction [5.0 - 8.0]%    có ngoặc  → thường
```

**Vì sao chắc chắn:** affix thường bị chặn cứng trong khoảng của nó nên game
luôn in được khoảng. Affix Greater roll ở trần rồi nhân 1,5 nên giá trị vượt
ra ngoài, in kèm khoảng sẽ vô lý → game giấu khoảng đi. Đọc ngược "không có
khoảng = Greater" vì thế không sai được: affix thường **không có đường nào**
vượt trần để mà mất khoảng.

D4LF làm y hệt, nhánh cuối trong `_AFFIX_RE` của họ:

```python
(?P<greateraffix2>[0-9]+[.0-9]*)(?![^\[]*\[).*
```

**Bẫy:** luật phải là *"không có ngoặc NÀO"*, không phải *"không có dấu
gạch"*. Đồ cấp thấp có dạng `+2 Weapon Damage [2]` — ngoặc giá trị cố định,
vẫn là affix thường.

**Ngoại lệ D4LF ghi rõ trong mã:** dòng `Charm Slot` trông như Greater nhưng
không bao giờ là Greater.

---

## Neo vào cấu trúc, không lọc bằng danh sách tên

Chỗ bắt đầu khối chỉ số (lấy theo `_get_affix_starting_location_from_tts_section`
của D4LF):

| Loại đồ | Khối chỉ số bắt đầu ở |
|---|---|
| vũ khí | sau dòng `Damage Per Second` **ba** dòng |
| trang sức | ngay sau dòng `All Resist` |
| khiên | sau dòng `Armor` ba dòng |
| giáp | ngay sau dòng `Armor` |

Kết thúc ở một trong `Empty Socket`, `Requires Level`, `Sell Value`,
`Durability`, `Tempers:`, `… mouse button`…

Nhờ neo vào cấu trúc, mấy dòng không cần (Item Power, DPS, Damage per Hit,
Attacks per Second, All Resist) **tự rụng** — không phải nuôi danh sách tên
để lọc như V2.

---

## Các dòng điều khiển gửi kèm

```
NEEDLEFLARE HORNED CUDGEL
Legendary Two-Handed Mace
850 Item Power
+309 Weapon Damage [187 - 312]
**+3500 Poison Resistance          ← ** = Greater Affix
#D4L-UNIQUE:80|80|110              ← giá trị | trần dưới | trần trên
#D4L-ASPECT:Thorns damage dealt…   ← mô tả, để dò ngược ra tên Aspect
#D4L-SOCKET:2
#D4L-SAO-OK                        ← cờ "phần dò dấu sao đã chạy"
#D4L-EXT:7.1
```

`#D4L-SAO-OK` **bắt buộc phải có**. Thiếu nó thì tiện ích **tắt ngầm** toàn
bộ việc bật/tắt dấu sao — nó thà không đụng còn hơn xoá nhầm dấu sao trang
đã nhận đúng. Cờ này do hàm đo pixel của V2 phát ra; V3 xoá hàm đó nên suýt
mất luôn cờ.

---

## Dựng món trên diablo.trade (chế độ BETA)

```
Unique / Mythic :  gõ tên món  →  bấm [role=option][data-value^="unique:"]
Rare / Legendary:  bấm nút loại đồ trong lưới 29 nút (không cần gõ)
                       ↓
                   lưới ĐỘ HIẾM: thẻ "<độ hiếm> <loại đồ>"
                       ↓
                   Legendary còn một bước: chọn Aspect
```

**Chọn Aspect:** chữ của game không nói tên Aspect, chỉ in mô tả. Danh sách
Aspect trên trang lại **có ảo hoá** (vẽ 12 thẻ trong khi có hàng trăm). Cách
đi: lọc `type === 'ASPECT'` trong danh mục React của trang, khớp **mô tả**
ngoại tuyến để ra **tên**, gõ tên vào ô tìm, rồi bấm thẻ. Khớp dưới 95% thì
không bấm gì — trả quyền lại cho người dùng.

Khớp mô tả bỏ hết số và ngoặc, nên `#` của danh mục và số thật của game quy
về cùng một chuỗi:

```
chữ game : Thorns damage dealt has a chance to deal damage to all enemies…
danh mục : Thorns damage dealt has a chance to deal damage to all enemies…
  100%  Aspect of Retribution      ← chọn
   41%  Aspect of Amplified Damage
```

---

## BẢNG BẪY — đọc trước khi sửa

*(22 cái; cái thứ 20 nằm ở mục "đẩy một phát" bên dưới)*

### 1. Sinh mã có regex qua heredoc thì mất dấu gạch chéo

`'\\b('` trong nguồn bị rút còn `'\b('` — tức **ký tự backspace** trong chuỗi
JS, `new RegExp` không khớp gì cả. Đã dính **ba lần**, hai ngôn ngữ (Python,
JS). Luôn sửa mã có regex bằng công cụ sửa file trực tiếp.

Bài thử cũng phải **lấy thẳng hàm từ file thật** (`new Function(...)`) chứ
không chép tay — chép tay là có dịp nuốt gạch chéo rồi kết luận oan cho mã
đang chạy.

### 2. Tên đường ống mất một gạch chéo

`"\.\pipe\d4lf"` thay vì `"\\.\pipe\d4lf"` → Windows từ chối, đường ống không
bao giờ dựng được. Cùng gốc với bẫy 1.

### 3. Đọc một câu mỗi nhịp = trễ vài giây

Đường ống chạy ở **chế độ thông điệp**: mỗi `ReadFile` trả về **đúng một
câu**. Đọc một câu mỗi nhịp 40 ms thì một tooltip mười mấy câu mất hơn nửa
giây; rê qua bốn món là hàng đợi dồn hơn hai giây, F3 lấy phải món cũ.
→ **Vét cạn** đường ống mỗi nhịp, và F3 vét ngay trước khi lấy.

### 4. Game chèn ký tự vô hình vào tên món

`GALVANIC<U+00A0>AZURITE<U+00A0>` — khoảng trắng không ngắt, `Trim` không cắt
được. Tiện ích đối chiếu tên món nên để lọt là nó từ chối điền.
`FileAppend … UTF-8` còn đặt thêm **BOM** dính liền vào tên ở dòng đầu →
phải dùng `UTF-8-RAW`.

### 5. Trang vẽ danh sách theo hai kiểu khác nhau

| Trạng thái | Mỗi thẻ là |
|---|---|
| ô tìm còn trống | `<button>` |
| đã gõ chữ (đã lọc) | `div[role="option"][cmdk-item]`, **không còn `<button>` nào** |

Chỉ tìm `button` thì càng lọc đúng tên càng không thấy gì.

### 6. Hỏi sai câu lúc chờ danh sách lọc

Hỏi *"có thẻ nào chưa"* → trả lời **có ngay**, vì 12 thẻ cũ vẫn đang hiện.
Chấm điểm trên thẻ cũ rồi bỏ cuộc đúng lúc thẻ thật sắp hiện.
→ Phải hỏi *"có thẻ **đúng tên** chưa"*.

### 7. Dòng affix cố định của đồ Unique không có nút Remove

Nhận khối của một dòng bằng cách đi ngược lên tìm `button[aria-label^="Remove "]`
thì bỏ sót dòng đó → ext tưởng thiếu, thêm thành **dòng thứ hai y hệt**.
→ Khối của một dòng = **tổ tiên gần nhất chỉ chứa đúng một ô `Affix value`**.

### 8. Phải bật dấu sao TRƯỚC khi ghi số

Trang chặn giá trị trong khoảng thường, **chỉ** khi công tắc Greater Affix
đang bật mới cho vượt trần. Ghi `3500` vào `Poison Resistance` (khoảng
1–2800) lúc sao còn tắt thì bị cắt còn 2800, và bật sao sau đó **không kéo
lại được**. Mục Unique Power cũng vậy với công tắc *Maxxed out*.

### 9. Trang đặt mặc định kịch trần cho Unique Power

Dựng đồ Unique xong, mục Unique Power mặc định là **trần** (60% trong khi món
thật 44%). Không sửa thì món nào cũng khai sai chỗ người mua nhìn kỹ nhất.

### 10. Sổ sách form phình ra ≠ màn hình vẽ ra

`dayCaLoat` từng chỉ kiểm mảng của form có dài thêm không. Mảng đi từ 1 lên 4
mà màn hình vẫn một dòng → ba dòng kia không có ô nhập, mọi con số ghi vào
rơi vào chỗ không ai thấy, mà hàm vẫn báo thành công nên **đường dự phòng
không hề chạy**.
→ Phải đợi **màn hình** vẽ đủ ô mới công nhận.

### 11. `setValue` lên một mảng dòng KHÔNG vẽ lại màn hình

react-hook-form: `useFieldArray` giữ sổ sách riêng. `setValue('affixes', …)`
đổi giá trị nhưng giao diện đứng im. Phải gọi `replace()` / `append()` của
chính nó — **hoặc** `reset()` cả form, đây là đường vòng chạm tới được
`useFieldArray` mà không cần cầm được nó.

### 12. Mảng rỗng thì không nhận ra bộ quản lý mảng

Phép nhận dạng cũ đối chiếu `id` của mục đầu tiên, nên mảng rỗng là chịu.
V2 không sao (trang tự dựng sẵn dòng); V3 thì **món mới luôn rỗng** → lần nào
cũng hụt → lần nào cũng phải gõ chữ.
→ Mảng rỗng thì đối chiếu bằng **vị trí**: đi ngược lên từ nút
`ADD STANDARD AFFIXES`. Nhiều ứng viên thì thử bằng chính việc đẩy thật,
không ăn thì trả lại nguyên trạng rồi sang cái kế.

### 13. Với tới nhầm form của món trước

Mỗi lần dựng món mới là trang thay một form mới; form cũ bị tháo khỏi màn
hình nhưng **vẫn còn vết trong cây React**. Nhật ký bắt được: form giữ
`[Willpower, Maximum Life, Critical Strike Damage Multiplier, Cooldown
Reduction]` — đúng bốn chỉ số của món Legendary lần trước — trong khi màn
hình là chiếc nhẫn Unique.

Hai chỗ phải sửa:
- **Phép kiểm:** màn hình 0 ô affix thì mảng affix cũng phải rỗng. (Bản cũ
  gặp màn hình rỗng là gật đầu với mọi form.)
- **Chỗ tìm:** `useForm()` trả về đối tượng nằm trong **chuỗi hook**, không
  phải `memoizedProps`. Bản cũ chỉ soi props nên chỉ vớ được form cũ còn sót
  trong props của một Provider. Hết đường neo thì **quét cả cây**.

### 14. `getValues('affixes')` trả về `undefined`, không phải mảng rỗng

Món vừa dựng xong chưa có dòng nào thì react-hook-form **chưa đăng ký** mảng
đó. Loại thẳng vì "không phải mảng" là loại sạch mọi form, rồi lọt xuống form
cũ (form cũ có mảng vì đã dùng rồi).

### 15. Thử nhiều đường thì phải chờ NGẮN

Bốn đường đẩy thẳng × 1200 ms chờ mỗi đường = **gần 5 giây đứng im** trước
khi đường dự phòng nhúc nhích. 450 ms là đủ rộng: React vẽ lại sau một lần
đổi trạng thái là xong trong một khung hình.

### 16. Đóng rồi mở lại danh sách mỗi dòng

Tốn gần một giây mỗi dòng, và đó cũng là cái làm nó **nhìn** giống người đang
bấm tay. Giữ danh sách mở suốt cả lượt; ngó đến khi danh sách thật sự có dòng
khớp thay vì ngủ một khoảng cố định.

### 17. Đừng đếm theo sổ sách của form khi hỏi "trang xong chưa"

Sổ sách đổi ngay khi ext ghi → đếm theo nó là tự ru mình. Đếm theo **ô nhập
trên màn hình**. Và V3 có thể tạo ra món **không có dòng affix nào**, nên chờ
`n > 0` là chờ mãi — nhận ra form đã dựng bằng nút `ADD STANDARD AFFIXES`.

### 18. Hàng đợi cũ của V2 lẫn vào

V2 để Tesseract đẻ ra `NNN.txt` cạnh `NNN.png`; V3 cũng lưu `.txt` nhưng nội
dung khác hẳn. Thấy còn `.png`/`.tsv` là biết hàng đợi bản cũ → dọn sạch.

### 19. PowerShell 5.1 `Set-Content -Encoding UTF8` thêm BOM

BOM trong `manifest.json` có thể làm Chrome từ chối nạp tiện ích. Sửa phiên
bản bằng Python/`utf-8` không BOM, và kiểm lại sau mỗi lần sửa.

---

### 21. Đường dẫn game khác nhau trên mỗi máy

Bản đầu của `CAI-TTS.ps1` dò đúng 6 đường dẫn đoán mò rồi bắt gõ tay — trên
máy khác là hỏng. Giờ dò sáu nguồn, chắc nhất trước:

| # | Nguồn | Ghi chú |
|---|---|---|
| 1 | tiến trình game đang chạy | chắc nhất, hỏi thẳng Windows |
| 2 | Registry *Uninstall* | Battle.net ghi `InstallLocation`; cả ba kho 64/32/HKCU |
| 3 | Registry khoá Blizzard | `InstallPath` |
| 4 | `Battle.net.config` | JSON, đường dẫn dạng `F:\Diablo IV` |
| 5 | quét ổ đĩa | 7 chỗ quen thuộc × mọi ổ, không quét sâu |
| 6 | hỏi người dùng | thử tối đa ba lần, có chỉ đường lấy từ Battle.net |

Đo trên máy thật: **180 ms**. Hàm kiểm nhận cả đường dẫn trỏ thẳng vào
`Diablo IV.exe` lẫn đường dẫn còn nguyên ngoặc kép (người dùng hay chép cả
ngoặc từ Explorer).

---

### 22. Luật nhận dấu sao phụ thuộc một công tắc trong game

Luật *"không in `[min - max]` ⇒ Greater Affix"* dựa vào chuyện game **có in
khoảng hay không**. Mà thứ in ra cái khoảng đó chính là
**Options → Gameplay → Advanced Tooltip Information**.

Tắt công tắc ⇒ không dòng nào có khoảng ⇒ đóng dấu sao lên **toàn bộ** affix
⇒ đăng sai hàng loạt, im lặng.

D4LF chặn bằng phép đếm 80% (`src/loot/filter.py`). Ta làm chặt hơn: đếm số
món **liên tiếp** mà mọi dòng có số đều không ngoặc. Một món như vậy vẫn có
thể thật (đồ 4 sao); **ba món liên tiếp** thì không còn là may mắn.

Chạm ngưỡng thì **không phát cờ `#D4L-SAO-OK`** — tiện ích để nguyên dấu sao
thay vì đóng bừa, đúng công dụng cờ đó sinh ra để làm. Và F3 báo đỏ cho
người dùng.

Đã thử: bật → đếm 0, có cờ. Tắt → 1, 2, 3 rồi ngừng phát cờ. Bật lại → về 0
ngay.

### 23. `Menu, ..., DeleteAll` trên menu chưa tồn tại — giết luồng, không một lời

Đây là cái bẫy tốn nhiều giờ nhất của bản này.

`DungMenuQuet()` mở đầu bằng `Menu, mQuet, DeleteAll` để dựng lại menu từ đầu
mỗi lần đổi lựa chọn. Lần **đầu tiên** gọi thì `mQuet` chưa tồn tại, và
AutoHotkey v1 phản ứng bằng cách **kết thúc luôn luồng đang chạy**:

* không hộp lỗi,
* không ghi gì ra `stderr`, kể cả khi chạy với `/ErrorStdOut`,
* tiến trình **vẫn sống**, biểu tượng khay vẫn hiện,
* `/iLib` kiểm cú pháp vẫn báo sạch — vì đây là lỗi lúc chạy.

Lời gọi nằm trong phần tự chạy, nên mọi dòng phía sau mất sạch: phím tắt
không đăng ký, `MoOng()` không chạy, **đường ống không bao giờ được dựng**.
Nhìn từ ngoài: script chạy, F3 câm, D4LF không nối được — chẳng có manh mối
nào chỉ về cái menu.

Bắt được bằng cách chèn `FileAppend` sau **từng dòng** của phần tự chạy rồi
xem dòng cuối cùng nào kịp ghi.

Chữa: thêm một mục mầm để menu chắc chắn có rồi mới xoá sạch.

```ahk
Menu, mQuet, Add, _mam, BamChonTab   ; tạo menu nếu chưa có
Menu, mQuet, DeleteAll
```

Hai bẫy phụ đi kèm, cũng đáng nhớ:

* **`FileAppend, chữ, tên-file` — tham số tên file KHÔNG phải biểu thức.**
  Bọc tên file trong dấu nháy thì dấu nháy thành một phần của tên, file không
  đẻ ra. Bài thử đầu tiên của tôi dính đúng lỗi này nên ra kết quả rỗng, và
  tôi kết luận nhầm là đoạn mã không chạy — mất một vòng chẩn đoán.
* **Liệt kê đường ống bằng `[IO.Directory]::GetFiles` lúc được lúc không**, có
  lần ném thẳng `DirectoryNotFoundException`. Muốn biết ống có thật hay không
  thì **nối thử** bằng `NamedPipeClientStream.Connect(700)`.

### 24. Lại đúng cái bẫy 23, hai lần nữa

Bẫy 23 nói `Menu ... DeleteAll` trên menu chưa có thì AutoHotkey giết luồng
mà không báo gì. Hoá ra đó không phải một trường hợp lẻ — đây là **cách
AutoHotkey v1 phản ứng với nhiều lỗi lúc chạy**. Triệu chứng luôn y hệt:
`/iLib` báo cú pháp sạch, tiến trình vẫn sống, không hộp lỗi, không stderr,
và mọi dòng sau chỗ lỗi coi như không tồn tại.

Bản này dính thêm hai lần:

**Đọc kích thước control trước khi `Gui Show`.** `GuiControlGet, p, Msg:Pos`
gọi lúc cửa sổ chưa hiện thì trả về rỗng, chuỗi toạ độ dựng từ đó thành rác
(`"x y w Right ..."`), và luồng chết. Phải `Show` trước, đo sau, rồi `Show`
lại để nới cửa sổ.

**Biến gắn với control GUI phải TOÀN CỤC.** Thêm `vMsgChu` trong một hàm có
khai báo `global` chọn lọc — tức hàm đang ở phạm vi cục bộ — là chết. Khai
báo thêm `global MsgChu, MsgDem` là xong.

Cách dò vẫn là cách của bẫy 23: chèn `FileAppend` sau từng dòng rồi xem dòng
cuối cùng nào kịp ghi. Lần thứ hai còn nhanh hơn — **không mốc nào ghi** thì
biết ngay lỗi nằm trước cả mốc đầu tiên, tức ở phần khai báo.

---

### 25. Nhận biết rương đang mở bằng một đường kẻ

V3 đã bỏ hết bộ xử lý ảnh, nhưng `PixelGetColor` thì vẫn còn và rất rẻ.

Không so màu tuyệt đối — nền game đổi liên tục. So **tương quan**: mép trái
lưới rương là một gờ sáng chạy dọc, bên trái nó là dải tối. Lấy 12 điểm dọc
theo `x = 42`, mỗi điểm so với điểm cách 6 px về bên trái; gờ phải sáng ≥ 35
và hơn bên trái ≥ 28.

Đo trên ảnh thật: rương 6 tab **12/12**, rương 7 tab **11/12**, ba ảnh không
phải rương (kể cả một ảnh Path of Exile 2) **0/12**. Ngưỡng 9/12 nằm giữa
hai cụm rất xa nhau.

Chịu được xê dịch 1 px ngang bằng cách lấy giá trị sáng nhất trong
`x ∈ {41, 42, 43}`.

Không kiểm lưới túi đồ: thử thì được 7/11 trên một ảnh, 0/11 trên ảnh kia, mà
lại **báo nhầm 6/11 trên ảnh Path of Exile**. Nhưng bỏ đi cũng không sao, vì
toạ độ lưới túi đồ vốn đo **trên màn hình rương** — mở túi đồ một mình thì bố
cục khác. Rương mở là điều kiện cần cho cả hai lưới.

### 26. Tìm cửa sổ game theo TIÊU ĐỀ là một cái bẫy

`WinGet, hwnd, ID, Diablo IV` — AutoHotkey mặc định khớp kiểu **bắt đầu
bằng**. Nghĩa là bất cứ cửa sổ nào có tiêu đề bắt đầu bằng "Diablo IV" đều
khớp, kể cả một cửa sổ Explorer đang mở thư mục tên *Diablo IV* — mà thư mục
đó thì máy nào cài game cũng có.

Hậu quả không phải "không tìm thấy" mà tệ hơn nhiều: F2 sẽ **rê chuột và bấm**
lên cửa sổ đó theo toạ độ của game.

Thử thật, lúc game đang chạy, dựng thêm một cửa sổ mang đúng tiêu đề
"Diablo IV" rồi đưa lên trước:

| Cách tìm | Trả về |
|---|---|
| theo tiêu đề `Diablo IV` | `0xfa0cb2` — **cửa sổ giả** |
| theo `ahk_exe Diablo IV.exe` | `0x1560d68` — game thật |

Nhận theo tệp thực thi thì không thể nhầm. Lớp cửa sổ của game, nếu cần:
`Diablo IV Main Window Class`.

---

### 27. Gốc vùng vẽ đổi giữa hai buổi — và vì sao không sao cả

Đo lại lúc game đang chạy: gốc vùng vẽ là `0,31`. Hôm đo lưới thì là `0,23`.
Cửa sổ đã dịch xuống 8 px.

Kiểm lại bằng chính hai ảnh chụp cũ — ảnh toàn màn hình nên đỉnh cửa sổ nằm
trong ảnh: độ sáng mỗi hàng cho thấy phần game bắt đầu **đúng tại y = 23** ở
cả hai ảnh. Vậy lúc đo, gốc đúng là 23, và các hằng số suy ra từ đó
(`RUONG_Y = 256`, `TAB_Y = 162`) đều đúng.

Cửa sổ dịch đi mà mọi thứ vẫn khớp, vì mã cộng `gy` **đọc lúc chạy** chứ
không chôn cứng. Đây chính là lý do phải lưu toạ độ theo vùng vẽ thay vì theo
màn hình — một quyết định lúc viết tưởng là thừa, hoá ra đã tự cứu mình.

### 28. Chống trùng theo NỘI DUNG làm mất món — sót mà không ai biết

Bẫy tệ nhất của bản này, vì nó **không báo gì cả**: đếm ra thiếu một món và
chẳng có dấu hiệu nào để lần ra.

F2 rê qua lại nhiều ô nên phải chống đọc trùng. Tôi chống bằng cách so **nội
dung món** với tất cả những gì đã lấy trong lượt. Nghe hợp lý, nhưng sai ngay
ở giả thiết: hai món **giống hệt nhau** ở hai ô khác nhau — hai chiếc nhẫn
cùng chỉ số chẳng hạn — là **hai món hàng**, hai thứ để bán. Món thứ hai bị
vứt im lặng.

Người dùng phát hiện ra bằng câu hỏi *"thực tế 9 món mà quét ra 8"* — không
phải từ log, không phải từ một lỗi nào nhảy ra.

Chữa: khoá chống trùng là **vị trí ô** (`nơi | hàng | cột | nội dung`), vì
một ô chỉ chứa một món. Kèm nội dung vào khoá để đổi đồ trong rương rồi quét
lại vẫn nhận ra là món khác.

Kiểm bằng rương giả:

| tình huống | trước | sau |
|---|---|---|
| 2 món y hệt, 2 ô khác nhau | 1 mới + 1 trùng ❌ | 2 mới ✓ |
| quét lại đúng ô đó | trùng ✓ | trùng ✓ |
| cùng vị trí, tab khác | trùng ❌ | mới ✓ |

Bài học: **"chống trùng" phải hỏi trùng theo cái gì.** Trùng nội dung không
có nghĩa là trùng vật thể.

### 29. Cùng một cửa sổ, hai máy ra hai vùng vẽ khác nhau

Máy thứ hai (qua Parsec) báo *"vùng vẽ 1920×1017"* trong khi máy gốc luôn ra
1920×1027. Lệch đúng 10 px, và mọi toạ độ của F2 đo ở 1027.

Đo hai máy thì thấy nguyên nhân:

```
vùng vẽ = chiều cao cửa sổ − viền

máy A   cửa sổ 1066   viền dọc 39   →  vùng vẽ 1027
máy B   cửa sổ 1066   viền dọc 49   →  vùng vẽ 1017
```

**Viền dày bao nhiêu là do Windows quyết, không phải do game** — khác chủ đề,
khác mức phóng DPI, hoặc màn hình ảo của phần mềm điều khiển từ xa. Cùng một
cỡ cửa sổ cho ra hai vùng vẽ khác nhau.

Nên chỉnh thì **đừng đặt cứng chiều cao cửa sổ**. Đo viền tại chỗ rồi cộng:

```ahk
viềnDọc  := caoCửaSổ - caoVùngVẽ        ; đo ngay lúc chạy
WinMove, …, CLIENT_W + viềnNgang, CLIENT_H + viềnDọc
```

Hai chốt kèm theo:

* **Đặt xong phải đo lại.** Game có thể tự nắn lại cỡ theo ý nó, và lúc ấy
  báo "đã chỉnh xong" là nói dối. Thử tối đa 3 lượt rồi chịu thua và nói thật.
* **Cả vùng vẽ phải nằm trong màn hình**, không riêng góc trên. Lưới túi đồ
  chạy tới `x = 1851`; phần nào lọt ra ngoài thì `PixelGetColor` đọc không ra
  mà rê chuột cũng không tới được.

Kiểm trên cửa sổ giả (không đụng cửa sổ game đang chạy của người dùng), sáu
ca đều về đúng 1920×1027 và nằm gọn trong màn hình: nhỏ ở giữa · sát mép phải
· sát mép dưới · lọt ra ngoài bên trái · **viền 14×14** · không viền. Ca viền
14×14 là ca quan trọng nhất — nó chứng minh viền được **đo**, không phải đoán.

---

## Đo được

| Việc | Thời gian |
|---|---|
| F3 lấy món (rê chuột → xong) | gần như tức thì |
| Trang tự dựng món sau khi ext bấm | ~1,8 s |
| Thêm một dòng affix qua danh sách | 150–283 ms |
| Tổng một lượt dán (4 dòng) | ~3,2 s |

### Toạ độ lưới — cái nào ĐO, cái nào SUY RA

Chỗ này phải ghi rõ, vì trộn hai loại vào nhau là tự lừa mình.

**Đo từ ảnh chụp thật** (cửa sổ mặc định 1920×1080, vùng vẽ 1920×1027 tại gốc
`(0, 23)`):

| Lưới | Số đo |
|---|---|
| Rương 5×10 | x 42 → 623, cách đều 58,1 · y 279 → 740, cách đều 92,2 |
| Túi đồ 3×11 | x từ 1301, ô rộng 52,4 · y từ 709, ô cao 77,0 |
| Dải tab, **6 tab** | tâm 185 244 303 362,5 421,5 480,5 · ô rộng 53 |
| Dải tab, **7 tab** | tâm 154,5 212,5 271 329,5 387,5 446,5 504,5 · ô rộng 53 |

Cả hai ảnh cùng gốc toạ độ — kiểm bằng mép trái lưới rương, cả hai đều nhảy
vọt đúng tại `x = 42`.

### Dải tab KHÔNG phải một dãy đều căn giữa

Đây là chỗ tôi đã đoán sai và nói chắc như đã đo. Có mỗi ảnh 6 tab, tôi dựng
công thức `tâm_i = 332,5 + 59,1 × (i − 1 − (n−1)/2)`, thấy khớp đẹp bản 6 tab
rồi đem suy ra bản 7 tab và ghi là "chuẩn". Đo nốt bản 7 tab thì hỏng giả
thiết: **cả bước nhảy lẫn tâm dải đều đổi theo số tab.**

| | bước nhảy | tâm dải |
|---|---|---|
| 6 tab | 59,10 | 332,75 |
| 7 tab | **58,33** | **329,43** |

Công thức cũ cho 7 tab ra `155 214 273 332 392 451 510`, đo thật là
`155 213 271 330 388 447 505` — lệch dồn tới **5 px** ở tab ngoài cùng. Ô tab
rộng 53 px nên chưa đến mức bấm hụt, nhưng đủ để thấy con trỏ không vào giữa ô.

Nên bỏ công thức, **thay bằng hai bảng số đo** `TAB_X6` / `TAB_X7`. Muốn thêm
trường hợp khác thì đo thêm một bảng, đừng nội suy.

Bài học chung: một phép đo khớp với một công thức **không** chứng minh công
thức đúng — nó chỉ chưa bác bỏ. Hai tham số tự do thì một dãy 6 điểm khớp
được là chuyện đương nhiên.

Ô tab rộng 53 px, sai quá ~26 px là bấm ra ngoài panel, mà bấm ra ngoài panel
trong Diablo 4 nghĩa là **nhân vật chạy đi**. Nên hộp thoại F2 vẫn giữ nút
**Rê thử tab** (rê qua từng tâm tab, không bấm) và ô **Lệch ngang** lưu vào
`quet.ini` — phòng khi máy khác, cỡ cửa sổ khác.

Công thức của D4LF cho dải tab thì **sai hẳn** — họ giãn 63 px, đo thật là
58–59. Tab ở hai đầu lệch tới 12–13 px.

---

## Kết luận về đường "đẩy một phát" — ngõ cụt, đã dừng

Đo thật ngày 23/09/2026, 5 lượt dán trong 16 phút, 5 món khác nhau. Form mà
tiện ích với tới được **luôn luôn** chứa đúng bốn chỉ số:

```
Willpower · Maximum Life · Critical Strike Damage Multiplier · Cooldown Reduction
```

Không đổi lần nào, dù món đang dựng là gì. Đó là một form đã chết, và **nó là
form duy nhất tồn tại trong cây React** — lưới vét quét cả cây cũng không tìm
ra cái thứ hai. `số ứng viên bộ quản lý mảng: 0` ở mọi lượt.

**Kết luận:** form đang sống của chế độ BETA không phơi ra `getValues` /
`setValue`, nên `replace()` / `append()` / `reset()` đều không với tới được.
Toàn bộ bộ máy "ghi thẳng vào form" là di sản của chế độ CLASSIC.

Đã **thôi đuổi theo**. Đường đang dùng — mở danh sách `ADD STANDARD AFFIXES`
một lần rồi thêm từng dòng — chạy ổn định ở **160–300 ms mỗi dòng**.

### Bẫy 20 — form chết vẫn lọt vì trùng tên

Phép đối chiếu cũ chỉ đòi *"mọi dòng đang hiện đều có trong form"*. Form chết
giữ 4 mục, màn hình 1 dòng, tình cờ trùng một tên (`Critical Strike Damage
Multiplier` — món nào chẳng có) là **lọt**. Ext ghi vào đó rồi ngồi chờ
2 × 450 ms vô ích.
→ Đòi thêm: **số dòng phải bằng nhau**. (Sửa ở 7.1.)

## Còn bỏ ngỏ

- Ổ ngọc: chỉ đếm được **ổ trống**. Ổ đã nhét ngọc thì game in tác dụng của
  viên ngọc, không in chữ `Empty Socket`.
- Đồ **Magic / Common**: mã dùng chung đường với Rare nên chạy được, nhưng
  chưa đi thử — người dùng không bán hai loại này.
- Mã **CLASSIC** còn nguyên trong tiện ích. Xoá được sau khi diablo.trade bỏ
  chế độ đó.
