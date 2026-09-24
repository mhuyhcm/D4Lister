# D4Lister v3 — nhật ký và các bẫy đã gỡ

Ngày chốt: **23/09/2026**
AutoHotkey `D4Lister.ahk` **v3** · tiện ích Chrome `d4lister.js` **7.1**

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

---

## Đo được

| Việc | Thời gian |
|---|---|
| F3 lấy món (rê chuột → xong) | gần như tức thì |
| Trang tự dựng món sau khi ext bấm | ~1,8 s |
| Thêm một dòng affix qua danh sách | 150–283 ms |
| Tổng một lượt dán (4 dòng) | ~3,2 s |

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
