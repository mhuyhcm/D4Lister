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
| Đặt giá | gõ tay trên web | **ô nhập ngay trong game**, gõ số rồi Enter |

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

**Đặt giá ngay trong game.** Lấy món xong (F3), một **form** hiện ra:
bấm chuột vào một mức giá là xong. Giá ghi thẳng vào file của món thành dòng
`#D4L-GIA:`, rồi tiện ích điền vào ô Price giúp — ô đó nhận `50b` nguyên
dạng, không phải `50000000000`.

**Ô nhập giá.** Bấm F3 lấy món xong, một ô hiện ra: gõ số rồi Enter là xong,
`Esc` bỏ qua. Gõ `300` thì lưu ra `300b` — ô chỉ hiện con số, chữ `b` không
hiện. Đổi đơn vị trong `quet.ini` mục `[gia] donvi`. Ô kéo được, lần sau mở
lại đúng chỗ đã kéo tới.

**Ô này không giành bàn phím, mà BẮT THẲNG PHÍM SỐ.** Lý do ở bẫy 53:
Diablo chỉ vẽ tooltip của món khi cửa sổ game đang hoạt động, nên ô nhập
giành bàn phím là tooltip tắt ngay — mà đó đúng là thứ cần nhìn để định giá.
Bắt phím thì game vẫn hoạt động suốt, người dùng vẫn gõ số rồi Enter y như
gõ vào ô bình thường. Đổi lại: lúc ô mở thì `0`-`9` bị nuốt, không lọt xuống
game (trong D4 đó là các ô kỹ năng) — đóng ô là trả lại ngay.

**Hai thứ đã bỏ hẳn (v4.4).** Người dùng yêu cầu:

* **Không còn đòi cửa sổ game phải đang hoạt động** mới vẽ dấu xanh. Bỏ
  luôn phép `WinActive`. Không vì thế mà dấu nổi đè lên màn hình lúc đang
  làm việc khác: `RuongDangMo()` vẫn đọc điểm ảnh chỗ mép rương, cửa sổ
  khác che mất là nó thấy ngay và cất dấu đi.
* **Không còn lời cảnh báo** *"N món liên tiếp không có khoảng [min - max]
  — bật Advanced Tooltip Information"*. Trước đây nó còn CHẶN luôn, không
  cho lấy tiếp; nay món vẫn lấy bình thường rồi hỏi giá như mọi món khác.
  Phần nhận biết vẫn chạy ngầm và vẫn quyết định có gửi `#D4L-SAO-OK` hay
  không — tức là nếu công tắc trong game bị tắt thật thì tiện ích để
  nguyên dấu sao thay vì đóng bừa, chỉ là không nói gì nữa.

**Đánh dấu món đã đặt giá.** Món nào đặt giá rồi thì có một ô vuông xanh ở
góc ô trong rương. **Rê chuột vào thì món đó hiện viền xanh kèm con số giá** —
làm theo kiểu D4LF: rê vào món nó nhận ra thì món được đóng khung màu, kèm
một nhãn chữ nhỏ (`Cosmetics`, `Codex Upgrade`). Khác một chỗ: D4LF đóng
khung quanh **tooltip**, muốn vậy phải đi dò xem tooltip đang vẽ ở đâu; ở đây
đóng khung quanh **ô**, mà toạ độ ô thì đã đo sẵn và tin được.

Cả ba lớp phủ (dấu xanh, viền, nhãn giá) đều `WS_EX_TRANSPARENT` +
`WS_EX_NOACTIVATE` — không ăn chuột, không giành tiêu điểm. Và đều bị **ẩn đi
trước khi F2/F10 quét**, vì chúng nằm đè lên rương mà hai lệnh đó đọc rương
bằng ảnh chụp màn hình.

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

*(74 cái; cái thứ 20 nằm ở mục "đẩy một phát" bên dưới)*

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

### 30. Nhìn ô bằng điểm ảnh — và ba lần sai trước khi đúng

Bài toán: TTS im lặng có hai nghĩa — **ô trống thật** hay **ô có đồ mà đọc
hụt**. Không phân biệt được thì sót món mà không ai hay. Người dùng gặp đúng
thế: tab có 30 món, F2 ghi nhận 29, mà F3 lấy tay thì đủ cả 30.

Cách giải: đọc điểm ảnh, vì mắt người nhìn vào rương là biết ngay ô nào có
đồ. Nhưng ba lần sai trước khi ra:

**Sai 1 — đo ĐỘ SÁNG.** Trên lưới rương thì tách sạch (ô trống ~10, ô có đồ
35–68). Đem sang lưới túi đồ thì hỏng: ba món ở hàng cuối chỉ được 47 / 18 /
10 %, tức hai món bị đọc thành ô trống. Lý do: **cái sáng lên không phải món
đồ mà là cái khung của nó**, mà khung chỉ sáng khi món được đánh dấu.

**Sai 2 — `PixelGetColor` quá chậm.** Đo trên máy này: **20 ms một lần đọc**.
Một lưới rương cần ~1750 điểm, tức **35 giây**. Phải chụp cả vùng vào bộ nhớ
bằng `CreateDIBSection` + `BitBlt` rồi đọc bằng `NumGet`: 1750 điểm còn **0
ms**, và 6/6 điểm đối chiếu khớp đúng `PixelGetColor`.

**Sai 3 — hằng số khai báo SAU `return` của phần tự chạy.** Ba dòng
`global O_LOI := 0.38` nằm ở dòng 1478, mà phần tự chạy kết thúc ở dòng 284
— **không bao giờ được gán**. Và đây là chỗ nó hiểm: trong AutoHotkey,

```ahk
5 >= ""     ; -> TRUE
```

nên `chênhSáng >= O_NGUONG` với `O_NGUONG` rỗng là **luôn đúng**, và mọi ô
đều thành "có đồ". Lỗi không nằm ở luật mà ở một dòng khai báo đặt sai chỗ,
còn triệu chứng thì trông y như luật sai hoàn toàn.

Cùng gốc với cái bẫy lúc ghép F2: **`global x := …` là một câu lệnh gán, nó
chỉ chạy khi luồng đi qua.** Giờ có phép kiểm tự động soát mọi
`global … :=` nằm sau `return` đầu tiên.

**Luật cuối cùng:** ô trống là một mảng **phẳng**, ô có đồ thì có **nét vẽ**.
Nên đo **chênh sáng** (sáng nhất − tối nhất) trong lõi 38% giữa ô, lấy mẫu
cách 9 px → 35 điểm.

| | chênh sáng |
|---|---|
| ô trống | 5 – 14 |
| ô có đồ | 77 – 229 |

Khe hở **5,5 lần**, ngưỡng 40 nằm giữa. Đo trên **166 ô thật** (2 ảnh × rương
+ túi đồ): **không sai ô nào**, ở mọi ngưỡng từ 25 đến 50.

Lấy rộng hơn 42% lõi là hỏng — chạm đường kẻ ô, mà đường kẻ cũng có chênh
sáng nên ô trống hoá ô có đồ.

Dùng để **đối chiếu**, không dùng để bỏ qua ô: nhìn thấy có đồ mà không đọc
ra chữ thì chỉ đúng tên ô — *"hàng 3 ô 6"* — chứ vẫn rê đủ mọi ô.

### 31. `return` giữa hàm nuốt mất việc ở cuối hàm

Thêm sơ đồ lưới vào báo cáo, thử tay thì thấy, mà người dùng chạy thật lại
**không thấy gì**.

Phần dựng sơ đồ nằm ở dòng cuối `QuetLuoi()`. Nhưng giữa hàm có sẵn ba chỗ
`return`:

```ahk
if (!g_DoLai || imLang.Length() = 0)
{
    …
    return          ← không bao giờ tới dòng cuối
}
```

Nên **tắt "dò lại ô im lặng" là mất sơ đồ**, bấm Esc giữa chừng cũng mất —
mà chẳng có dấu hiệu gì, vì cả hai vẫn là đường chạy bình thường.

Chữa: bỏ hết `return` giữa hàm, đổi thành `break` với một cờ, để **mọi
đường đều đi qua một chỗ ra**. Cái gì phải chạy ở cuối thì đừng để nó phụ
thuộc vào việc không có ai thoát sớm.

Bài học rộng hơn: **thêm một bước vào cuối một hàm đang có `return` giữa
chừng là tự đặt bẫy.** Trước khi thêm, đếm xem hàm đó có mấy lối ra.

Còn một lỗi lộ ra lúc chạy thử trọn chuỗi: lưới hỏng cả 23 ô thì câu
*"SÓT 23 ô: …"* kể tên hết, bảng báo cáo rộng **2042 px** — rộng hơn màn
hình. Giờ báo cáo chỉ kể 5 ô rồi "…", sổ ghi vẫn đủ.

### 32. Một hàm ở phạm vi toàn cục ăn mất biến đếm của vòng lặp

Sơ đồ lưới ghi *"Tab 1"* cho cả tab 2. Nhưng dòng cảnh báo ngay phía trên
lại ghi đúng *"Rương tab 3"*. Cùng một biến `i`, hai chỗ ra hai kết quả.

Khác nhau ở **thời điểm đọc**:

```ahk
soTab := i                                  ; đọc TRƯỚC khi quét  -> đúng
QuetLuoi(…, "Rương tab " . i, huy)
g_TK.chiTiet.Push({ten: "Tab " . i, …})     ; đọc SAU khi quét    -> hỏng
```

Thủ phạm là `NhanCau()` — hàm mở đầu bằng `global`, nên **mọi biến không
khai báo trong đó đều là biến toàn cục**. Nó có dòng

```ahk
i := g_Dem.Length() - A_Index + 1
```

và nó chạy **mỗi khi một câu TTS về**, tức liên tục suốt lượt quét. Vòng lặp
tab và nó dùng chung một biến `i` mà không ai biết.

Chữa hai lớp:

* khai báo `local` cho mọi biến làm việc của các hàm có `global` ở đầu;
* và vòng lặp tab dùng tên riêng `soTabNay`, không xài lại `i` — vòng đó gọi
  qua cả chục hàm, chỉ cần **một** hàm nào đó đụng vào là số tab hỏng.

Thêm một phép soát tự động: liệt kê mọi hàm có `global` ở đầu mà gán vào
biến không khai báo `local`. Lần chạy đầu ra **6 hàm**.

Lưu ý phân biệt: hàm **không** có dòng `global` thì AutoHotkey coi mọi biến
là cục bộ sẵn — `LocMonTTS`, `DonCau`, `LaTenMon`, `LaMocDung` đều thế, nên
chúng vô can dù cũng dùng `i`. Chỉ hàm có `global` mới nguy hiểm.

### 33. Lấy ít điểm mà sát tâm thì chịu lệch tốt hơn nhiều

Toạ độ lưới đo trên một máy, máy khác có thể lệch. Đo thử xem phép nhận ô
chịu được bao nhiêu px — và kết quả làm giật mình:

```
lấy rộng 0,34 ô (140 điểm)   chỉ chịu lệch  -1 .. +4 px
```

Quá sát. Nguyên nhân: lấy rộng thì chỉ cần lệch vài px là mẫu chạm **đường
kẻ ô**, mà đường kẻ cũng sáng — ô trống hoá ô có đồ.

Thử ngược lại, lấy **ít điểm hơn nhưng sát tâm**:

| cách lấy | điểm | ô trống / ô có đồ | chịu lệch ngang |
|---|---|---|---|
| rộng 0,34 ô | 140 | 0 / 29 | −1 … +4 px |
| ±16×16 px | 49 | 0 / 5 | −6 … +7 px |
| ±12×12 px | 25 | 0 / 2 | −10 … +13 px |

Chịu lệch tốt hơn hẳn, nhưng khe hở tụt — vùng nhỏ quá thì **món mảnh không
đi qua tâm ô**, đếm ra ít điểm lệch.

Nới khe hở lại bằng cách **hạ ngưỡng chênh sáng** từ 16 xuống 12, và lấy
vùng vừa phải:

```
±18×20 px, bước 5  →  72 điểm
ô trống ≤ 1 điểm lệch   ·   ô có đồ ≥ 35 điểm lệch
chịu lệch −10 … +10 px cả hai chiều
```

**Ít điểm hơn một nửa, khe hở rộng hơn, chịu lệch gấp ba.**

Bài học: với loại phép đo này, **lấy nhiều mẫu hơn không phải lúc nào cũng
chắc hơn**. Lấy rộng ra là rước thêm thứ không thuộc về ô. Phải quét cả hai
tham số — cỡ vùng lấy mẫu VÀ ngưỡng — chứ chỉnh một cái thì thấy đánh đổi mà
tưởng là giới hạn.

Kiểm trên 166 ô thật, có cố tình làm lệch: **0 sai ở cả 0, ±8 px hai chiều.**

### 34. Phép đo vị trí lưới tự tin sai — và vì sao cần hai lớp chắn

Bật "bỏ qua ô trống" thì đoán sai một ô là **mất món, im lặng**. Nên trước
khi bỏ qua, đo lại vị trí lưới tại chỗ; lệch quá 6 px thì thà rê đủ.

Thử bằng cách cố tình đưa vào gốc sai:

```
lệch  0 px  ->  đo ra  0 px   cho bỏ qua        đúng
lệch  4 px  ->  đo ra  4 px   cho bỏ qua        đúng
lệch 10 px  ->  đo ra 10 px   từ chối bỏ qua    đúng
lệch 20 px  ->  đo ra  3 px   CHO BỎ QUA        *** SAI ***
```

Vì cửa sổ quét chỉ ±16 px, lưới thật ở 20 px nằm **ngoài tầm**. Nó trả về
cái tốt nhất trong tầm — và con số "3 px" nghe còn yên tâm hơn cả sự thật.

**Một phép đo không tìm thấy thứ cần tìm vẫn trả về một con số.** Con số đó
không có nghĩa là "gần đúng", nó có nghĩa là "tôi không thấy gì cả".

Chữa hai lớp:

1. **Nới tầm quét lên ±26 px.** Đo lại: lệch 20 px giờ ra đúng 20.
2. **Rê thử 6 ô mà mình định bỏ qua**, rải đều khắp lưới. Ô nào lại ra món
   thì phép nhìn sai → bỏ luôn ý định bỏ qua, rê đủ mọi ô.

Lớp 2 **độc lập** với lớp 1: nó không tin phép đo vị trí, nó hỏi thẳng game.
Đã thử lại cả 5 mức lệch 0/4/10/20/30 px — đúng hết.

Giá của lớp 2 là 6 ô mỗi lưới, khoảng 1 giây. Rẻ so với việc mất một món mà
không ai biết.

### 35. Nửa file xuống dòng kiểu này, nửa kiểu kia — `m)^…$` không bám được

Ghi giá vào file món: đọc file lên, bỏ dòng giá cũ bằng
`RegExReplace(chu, "m)^#D4L-GIA:.*", "")`, nối dòng mới, ghi lại. Chạy thì
**dòng cũ không bị bỏ, dòng mới cứ chồng thêm**, mà đọc lại giá thì ra rỗng.
Cùng đoạn regex đó chép ra một file thử riêng lại khớp ngon lành.

Xem từng byte của file món mới thấy:

```
Ten mon 0d 0a  Affix 1 0d 0a  Affix 2 0a  #D4L-GIA:50b
                                       ^^ chỉ có 0a
```

`FileAppend` **không phải lúc nào cũng** đổi `` `n `` thành `` `r`n ``: mấy
dòng có sẵn trong chuỗi thì được đổi, dòng mình vừa nối thêm thì không. Mà
PCRE trong AutoHotkey mặc định **chỉ coi `\r\n` là hết dòng** — gặp một `\n`
trơ thì `^` không bám vào đó, `$` cũng không.

→ Đừng dựa vào kiểu xuống dòng. Dùng `\R` (khớp mọi kiểu) thay cho `^…$`:

```ahk
RegExReplace(chu, "(?:\R|^)#D4L-GIA:[^\r\n]*", "")
```

Và lúc nối thì ghi thẳng `` `r`n `` cho file đồng nhất.

### 36. `m1` của `RegExMatch` rỗng khi trong hàm có khai báo `local`

Sửa xong bẫy 35, regex khớp rồi (`RegExMatch` trả về vị trí 17) nhưng
`m1` **vẫn rỗng**:

```ahk
DocGiaTuFile(f)
{
    local noiDung, m                      ; <- chính dòng này
    ...
    if (RegExMatch(noiDung, "…#D4L-GIA:([^\r\n]*)", m))
        return Trim(m1)                   ; ra rỗng
}
```

Mấy hàm khác trong cùng file dùng `m1` vẫn chạy — khác ở chỗ chúng **không
khai báo `local` dòng nào**. `m1` là biến AutoHotkey tự dựng ra lúc chạy, mà
biến dựng động trong hàm không đi cùng đường với chữ `m1` viết trong nguồn:
một bên rơi ra toàn cục, một bên đọc cục bộ. Khớp mà vẫn rỗng, không báo lỗi.

→ Dùng dạng **`O)`** trả về đối tượng, khỏi phải biết luật:

```ahk
if (RegExMatch(noiDung, "O)…#D4L-GIA:([^\r\n]*)", m))
    return Trim(m.Value(1))
```

### 37. Bẫy 30 quay lại — nay đã có máy soát

`global GIA_CHO_MS := 8000` đặt ở đầu phần hỏi giá, mà phần đó nằm **sau**
cái `return` của khối tự chạy. Phép gán không bao giờ chạy; AutoHotkey vẫn
nhận cái tên, nên `GIA_CHO_MS` là chuỗi rỗng. `A_TickCount + ""` bằng
`A_TickCount`, vòng chờ thoát ngay lập tức — bảng giá hiện lên rồi tắt trong
một nhịp, không kịp bấm gì.

Lần này dính tiếp với `g_DauXanh := {}`: rỗng thì nó là **chuỗi**, gọi
`.Count()` lên chuỗi là giết luôn luồng, vẫn không một tiếng động.

→ `_he-thong\DONG-GOI.ps1` nay **từ chối đóng gói** nếu còn `global X := …`
nào nằm sau cái `return` đó. Bắt được cả hai lần trên.

### 38. Dấu vẽ đè lên game thì chính tool đọc nhầm nó

Ô vuông xanh đánh dấu món đã đặt giá nằm **đè lên rương**. Mà F2 và F10 đều
đọc rương bằng ảnh chụp màn hình — ô trống nào có dấu sẽ được đọc thành ô có
đồ. Hai chỗ phải chừa:

- **Lúc quét**: F2/F10 gọi `AnDauXanh()` ngay đầu, đồng hồ vẽ lại sau.
- **Chỗ dán dấu**: dán ở góc **trên phải** ô. Góc trái của cột 1 rơi vào
  x=47, đúng dải x=32…52 mà `RuongDangMo` đọc để biết rương có mở không.
  Góc phải cột 1 ở x=81, cách hẳn ra.

### 39. Lỗi *tải* của AutoHotkey không hiện hộp thoại khi chạy từ script

Bài thử lớp phủ chạy ra **file kết quả rỗng**, không một dòng nào — giống hệt
kiểu chết thầm lặng của bẫy 24/30, nên mất một lúc đi tìm nhầm chỗ. Thật ra
là lỗi cú pháp lúc tải:

```
thu-dau.ahk (331) : ==> Parameter #2 invalid.
     Specifically: ControlCount
```

(`WinGet` không có mục `ControlCount`; phải là `ControlList` rồi tự đếm.)

Chạy bằng `Start-Process` thì hộp thoại lỗi đó không thấy đâu cả. → Mọi lần
chạy thử phải kèm `/ErrorStdOut` và hứng `stderr` ra file. Rẻ, và nó phân
biệt ngay "chết lúc tải" với "chết lúc chạy".

### 40. Form đè lên game mà không cướp tiêu điểm

Bản đầu của phần đặt giá **bắt phím `1`–`5`** chứ không mở form, vì mở cửa sổ
là cửa sổ đó giành bàn phím, game mất tiêu điểm, **tooltip của món tắt ngay**
— đúng lúc người bán đang nhìn chỉ số để định giá.

Người dùng bác: *"bấm số không hợp lý, form có ô nhập và có các số chỉ cần
click vào luôn"*. Tưởng phải chọn một trong hai, hoá ra không:

```ahk
Gui, hGia:New, ... +E0x08000000     ; WS_EX_NOACTIVATE
Gui, hGia:Show, NoActivate x… y…
```

Cửa sổ `WS_EX_NOACTIVATE` **vẫn nhận chuột như thường** — bấm nút vẫn chạy
nhãn `g` — nhưng bấm vào nó không làm nó thành cửa sổ hoạt động. Game giữ
nguyên tiêu điểm, tooltip còn nguyên.

Chỉ **ô gõ chữ** là không xong: phím gõ sẽ rơi xuống game. Nên ô đó chỉ giành
bàn phím khi người dùng chủ động bấm nút `Giá khác…` (`WinActivate` +
`GuiControl Focus`). Nút ấy đặt `+Default`, nên gõ xong nhấn Enter là chính
nó chạy lần hai và lấy chữ trong ô ra — khỏi thêm nút ẩn.

Hai thứ phải nhớ kèm:

- **Một phím Esc, hai việc.** AutoHotkey chỉ giữ **một** nhãn cho mỗi phím:
  đăng ký `~Esc` lần nữa với nhãn khác là đè mất nhãn cũ, tắt cái này thì tắt
  luôn cái kia. Gộp về một nhãn rồi rẽ nhánh bên trong.
- **Kéo form** khi không có thanh tiêu đề: bắt `WM_LBUTTONDOWN`
  rồi `PostMessage 0xA1, 2` — bảo Windows coi như vừa bấm vào thanh
  tiêu đề. Nút và ô nhập tự nuốt cú bấm của chúng nên chỉ kéo được ở
  chỗ trống.
- **Form không tự tắt** nên F3 phải chặn: `if (g_Busy || g_DangHoiGia)
  return`, không thì bấm nhầm F3 là xếp chồng form, món nào ra món nào không
  lần ra.

Bài thử bấm nút bằng `ControlClick` sau khi dò `ControlGetText` theo dòng chữ
trên nút. Một lần chệch ở chính bài thử: `ControlSetText` bỏ trống tham số
control thì nó **không** nhắm vào ô nhập, kết quả trả về chuỗi rác — phải ghi
rõ `Edit1`.

### 41. Bài thử giành bàn phím thì nó hứng luôn phím người dùng đang gõ

Bài thử phần "gõ giá tay" báo sai ba lần liền, mỗi lần một kiểu:

```
SAI 7. go tay tra ve [fffffffffffffffffffffffffff500b]
SAI 7. go tay tra ve [ffff777b]
SAI 7. go tay tra ve [f777b]
```

Số ký tự thừa **giảm dần theo đúng độ hẹp của khoảng thời gian** mà bài thử
để hở giữa lúc đặt chữ vào ô và lúc bấm nút đọc ra. Chạy lại lúc không ai
đụng bàn phím thì `OK`.

Tức là: đúng đoạn ấy bài thử gọi `WinActivate` để ô nhập nhận được phím — mà
ô nhập nhận được phím thì nó nhận **mọi** phím, kể cả phím người dùng đang gõ
ở cửa sổ khác. Mã sản phẩm không sai chỗ nào.

Hai bài học:

- Bài thử nào có `WinActivate` thì nó không còn chạy nền được nữa; kết quả
  chỉ đáng tin khi bàn phím đang rảnh. Ghi rõ ra, đừng ngồi sửa mã.
- Một chỗ sai mà số liệu **đổi theo mỗi lần chạy** thì gần như chắc chắn là
  môi trường, không phải mã. Sai do mã thì sai giống hệt nhau.

Còn một chỗ chệch nữa của chính bài thử: máy đang thử **không chạy Diablo**,
mà `TheoDoiReGia` mở đầu bằng `KiemCuaSoGame` nên thoát ngay — phần vẽ viền
không bao giờ chạy, mà bài thử lại báo "OK" vì đem hai số rỗng ra so với
nhau. Phải gọi thẳng `HienGiaRe()` và đòi `vwR > 0` mới đếm là đạt.

### 42. Đổi cách bấm làm hỏng một tính năng khác, ở chỗ không ai ngờ

Đặt giá xong thì món phải được đánh dấu xanh trong rương. Chạy thử đủ kiểu
đều đạt, người dùng đem vào game thì **không món nào được đánh dấu**, và
cũng chẳng có lấy một câu báo lỗi.

Lý do nằm ở một dòng tưởng vô hại:

```ahk
DanhDauMon()            ; hỏi "con trỏ đang ở ô nào?" NGAY LÚC NÀY
```

Hồi còn bắt phím `1`–`5` thì đúng: người dùng vẫn đang rê chuột trên món,
bấm phím xong con trỏ chưa nhúc nhích. Đổi sang **form bấm chuột** thì con
trỏ đã đi xuống đáy màn để bấm nút — hỏi ra thì nó chẳng nằm trong ô nào,
hàm lặng lẽ trả về `false`.

→ Chốt cái ô **ngay lúc bấm F3** (`GhiNhoODangRe()`), lúc con trỏ chắc chắn
còn trên món. Lúc lưu giá chỉ việc dùng lại cái đã chốt.

Bài học rộng hơn: đổi **cách người dùng thao tác** thì phải đi soát lại mọi
chỗ đang ngầm dựa vào thao tác cũ. Ở đây cái ngầm định là "con trỏ vẫn đứng
yên trên món" — không viết ra ở đâu cả, nên không ai nghĩ tới nó.

Và: hỏng mà im lặng thì mất gấp đôi thời gian. Nay câu báo nói thẳng
*"không đánh dấu được ô — lúc bấm F3 con trỏ không nằm trong ô nào"*.

### 43. Tooltip của món che mất dải tab

Muốn biết dấu xanh thuộc tab nào thì phải đọc xem rương đang mở tab mấy, mà
phép đọc ấy soi vệt sáng trên dải tab. Rắc rối: lúc bấm F3 thì game **đang
vẽ tooltip của món**, và cái tooltip ấy cao gần hết màn hình — nó phủ lên
chính chỗ cần soi. Đọc lúc đó là đọc phải chữ của tooltip.

→ Chỉ đọc dải tab **khi con trỏ nằm ngoài lưới rương**, rồi nhớ lại
(`g_TabCuoi`). Không lỡ lần nào cả: muốn đổi tab thì phải bấm vào dải tab,
mà lúc bấm thì con trỏ đang ở ngoài lưới — đúng lúc phép đọc chạy.

Kèm theo: hai cái đồng hồ đó phải chạy **từ lúc khởi động**, không phải đợi
tới khi có món đầu tiên được đánh dấu. Số tab phải có SẴN vào đúng lúc bấm
F3, chứ lúc ấy mới đi đọc thì đã muộn.

### 44. Cửa sổ không giành tiêu điểm thì ô gõ chữ cũng không gõ được

Người dùng báo: *"tôi thêm nó không nhận và không add thêm"*. Nút `＋` bấm
xong chẳng thêm mức nào.

Hoá ra nút không sai: **ô gõ luôn rỗng**. Form đặt ở chế độ `NoActivate` +
`WS_EX_NOACTIVATE` để game khỏi mất tiêu điểm — mà đúng cái cờ đó khiến bấm
vào ô gõ thì Windows **không đưa cửa sổ lên trước**. Ô có nhận tiêu điểm
trong nội bộ cửa sổ cũng vô ích: phím gõ đi theo cửa sổ đang hoạt động, tức
là rơi thẳng xuống game. Người dùng gõ "30b", màn hình chẳng hiện gì, bấm
`＋` thì ô vẫn rỗng.

Ba chỗ phải gỡ, và hai chỗ đầu **đều im lặng**:

1. Bắt cú bấm vào ô. `OnMessage(0x201)` chỉ nghe tiếng bấm rơi vào **nền**
   form, bấm trúng control con thì không thấy gì. Phải nghe
   **`WM_PARENTNOTIFY` (0x210)** — control con bị bấm thì cha nhận được.
2. Gỡ cờ `WS_EX_NOACTIVATE` trước khi gọi `WinActivate`, còn cờ thì Windows
   từ chối. Mà **cả hai đường của AutoHotkey đều không ăn**:
   `WinSet, ExStyle, -0x08000000` và `Gui, hGia:-E0x08000000` — đọc lại
   `ExStyle` vẫn nguyên `0x08000088`, không lỗi, không cảnh báo. Phải gọi
   thẳng `SetWindowLongPtr(hwnd, -20, ex & ~0x08000000)`.
3. `ControlGetPos` **không nhận tên biến của control GUI** — chỉ nhận ClassNN
   hoặc chữ trên control. Đưa `GiaChuNhap` vào thì nó trả về rỗng, phép kiểm
   "cú bấm có rơi vào ô không" thành sai, hàm thoát sớm. Phải dùng
   `GuiControlGet, p, hGia:Pos, GiaChuNhap`.

Cùng một cái bẫy số 3 dính **hai lần trong một giờ**: một lần trong mã sản
phẩm, một lần trong chính bài thử — và lần ở bài thử làm tôi tưởng mã sản
phẩm còn hỏng sau khi đã sửa xong.

Đo lại sau khi sửa: `ExStyle 0x08000088 → 0x00000088`, cửa sổ hoạt động đổi
sang form, `ControlGetFocus` trả về `Edit1`.

### 45. Bài thử dài ra thì phải nới thời gian chờ, không thì đọc nhầm thành lỗi

Thêm mấy phép thử mới, bộ thử chạy quá 38 giây mà lệnh chạy vẫn giết tiến
trình ở giây 38. Kết quả: file chỉ có nửa đầu, không có dòng `--- het ---`.
Tôi đi tìm "hộp thoại lỗi đang chặn" mất một lúc, kiểm cả tiêu đề cửa sổ của
tiến trình, trong khi chuyện chỉ là **chưa chạy xong**.

→ Dòng `--- het ---` ở cuối mỗi bộ thử chính là để phân biệt "chạy xong mà
sai" với "chưa chạy xong". Không thấy nó thì nới giờ trước, đừng đi chẩn
đoán.

### 46. Clipboard được đặt TRƯỚC khi hỏi giá, nên nó thiếu mất dòng giá

Người dùng báo tiện ích không tự điền giá. Hàm điền giá bên tiện ích thì
đúng — thử tách riêng, bảy trường hợp đều đạt. Vấn đề ở phía trước nó: **chữ
trong clipboard không có dòng `#D4L-GIA`**.

Trình tự của F3:

```
1. đọc món từ đường ống
2. ghi ra file
3. DatClipboard(chu)      <-- clipboard chốt Ở ĐÂY
4. hỏi giá
5. LuuGiaVaoFile(...)     <-- dòng giá chỉ vào FILE
```

Dán bằng **F4** thì không sao, F4 đọc lại từ file. Nhưng dán bằng **Ctrl+V**
là dán bản đã chốt ở bước 3 — không có giá.

→ Sau bước 5 gọi thêm `DatClipboardTuFile(...)` để clipboard khớp lại với
file. Cả nhánh đặt giá lần đầu lẫn nhánh đặt lại giá.

Đây là **bẫy 42 lặp lại y hệt ở một chỗ khác**: xen một bước mới (hỏi giá)
vào giữa một trình tự cũ thì mọi thứ đã chốt TRƯỚC bước đó đều thành cũ.
Lần trước là vị trí con trỏ, lần này là clipboard.

Và lại một lần hỏng im lặng. Nay bảng kết quả của tiện ích có hẳn một dòng
nói giá vào được hay không: *"giá 500b đã điền"* / *"có giá 500b nhưng KHÔNG
điền được"* / *"giá: chưa đặt trong game"*.

### 47. Chèn đoạn mới vào nhầm hàm — cú pháp sạch, bài thử sạch, vẫn hỏng

Người dùng gửi ảnh Console: `Uncaught ReferenceError: text is not defined`.

Đoạn điền giá tôi chèn vào hàm **vẽ bảng kết quả** chứ không phải `apDung` —
mà hàm vẽ bảng không có tham số nào tên `text`. Nó ném lỗi ngay dòng đầu,
tức là phần điền giá **chưa chạy được lần nào**.

Vì sao lọt qua hết mọi lớp kiểm:

- `node --check` **sạch**: đúng cú pháp, chỉ sai lúc chạy.
- Bài thử của tôi **sạch**: tôi lấy hàm `dienGiaTuChu` ra thử riêng, bảy
  trường hợp đều đạt. Hàm đúng thật — chỗ GỌI nó mới sai.
- Trang **vẫn chạy**: lỗi ném ở cuối, sau khi bảng kết quả đã vẽ xong, nên
  nhìn vào màn hình không thấy gì bất thường.

Tôi còn đi sửa một nguyên nhân khác (clipboard, bẫy 46) trước khi thấy cái
này — sửa ấy vẫn đúng, nhưng không phải cái đang chặn.

**Thử viết một bộ soát "biến chưa khai báo" và đã bỏ đi.** Nó không bắt được
lỗi này: `text` CÓ tồn tại trong file (là tham số của `apDung`), sai là sai
**phạm vi**. Một bộ soát không hiểu phạm vi thì chỉ tạo cảm giác an toàn.

Thay bằng phép thử hẹp mà đúng việc: lấy hàm đang CHỨA lời gọi, rồi đòi biến
truyền vào phải là tham số của chính nó, hoặc biến ở mức mô-đun. Đã chạy thử
ngược trên bản còn lỗi để chắc nó bắt được — 3 chỗ báo sai.

Một chi tiết của chính phép thử: lần đầu viết, phép kiểm "biến này có khai
báo trong hàm không" bị **chính dòng đang gọi** đánh lừa —
`const daDatGia = dienGiaTuChu(text)` khớp với mẫu `const … text`. Phép thử
tự ru ngủ nó. Phải đòi tên đứng ngay sau `let/const/var` hoặc sau dấu phẩy.

Bài học: thử một hàm riêng ra thì chỉ chứng minh **hàm** đúng. Chỗ gọi nó là
một chuyện khác, và đó mới là chỗ tôi vừa sửa.

### 48. Một affix bình thường bị nhận nhầm thành Aspect — vì danh sách class

Người dùng báo tiện ích chọn Aspect sai. Không đoán nữa: trong `queue\` có
**10 món thật đã chụp**, mở ra xem là thấy ngay.

`queue\001.txt` — một đôi găng **RARE**, loại không bao giờ có Aspect:

```
SMASH GAMBIT
Rare Gloves
…
#D4L-UNIQUE:15.0|10.0|15.0
#D4L-ASPECT:+15.0% Fortify Generation [10.0 - 15.0]% (Druid Barbarian Rogue
            Necromancer Paladin Warlock Only)
```

Luật nhặt câu Aspect là *"dòng dài quá 12 từ trong khối chỉ số"*. Đếm cả
phần trong ngoặc thì một affix tầm thường kèm danh sách class dài cũng
thành 13 từ. Tiện ích nhận được câu đó, đem đi dò danh mục Aspect rồi chọn
đại một cái gần nhất.

Hai lớp chắn, độc lập nhau:

- **Đếm từ SAU khi bỏ ngoặc tròn.** Ngoặc là giới hạn class và phần so với
  đồ đang mặc, không phải nội dung câu. Bốn Aspect thật trong hàng đợi vẫn
  qua được (14–22 từ), affix kia rớt còn 6 từ.
- **Chỉ đồ Legendary / Unique / Mythic mới có sức mạnh riêng.** Rare, Magic,
  Common thì không bao giờ — đọc thẳng dòng loại đồ.

Bỏ ngoặc còn được thêm một việc: câu gửi đi khớp sát hơn với mô tả trong
danh mục của trang, vốn không có phần class.

Kèm theo, phần chọn Aspect trước nay **thiếu phép kiểm nhập nhằng** mà phần
chọn affix đã có từ lâu (`kq.nhi >= DIEM_CHAC`). Với câu dài thì thiếu cái
đó rất nguy: `diemKhop` đếm theo TỈ LỆ từ khớp được, nên hai Aspect chỉ khác
đúng một từ — "increased Cold damage" so với "increased Fire damage" — vẫn
được 24/25 = 96%, qua ngưỡng 95% và được chọn *như thể chắc chắn*. Nay đòi
khoảng cách với á quân phải bằng ít nhất **một từ**; sát hơn thế thì dừng
lại, báo tên cả hai để người dùng tự chọn.

**Chỗ tìm dữ liệu thật.** Mất công đoán một lúc rồi mới nhớ ra `queue\` có
sẵn mười món đã chụp. Lần sau gặp "tiện ích đọc sai", mở `queue\*.txt`
trước — đó chính xác là thứ tiện ích nhận được.

### 49. Bài thử cắt chuỗi lệch một ký tự, tám ca đều "đạt" giả

`SubStr(dong, 1, 13) = "#D4L-ASPECT:"` — chuỗi đó dài **12**. Phép so không
bao giờ đúng, nên `asT` luôn rỗng. Bốn ca kỳ vọng "không có aspect" liền
báo OK vì hai bên cùng rỗng; bốn ca còn lại báo SAI và suýt nữa thì tôi đi
sửa mã sản phẩm đang đúng.

Dấu hiệu nhận ra: **các ca kỳ vọng "rỗng" thì đạt, các ca kỳ vọng có giá trị
thì trượt sạch.** Hình dạng đó gần như luôn là phép trích của bài thử hỏng,
không phải mã sản phẩm. Trùng ý với bẫy 45: phép thử so hai giá trị rỗng
với nhau thì lúc nào cũng "đạt".

### 50. Đồ Unique trùng tên khác loại — chọn theo tên không thôi là vơ nhầm

Người dùng gửi ảnh form: món **SCOUNDREL'S LEATHERS — Ancestral Unique Chest
Armor**, mà trang dựng ra lại là **Charm · Unique · Scoundrel's Leathers**.
Toàn bộ affix, Unique Power, giá đều đúng — chỉ mỗi loại đồ sai, và sai thì
cả cái listing vô nghĩa.

Đường đi của đồ Unique khác hẳn đồ thường: tên đồ Unique có trong danh mục
nên tiện ích **gõ thẳng tên** vào ô Add item rồi chọn trong danh sách gợi ý.
Chọn bằng `timKhopNhat(tenMon, ds, tenGoiY)` — tức **chỉ chấm theo TÊN**.

Danh sách gợi ý có thể có nhiều mục TRÙNG TÊN mà khác loại đồ. Hai mục cùng
tên thì điểm BẰNG NHAU, `timKhopNhat` giữ cái gặp trước (`r > dTot` nên cái
sau không thắng được) — lấy cái nào là tuỳ thứ tự trang trả về.

Mà loại đồ thì **đã biết chắc từ đầu**: nó nằm ngay trong dòng
"Ancestral Unique Chest Armor" mà `tachDongLoai` đã tách sẵn ra `Chest
Armor`. Chỉ là chưa ai đem nó ra dùng ở bước này.

→ Lọc danh sách gợi ý theo loại đồ trước khi chấm tên. Lọc trên cả
`data-value` lẫn chữ trong thẻ, đòi khớp MỌI từ của tên loại ("Two-Handed
Mace" phải đủ ba từ). Lọc xong không còn mục nào thì trả lại danh sách cũ —
trang viết tên loại khác đi thì thôi, còn hơn không chọn được gì.

Bài học lặp lại từ bẫy 48: **dữ liệu đã có sẵn trong tay mà không dùng.**
Lần đó là dòng loại đồ để biết Rare không có Aspect; lần này cũng là dòng
loại đồ, để biết nên lấy gợi ý nào.

Và lại thêm một chỗ hỏng im lặng: chọn nhầm xong mọi bước sau vẫn chạy trơn
tru. Nay nhật ký ghi rõ "Loại đồ X: n gợi ý, còn m sau khi lọc" và "Chọn gợi
ý: <cả chữ của thẻ>" — nhìn là biết nó lấy đúng thẻ nào.

### 51. Ba bản form, và cái đúng là cái ít nhất

Phần đặt giá đi qua ba bản trong một buổi:

1. **Bắt phím `1`–`5`.** Chọn vậy để game khỏi mất tiêu điểm — mở cửa sổ là
   tooltip của món tắt, mà đó đúng thứ đang cần nhìn. Người dùng bác: *"bấm
   số không hợp lý"*.
2. **Form nhiều nút:** năm nút mức giá sẵn, `＋` thêm mức, `−` bớt mức, ô
   chọn đơn vị, chuột phải để xoá. Người dùng bác tiếp: *"bỏ hết các tính
   năng khác, + − click các kiểu đi"*.
3. **Một ô nhập.** Gõ số, Enter, xong.

Bản 3 giải quyết luôn cái lo của bản 1 mà không cần cửa sổ không-giành-tiêu-
điểm: **con trỏ nằm sẵn trong ô ngay khi form mở**, nên chuột không phải
nhúc nhích khỏi món. Mất tiêu điểm hay không hoá ra không phải vấn đề —
**rê chuột** mới là vấn đề, vì tooltip tắt khi chuột rời món.

Tôi đã mất hai vòng vì bảo vệ nhầm thứ. Cái cần giữ là **vị trí con trỏ
chuột**, không phải tiêu điểm bàn phím.

Mã bỏ đi: `DocMucGia`, `ThemMucGia`, `XoaMucGia`, `LuuMucGia`, bốn nhãn nút,
ô chọn đơn vị, và bốn hằng số. Giữ lại đúng phần có giá trị: gõ `200` hiểu
là `200b`.

### 52. Bài thử gửi phím thật thì hỏng khi có người dùng máy

Bộ thử form gửi `ControlSend {Enter}` và đọc ra `f200`, `f500m` — chữ `f`
là phím người dùng đang gõ ở cửa sổ khác rơi vào ô thử, vì form giành bàn
phím. Bốn phép báo sai oan, trong khi mã sản phẩm không sao.

→ Bấm thẳng nút mặc định (`ControlClick Button1`) thay cho gửi phím. Còn
"Enter có tới được nút hay không" thì kiểm riêng bằng cờ `BS_DEFPUSHBUTTON`
của nút — chắc hơn mà không nhiễu gì.

Thêm một cái lợi bất ngờ: bộ thử chạy từ hơn **100 giây xuống 7 giây**, vì
không còn phải chờ các mốc thời gian rộng rãi cho phím thật kịp tới.

Trùng ý với bẫy 41 và 45: bài thử nào đụng tới bàn phím/tiêu điểm thật thì
kết quả chỉ đáng tin khi máy đang rảnh — mà tốt nhất là đừng đụng tới.

### 53. Tooltip của món tắt khi game thôi là cửa sổ hoạt động

Người dùng: *"khi tôi target vào game thì item mới hiển thị chỉ số, nhưng
khi F3 thì target lại qua form nên mất hiển thị"*.

Đây là mắt xích cuối cùng của một chuỗi hiểu sai kéo dài bốn bản form. Sự
thật đơn giản: **Diablo chỉ vẽ tooltip của món khi CỬA SỔ GAME đang hoạt
động.** Không phải "khi chuột còn trên món" như tôi tưởng ở bẫy 51.

Nên hai điều kiện phải giữ CÙNG LÚC:

- chuột không rời ô chứa món (nếu không game bỏ trạng thái rê)
- game vẫn là cửa sổ hoạt động (nếu không game thôi vẽ tooltip)

Bản v4.1 giữ điều kiện hai nhưng bắt rê chuột xuống ô. Bản v4.2 giữ điều
kiện một nhưng giành bàn phím. Mỗi bản gỡ được một nửa rồi làm hỏng nửa kia.

Giữ được cả hai bằng cách **không dùng tiêu điểm bàn phím chút nào**: ô nhập
để `ReadOnly`, còn chữ vào ô bằng đường **bắt phím** — `0`-`9`, dấu chấm,
`BackSpace`, `Enter`, `Escape` đăng ký thành hotkey, nuốt luôn không cho lọt
xuống game (trong D4 phím số là ô kỹ năng). Người dùng vẫn gõ số rồi Enter y
như gõ vào ô bình thường, mà cửa sổ hoạt động vẫn là game từ đầu đến cuối.

Hai chỗ phải cẩn thận:

- **Tắt cho bằng hết** lúc đóng ô. Sót một phím số là trong game bấm kỹ năng
  đó không ăn nữa, mà lỗi kiểu ấy rất khó lần ra nguyên nhân.
- **Esc dùng chung** với báo cáo F2: ô giá bắt `Escape` (nuốt), báo cáo bắt
  `~Esc` (cho lọt xuống game). AutoHotkey chỉ giữ MỘT nhãn cho mỗi phím, nên
  có hẳn một phép thử: dùng ô giá xong thì Esc phải vẫn đóng được báo cáo.

Bài học: tôi đã đoán cơ chế của game hai lần và sai cả hai. Đáng lẽ phải hỏi
"chính xác thì khi nào game vẽ tooltip?" ngay từ đầu — người dùng biết câu
trả lời, và họ đã nói ra ở ngay câu đầu tiên của tin nhắn này.

### 54. Hai món trùng tên trùng cả mô tả — chỉ khác mã

Bẫy 50 sửa chuyện chọn nhầm loại đồ bằng cách lọc gợi ý theo tên loại. Sửa
xong vẫn sai. Lần này không đoán nữa: cho tiện ích **ghi ra hết mọi gợi ý**
rồi đọc nhật ký thật của người dùng.

```
Gợi ý cho "INFERNAL HOMUNCULUS" (2):
   [0] unique:9ecbda01-fdf8-4df4-8edf-8febdf0d0e3b Infernal HomunculusYour
       Archfiend Skills deal {80%}[x] increased damage…Unique
   [1] unique:dd399910-787d-41bf-a0dc-2a2529d84021 Infernal HomunculusYour
       Archfiend Skills deal {80%}[x] increased damage…Unique
Loại đồ "Focus": còn 2 sau khi lọc
```

Hai thẻ **giống nhau từng ký tự** — tên như nhau, mô tả như nhau, đều ghi
"Unique". Khác mỗi cái mã. Thẻ **không hề ghi loại đồ**, nên lọc theo chữ
trên thẻ là việc vô ích ngay từ đầu; nó "lọc" xong vẫn còn hai, rơi vào
nhánh dự phòng và lấy cái đầu — đúng cái Charm.

Chỗ duy nhất còn phân biệt được là **cái mã**. Tra ngược mã đó vào danh mục
của trang (`.attributes`, 1450 mục) thì ra bản ghi đầy đủ của món.

Không biết trang đặt tên trường loại đồ là gì — `itemType`? `slot`?
`baseType`? — nên **không soi một trường cụ thể**: đổi cả bản ghi thành
chuỗi JSON rồi tìm tên loại đồ trong đó. Tên trường là gì cũng chạy, và bài
thử có hẳn một ca `slot.base` để chốt chuyện đó.

Còn nếu vẫn không tách được — danh mục không có mã ấy chẳng hạn — thì **giữ
cả hai và nói ra**: một dòng đỏ trong bảng kết quả *"2 mục trùng tên, không
tách được theo loại đồ Focus — kiểm lại loại đồ trên form giúp"*. Thà bảo
người dùng liếc một cái còn hơn im lặng dựng nhầm.

Một chi tiết nhỏ mà suýt nuốt mất cảnh báo đó: `loiThem` bị **xoá sạch** ở
đầu `themCacAffixThieu()`, mà hàm ấy chạy SAU chỗ chọn món. Nhét cảnh báo
vào `loiThem` là nó bay mất trước khi bảng kết quả kịp vẽ. Phải để riêng
một biến.

**Cách làm đã đổi hẳn.** Ba lần trước tôi đoán hình dạng DOM của trang rồi
viết mã theo phỏng đoán, sai cả ba. Lần này viết mã để **lấy dữ liệu thật
ra trước**, đọc, rồi mới sửa. Nhanh hơn hẳn — và câu trả lời (hai mã UUID)
là thứ không đời nào đoán ra được.

### 55. Nhật ký: lưu ra file, chép đường dẫn

Nút "Chép nhật ký" trước đây nhét cả xấp chữ vào clipboard, người dùng phải
dán mấy chục dòng vào khung chat. Nay tải hẳn ra file trong thư mục Tải
xuống, clipboard chỉ giữ đường dẫn `%USERPROFILE%\Downloads\d4lister-<giờ>.txt`
— gửi một dòng là xong, mà nhật ký dài bao nhiêu cũng không sao.

Trang web không được phép biết thư mục Tải xuống nằm đâu, nên đường dẫn
ghép bằng `%USERPROFILE%`. Đúng trên Windows trừ khi người dùng tự dời thư
mục Tải xuống đi chỗ khác.

### 56. "AI fix bug" — để tiện ích tự gom hồ sơ gỡ lỗi

Ba lần liền tôi đoán cấu trúc DOM của diablo.trade rồi viết mã theo phỏng
đoán, sai cả ba (bẫy 50, 54, và lần tra mã UUID hụt). Lần nào cũng tốn một
vòng qua lại với người dùng chỉ để biết một sự thật nhỏ.

Người dùng đề nghị đảo ngược cách làm: thêm một công tắc trong tab Advanced
— **AI fix bug** — bật lên thì mỗi món dán vào, tiện ích tự chụp cấu trúc
trang ở các bước hiểm, gom cùng nhật ký vào một file rồi tải về. Chạy xong
cả loạt thì đưa tên file, đọc file là dò được.

Bốn chỗ chụp, chọn theo đúng chỗ đã từng hỏng:

| bước | vì sao |
|---|---|
| `vua-dan-chu` | trạng thái gốc, trước khi tiện ích đụng vào |
| `danh-sach-goi-y` | **đang mở** danh sách chọn món — chỗ nhầm Focus thành Charm |
| `them-affix-hong-<tên>` | đang xổ danh sách affix mà không khớp dòng nào |
| `sau-khi-dien` | kết quả cuối |

Mấy quyết định đáng ghi:

- **MỘT file, không phải mỗi bước một file.** Chrome chặn tải hàng loạt:
  tải liên tiếp vài cái là nó hỏi *"cho phép tải nhiều file?"*, mỗi món hỏi
  một lần thì không ai dùng nổi.
- **Cắt trước khi gom**: bỏ `script`/`style`/`svg`/`canvas`, cắt ngắn ảnh
  nhúng `data:`. Giữ nguyên thẻ và thuộc tính — đó mới là thứ cần đọc. Ảnh
  thường `src` **không** cắt: đường ảnh hay chứa tên loại đồ, đúng thứ đang
  đi tìm.
- **Hẹn lưu chứ không lưu ngay.** Một món vẽ bảng kết quả vài lần (thêm
  affix xong thì điền lại), đợi lắng 2,5 giây rồi mới lưu để hồ sơ có đủ cả
  lượt sau.
- Chụp ở chỗ **danh sách đang mở**. Đóng rồi thì không còn gì để xem — đây
  là lý do ba lần trước không có dữ liệu.

Mặc định TẮT. File khá nặng, chỉ bật lúc đang săn lỗi.

### 57. Chép nhật ký: đừng đoán thư mục tải về

Bản 8.1 chép sẵn `%USERPROFILE%\Downloads\<tên file>` vào clipboard. Sai:
máy người dùng đặt Chrome tải thẳng vào thư mục dự án, nên đường dẫn đó trỏ
vào chỗ không có gì. Trang web không có cách nào biết thư mục tải về nằm
đâu.

→ Chỉ chép **tên file**. Đi tìm bằng tên thì một lệnh là ra, còn đường dẫn
bịa ra thì dẫn người ta đi sai chỗ.

### 58. Hai thẻ giống nhau từng byte — câu trả lời nằm ở tooltip

Hồ sơ "AI fix bug" đầu tiên (`d4l-hoso-20260925-122343`) chấm dứt chuyện
đoán. Moi hai thẻ gợi ý ra, bỏ `srcset` cho dễ đọc, đặt cạnh nhau:

```
data-value="unique:9ecbda01-…"   …/game/d4/items/2674666.webp
data-value="unique:dd399910-…"   …/game/d4/items/2548638.webp
```

Ngoài hai chỗ đó ra, **giống nhau từng byte**: cùng class, cùng
`alt="Infernal Homunculus"`, cùng mô tả, cùng cái nhãn `Unique` ở cuối.
Trong thẻ **không có một chữ nào** về loại đồ. Ba vòng vừa rồi tôi đi tìm
thứ không tồn tại.

Nhưng có cái này, trước đó không ai để ý:

```
data-slot="tooltip-trigger" data-state="closed"
```

Thẻ có tooltip. Rê chuột vào thì trang xổ ra tooltip đầy đủ của món — mà
tooltip món thì CÓ dòng loại đồ, đúng dạng "Ancestral Unique Focus".

→ Rê vào từng thẻ (`pointerover`/`mouseenter`), chờ Radix mở tooltip, đọc
dòng loại đồ, rồi rê ra (`pointerout`/`mouseleave`). Thẻ nào khớp loại đồ
game nói thì chọn thẻ đó.

Tooltip không xổ ra thì trả về rỗng — **không đoán** — và lui về cách lọc
theo chữ như cũ, kèm cảnh báo.

**Bài học lớn hơn cả cái lỗi.** Ba vòng trước tôi đọc mã, suy ra hình dạng
DOM, viết mã theo suy luận đó. Sai cả ba, mỗi lần tốn một vòng qua lại.
Vòng này viết mã để **lấy dữ liệu thật về trước**, rồi đọc, rồi mới sửa —
và câu trả lời (`tooltip-trigger`) là thứ không đời nào suy ra được.

Ý tưởng "AI fix bug" là của người dùng. Đáng lẽ tôi phải tự nghĩ ra từ vòng
thứ hai.

### 59. Sự kiện chuột giả không đánh thức được tooltip của Radix

Bẫy 58 đoán rằng rê chuột vào thẻ gợi ý sẽ xổ ra tooltip có dòng loại đồ.
Viết xong, chạy, đọc hồ sơ lượt sau:

```
[0] tooltip nói loại đồ: (không đọc được)
[1] tooltip nói loại đồ: (không đọc được)
```

Ảnh chụp ngay lúc đó (`2t-tooltip-goi-y-0`) nói rõ hơn: trong 51.678 ký tự
**không có lấy một** `tooltip-content`, `role="tooltip"`, `radix-popper`,
hay `data-state="open"`. Tooltip chưa từng mở. Bắn `pointerover` /
`mouseenter` bằng `dispatchEvent` không đủ đánh thức Radix.

**Bỏ đường đoán, đi đường đo.** Trang đã tự nói ra loại đồ nó dựng — ô xem
trước ghi hẳn "Ancestral Unique Charm", và tiện ích đã đọc được từ bẫy 53.
Vậy thì đừng cố biết trước, cứ **dựng thử rồi kiểm**:

1. bấm thẻ thứ nhất, chờ trang dựng món
2. đọc loại đồ trang vừa dựng ra
3. khớp chữ của game → xong
4. không khớp → bấm **Reset**, gõ lại tên, chọn thẻ còn lại (nhớ mã thẻ đã
   thử qua `data-value`), nhiều nhất hai lượt

Nút Reset tìm theo CHỮ trên nút, không bám class: class của trang này do
Tailwind sinh ra, đổi xoành xoạch.

Phép dò tooltip giữ lại làm đường ưu tiên — rẻ, và nếu sau này trang đổi
cách dựng thì đỡ phải dựng thử hai lượt. Nhưng không còn trông vào nó nữa.

**Bài học:** "đoán ra cách biết trước" thua "làm rồi kiểm lại". Ba vòng tôi
đi tìm cách nhìn thẻ mà biết loại đồ; trong khi thứ cần thiết — trang tự
khai loại đồ sau khi dựng — đã nằm sẵn trong tay từ bẫy 53.

### 60. Dựng thử một lần rồi nhớ lấy — khỏi dựng thử mãi

Cách "dựng thử rồi kiểm" (bẫy 59) chạy đúng, nhưng **mỗi lần dán lại tốn
một lượt Reset**: tiện ích quên sạch sau mỗi món, hai thẻ trùng tên thì lần
nào cũng phải đoán lại từ đầu.

Mà dựng đúng MỘT LẦN là biết mã nào đúng. Nhớ lại là xong:

```
localStorage['d4lister-ma-mon-1']
  { "infernal homunculus|focus": "unique:dd399910-787d-41bf-a0dc-2a2529d84021" }
```

Nhớ theo cặp **tên món + loại đồ**, không phải chỉ tên: cùng một tên vẫn có
thể có nhiều loại, đó chính là gốc của cả chuyện này.

Nhớ nhầm cũng không sao — trang đổi danh mục theo mùa chẳng hạn. Lượt sau
vẫn **kiểm loại đồ như thường**: sai thì bỏ mã đó, Reset, thử thẻ khác, rồi
ghi đè lại mã đúng. Bộ nhớ chỉ là đường tắt, không phải nguồn tin cậy.

Đo trên bài thử: lần đầu 1 lượt Reset, lần sau **0 lượt**; mã nhớ sai thì
tự sửa trong 1 lượt và ghi đè lại đúng.

### 61. Phím tắt chỉ nên ăn ở đúng cửa sổ của nó

Mọi phím tắt trước nay đều toàn máy: đang gõ chữ ở đâu đó mà lỡ chạm F3 là
tool tưởng bạn lấy món, F4 là nó dán nhầm vào chỗ khác.

Chia lại theo đúng nơi phím ấy có nghĩa:

| phím | chỉ ăn ở |
|---|---|
| F2 F3 F10 | game — chúng rê chuột, chụp màn hình, đọc tooltip của game |
| F4 F5 F6 | trình duyệt — chúng dán vào trang |
| F9 | game hoặc trình duyệt |
| Ctrl+Shift+F11/F12 | ở đâu cũng được — tổ hợp ba phím, không chạm nhầm |

Làm bằng `GroupAdd` rồi `Hotkey, IfWinActive, ahk_group <nhóm>`. Nhóm trình
duyệt gom sẵn tám exe (chrome, edge, firefox, brave, opera, vivaldi, zen,
arc).

**Cái bẫy nằm ở dòng cuối.** `Hotkey, IfWinActive` đặt điều kiện cho MỌI
lệnh `Hotkey` gọi về sau, chứ không riêng mấy dòng ngay dưới nó. Quên bỏ
điều kiện đi thì `~Esc` của báo cáo và bộ phím của ô nhập giá — đăng ký lúc
chạy, tận đâu đó trong hàm — cũng dính điều kiện còn treo lại, bật/tắt không
đúng cái mình tưởng.

Nên sau khối phím có điều kiện phải có một dòng `Hotkey, IfWinActive` trơ
trọi để xoá điều kiện. Bài thử có hẳn một ca **chứng minh chiều ngược lại**:
đăng ký một phím dưới điều kiện A rồi đổi sang điều kiện B mà tắt, thì tắt
không được — đúng như lo.

Bài thử dùng **F13–F15**, những phím bàn phím thật không có. Kiểm được cách
đăng ký mà không cướp phím nào của người đang dùng máy (xem bẫy 41, 52).

### 62. Danh mục của trang KHÔNG có món ở loại đồ đúng — sửa thẳng loại đồ

`Moloch's Beating Flame` trong game là **Amulet**. Gõ tên ra đúng 2 mục, và
tooltip (nay đã đọc được) nói cả hai đều là **Charm**:

```
[0] tooltip nói loại đồ: Ancestral Unique Charm
[1] tooltip nói loại đồ: Ancestral Unique Charm
```

Đếm trong ảnh chụp: đúng 2 thẻ, không bị cắt bớt. Trang **không có** bản
Amulet để mà chọn — chọn thẻ nào cũng ra Charm. Đây là dữ liệu của trang
sai, không phải chỗ nào trong tool sai.

Lối ra nằm ở dòng "Item" trên form: nó là **ba cái nút bấm được** —
`<loại đồ> · <độ hiếm> · <tên món>`. Bấm nút loại đồ thì trang mở lại lưới
chọn base (Amulet / Axe / Boots / Bow / Charm…). Chọn Amulet ở đó là xong.

Đo trên hồ sơ thật: `sửa loại đồ sang "Amulet": được`, và phép tự kiểm cuối
cùng `game: Amulet · trang: Amulet`. **Đổi được loại đồ của một món Unique
mà không mất món.**

Thứ tự bây giờ, từ rẻ tới đắt:

1. mã đã nhớ → vào thẳng
2. tooltip nói thẳng loại đồ → chọn đúng mục
3. tooltip nói KHÔNG mục nào đúng loại → khỏi dựng thử, nhảy luôn xuống (5)
4. không đọc được gì → dựng thử, sai thì bấm tên món mở lại, thử mục kia
5. vẫn sai → **đổi thẳng loại đồ trên form**
6. vẫn sai → báo đỏ, chặn tự đăng

### 63. Điền giá xong phải so từng ký tự, không chỉ "có chữ số"

Phép kiểm sau khi điền giá chỉ hỏi *ô Price có chữ số không*. Trang cắt bớt
giá — gõ `1200b` mà nó giữ `999b` chẳng hạn — thì phép kiểm ấy **vẫn báo
thành công**, và món lên sàn với giá khác hẳn giá mình đặt, không ai biết.

Nay đòi khớp từng ký tự. Lệch thì báo đỏ *"GIÁ BỊ ĐỔI: đặt 1200b mà ô Price
giữ 999b"* và **chặn tự đăng**.

Chưa rõ trang có thật sự chặn ở 999 hay không — ô Price trong DOM không có
`maxlength` nào (mấy ô affix thì có: `maxlength="5"`). Nhưng phép kiểm lỏng
kia là lỗ hổng thật dù mức chặn nằm ở đâu.

### 64. Tắt Advanced Tooltip Information là hỏng ba thứ cùng lúc

Người dùng báo ba lỗi tưởng rời nhau: đóng dấu ✻ lên cả bốn dòng trong khi
game chỉ có hai; cây kiếm kẹt ở bước chọn Aspect; đồ Unique không đóng dấu
đúng chỗ. Và kèm một nghi ngờ: *"tôi đang nghi việc TTS hoặc AutoHotkey đọc
thiếu dữ liệu"*.

Nghi ngờ đó **đúng**. So chính một món, chụp cách nhau vài tiếng:

| lúc 12:23 | lúc 14:00 |
|---|---|
| `+122 Weapon Damage [86 - 143]` | `**+122 Weapon Damage` |
| `x16% Critical Strike Damage Multiplier [13 - 25]%` | `**x16% Critical Strike Damage Multiplier` |
| `#D4L-UNIQUE:83\|80\|110` | `#D4L-UNIQUE:83` |

Toàn bộ khoảng `[min - max]` biến mất — **Advanced Tooltip Information bị
tắt**. Một nguyên nhân, ba triệu chứng:

* **Dấu ✻ sai.** Luật nhận Greater Affix là "dòng nào KHÔNG in khoảng". Không
  dòng nào có khoảng nữa → mọi dòng thành Greater.
* **Aspect kẹt.** Đường ống gộp hai dòng làm một:
  `"…no longer attack faster.. Current Bonus: 0.00%"`. Cái đuôi thừa kéo
  điểm khớp xuống 88%, dưới ngưỡng, món không dựng được.
* **Mất khoảng của Unique Power** nên không biết có kịch trần hay không.

Ba chỗ sửa:

1. **Cắt đuôi giao diện** khỏi câu Aspect: `Current Bonus`, `Requires
   Level`, `Sell Value`, `Durability`, `Tempers`, `Unique Equipped`,
   `Lord of Hatred`. Kèm dọn `..` thành `.`.
2. **Chặn ngay ở món ĐẦU TIÊN**, không đợi đủ ba món liên tiếp. Trước đây
   đếm tới ba mới ngưng phát cờ `#D4L-SAO-OK` — nên đúng món đầu đã lên sàn
   với bốn dấu sao sai. Nay xét trên chính món đó: mọi dòng có số mà không
   dòng nào có khoảng → không phát cờ.
3. **Nói ra thay vì im.** Tiện ích hiện một dòng vàng: *"Dấu sao để nguyên —
   game không in khoảng [min - max]… Bật Options > Gameplay > Advanced
   Tooltip Information"*.

Điểm 3 đáng nhắc riêng: **cảnh báo cũ trong game đã bị gỡ theo yêu cầu người
dùng (bẫy ở mục V4.4), và đây đúng là cảnh nó sinh ra để bắt.** Gỡ xong thì
chuyện này lọt qua im lìm. Lần này chỗ báo đặt trên trang web — nơi người
bán đang nhìn — chứ không phải hộp thoại chặn giữa game.

### 65. Siết quá tay: món CẢ BỐN dòng đều Greater thật

Bẫy 64 chặn dấu sao ngay ở món đầu tiên có "mọi dòng đều không khoảng". Sửa
xong nửa ngày thì dính ngược: **ARCHON GAUNTLETS OF FORTUNE ✻✻✻✻** — cả bốn
affix đều là Greater thật, mà Greater thì không in khoảng. Luật mới bỏ sạch
dấu sao của nó.

Đúng cái giá tôi đã ghi ra lúc sửa bẫy 64 ("món nào mà mọi dòng đều Greater
thật thì cũng mất dấu sao... chuyện đó hiếm"). Hiếm thật, nhưng hiếm cỡ nửa
ngày.

**Chỗ phân biệt nằm ở câu Aspect.** Câu Aspect KHÔNG bao giờ là Greater
Affix, nên công tắc bật thì nó LUÔN in khoảng:

```
công tắc BẬT:  "You gain 18.5%[x] [15.0 - 20.0]% Lucky Hit Chance…"
công tắc TẮT:  "Your Summons gain 43% Attack Speed."
```

→ Câu Aspect còn khoảng `[số - số]` = công tắc đang bật = mấy dòng không
khoảng kia là Greater **thật**. Không còn khoảng ở đâu cả = không biết gì,
giữ hướng an toàn.

Thử lại trên cả năm món thật đã chụp: hai món lúc công tắc tắt vẫn bị chặn
đúng, món Archon phát cờ và đóng đủ bốn dấu sao, hai món cũ lúc công tắc bật
vẫn nguyên.

**Đọc thẳng setting của game thì sao?** Người dùng hỏi, và đó là câu hỏi
đúng. Đã tìm: `Documents\Diablo IV\LocalPrefs.txt` — 190 dòng, **chỉ có đồ
hoạ, hiển thị, âm thanh**. Mục Gameplay (trong đó có Advanced Tooltip
Information) Blizzard giữ ở tài khoản trên máy chủ, không nằm trên đĩa.

Hoá ra lại may: dấu hiệu lấy từ chính chữ nhận được **đúng hơn** đọc file
cấu hình. File nói cái công tắc ĐANG đặt thế nào; câu Aspect nói chữ mình
VỪA NHẬN có khoảng hay không — mới là thứ thật sự quyết định đọc đúng hay
sai.

### 66. Gom hồ sơ vào một file = mất đúng lượt cần xem

Bản đầu của "AI fix bug" gom mọi bước vào **một** file rồi mới tải, vì thẻ
`<a download>` tải liên tiếp thì Chrome hỏi *"cho phép tải nhiều file?"*.

Đổi lại: hồ sơ chỉ ra đời khi lượt chạy **tới được chỗ lưu**. Lượt nào kẹt
cứng giữa chừng — đúng lượt cần xem nhất — không để lại gì cả. Mấy lần gỡ
lỗi món Charm/Focus đều phải chờ lượt nào tình cờ chạy hết mới có file đọc.

Sửa: ghi **ngay từng bước**, mỗi lượt một thư mục đặt tên theo giờ:

```
Tải xuống/d4l-hoso/20260925-153012-infernal-homunculus/
    01-vua-dan-chu.html   …   17-sau-bam-submit.html   00-nhat-ky.txt
```

Muốn vậy phải qua **`chrome.downloads`**, vì hai lẽ: thẻ `<a download>` bỏ
dấu gạch chéo trong tên nên **không tạo được thư mục con**, và nó mới là cái
làm Chrome hỏi — `chrome.downloads` không hỏi.

Mà `d4lister.js` chạy ở `world: "MAIN"` (phải vậy mới với tới React của
trang) — ở đó **không có `chrome.*` nào cả**. Nên thành ba mảnh:
`d4lister.js` (MAIN) → `cau-noi.js` (ISOLATED, có `chrome.*`) → `nen.js`
(service worker, gọi `chrome.downloads`). Cầu nối câm quá 4 giây thì lui về
`<a download>` như cũ — bản tiện ích cũ còn sót lại vẫn chạy được, chỉ là
file nằm rải.

Hai chỗ dễ vấp trong `nen.js`:
- `String.fromCharCode(...mang)` vỡ ngăn xếp với ảnh chụp DOM hàng trăm
  nghìn byte → phải đổi base64 theo **từng khúc 0x8000**.
- `onMessage` phải `return true` thì `traLoi` bất đồng bộ mới tới nơi.

Nhật ký ghi **sau cùng** vào cùng thư mục. Chỗ này lại vấp thêm một cái —
xem bẫy 67.

### 67. "Im lặng 2,5 giây" không có nghĩa là lượt đã xong

Nhật ký hẹn ghi sau 2,5 giây không có bước mới. Lượt thử đầu tiên
(`20260925-150634-scoundrels-leathers`) đẻ ra **hai** cuốn:

```
15:06:35  bước 07 — sửa loại đồ xong
          ← 3 giây trống: đang ĐỢI trang dựng form, không có gì để chụp
15:06:38  hẹn nổ  ->  00-nhat-ky.txt    (cụt, 7 bước)
15:06:38  bước 08, 09  ->  00-nhat-ky-2.txt  (9 bước)
```

Giữa lượt có quãng trống **dài hơn** hẹn giờ. Kéo hẹn giờ dài ra chỉ là đoán
xem quãng nào dài nhất — trang chậm hơn là vấp lại.

→ Hỏi thẳng cờ đang chạy, đủ **năm** việc dài hơi: `dongHo` (đợi form),
`dangTaoItem`, `dangChonBase`, `dangThemAffix`, `dongHoDang` (đếm ngược tự
đăng). Phần thêm affix trước đó không có cờ nào, phải thêm.

Kèm **hạn 60 giây**: lượt kẹt cứng thì cờ không bao giờ hạ, mà hồ sơ của
lượt kẹt mới đúng là hồ sơ cần đọc — quá hạn là ghi, đừng đợi nữa.

### 68. Chặn trần thì phải chặn cả cái dấu chấm cụt

Ô giá F3 chặn trần 999: gõ thêm mà vượt thì bỏ cú gõ. Luật viết một dòng
`QuaTranGia(chữ đang có . ký tự mới)` — nhìn thì kín, nhưng:

```
gõ 9 9 9 .    ->    "999."     (999.0 = 999, không vượt -> lọt)
rồi gõ 5      ->    "999."     (999.5 vượt -> chặn)
```

Ô đứng ở `999.` — dấu chấm **không bao giờ** gõ tiếp được, mà ghép đơn vị
thì ra `999.b`. Bài thử bắt đúng cái này, người ngồi thử tay khó ra: phải
gõ dấu chấm **đúng lúc đang ở sát trần** mới thấy.

→ Nhận dấu chấm chỉ khi đằng sau còn nhét nổi một con số:
`QuaTranGia(chữ đang có . ".1") = false`.

Ngoài ra `QuaTranGia` phải đắp chuỗi cho thành số trước khi so (`"."` →
`"0."`, `"12."` → `"12.0"`). So thẳng thì AHK đem so theo bảng chữ cái, và
`"1000" < "999"`.

### 69. Hai luật loại trừ nhau để hở một cái khe, dòng rơi vào là mất hẳn

**DOOM CUISSES OF ACCURSED TOUCH** (Legendary Pants) sang tới trang thì báo
*"chưa tự chọn được Aspect — D4Lister không gửi kèm mô tả Aspect"*. Mở
`queue\001.txt` ra xem: đúng là **không có** dòng `#D4L-ASPECT:`.

Hai luật, mỗi luật đúng phần mình, mà ghép lại thì hở:

| luật | nói gì về câu Aspect của món này |
|---|---|
| `LaCauRieng` — bỏ mọi dòng mở đầu `Lucky Hit` | "không phải Aspect" |
| `DonChiSo` — bỏ mọi dòng dài quá 12 từ | "không phải affix" |

Aspect *of Accursed Touch* mở đầu bằng `Lucky Hit:` **và** dài. Không ai
nhận, và vòng lặp **không hề có nhánh nào giữ lại dòng bị cả hai chối** —
nó biến mất, im lặng.

Luật `^lucky hit` có lý do của nó: trang có 28 affix thật mở đầu như vậy
(`Lucky Hit: Chance to Stun for 2 Seconds`…). Bỏ luật đó thì affix hoá
Aspect. Nên cách chữa **không** đụng vào luật, mà vá cái khe:

> Món Legendary/Unique nào cũng có đúng MỘT sức mạnh riêng. Hết vòng lặp mà
> chưa nhặt được câu nào, trong khi có một câu **dài** bị bỏ — thì câu đó
> chính là nó.

Không cần biết câu ấy mở đầu bằng chữ gì, nên nó đỡ cho cả những Aspect mở
đầu kiểu khác mà sau này mới gặp. `DonChiSo` giờ trả thêm *vì sao* bỏ
(`ngan` / `unlocks` / `dai`) để lưới an toàn chỉ đỡ đúng loại `dai`.

Hai chỗ vá kèm:
- Đếm từ phải **bỏ khoảng `[min - max]`** (kể cả dấu `%` dính đuôi nó).
  Khoảng chỉ hiện khi Advanced Tooltip Information bật và ngốn ba "từ" —
  không trừ thì cùng một dòng affix lúc bật công tắc dài hơn lúc tắt ba từ,
  đủ để nhảy qua mốc 12 và bị bỏ. Tức là công tắc lại đổi cách đọc, y như
  bẫy 64.
- `LaCauRieng` phải chối cả `^unlocks`. `Unlocks new Aspect in the Codex of
  Power and look on salvage` mở đầu bằng chữ cái nên lọt vào, và món nào
  không đọc ra Aspect thật thì nó chiếm luôn chỗ.

**Lấy câu dài CUỐI CÙNG, không phải câu đầu.** Bật `[quet] ttslog=1` rồi
đọc `queue\_tts.log` thì thấy tooltip xếp thế này:

```
DOOM CUISSES OF ACCURSED TOUCH
Ancestral Legendary Pants
900 Item Power
2,004 Armor (+298.5% Toughness)
+151 Willpower
+22 Life on Kill +[18 - 22]
+5 Wrath Regeneration
12.5% Impairment Reduction
Lucky Hit: Up to a 37.0% [30.0 - 40.0]% chance for your Skills to inflict
  Vampiric Curse on enemies. …            <- Aspect, sau HẾT mọi affix
Requires Level 70. Lord of Hatred Item    <- vòng lặp dừng ở đây
```

Câu Aspect **luôn đứng sau** các affix, và vòng lặp dừng ngay dòng kế tiếp.
Nên nếu một affix `Lucky Hit` dài cũng rơi vào lưới (mấy cái dài nhất trong
danh mục 643 tên có thể quá 12 từ), câu Aspect đứng sau vẫn giành lại được
chỗ. Mốc 12 từ vì thế không còn phải gánh việc phân biệt nữa — thứ tự gánh.

Bài thử chạy trên đúng chữ thô đó, thêm một ca đặt affix `Lucky Hit` dài
ngay trước câu Aspect để canh chừng.

**Vấp thêm lúc thử:** bài thử chép tay vòng lặp của `DungChuMon` (mấy hàm
khác bứng thẳng từ file được, riêng vòng lặp nằm lọt giữa một hàm to). Sửa
file thật xong chạy lại thì bài thử báo SAI trong khi mã đã đúng — bản chép
chưa đổi. Nay `gen_khe.py` đòi mấy dòng cốt lõi phải còn y nguyên trong
nguồn, lệch một chữ là dừng hẳn, bắt sửa bản chép trước. Cùng họ với bẫy 1:
**chép tay thì phải có cái gì đó canh cho khỏi lệch.**

### 70. Đuôi "Skills" là tuỳ trang đặt, không phải luật

**TEARVEIL AMULET OF FRENZIED ONSLAUGHT** có dòng `+4 to Dust Devil Skills`.
Trang gọi affix đó là **`Dust Devil`** — trơn, không đuôi. Lệch đúng một từ,
mà phép chấm điểm tính theo từ:

```
"Dust Devil Skills"  vs  "Dust Devil"   ->  2/3 = 67%   ->  hụt ngưỡng
```

Dòng đó không thêm được, và món đứng lại.

Không cắt đuôi `Skills` cho tất cả được: **73 tên** trong danh mục của trang
CÓ đuôi đó thật (`Core Skills`, `Blood Skills`, `Corpse Skills`…). Cắt sạch
thì `Core` đụng `Corpse` ngay.

→ Chỉ cắt khi **một bên có đuôi mà bên kia không**. Hai bên cùng có thì để
nguyên. Đo trên cả **640 tên** của trang: cắt kiểu này **không làm cặp nào
đụng nhau** (0 cặp khớp 100% với nhau), nên an toàn.

Không phải ca lẻ — cả một họ để trơn như vậy: `Dust Devil`, `Golem`,
`Hydra`, `Arrow Storm`, `Lightning Storm`. Sau khi sửa, cả năm đều khớp
100%, á quân 33%.


**Bài thử lại tự làm mình sai:** lần đầu tôi truyền nguyên dòng game
(`"+4 to Dust Devil Skills"`) vào bộ chấm điểm, và *mọi* phép thử đều SAI,
kể cả `"Core Skills"` khớp với chính nó. Vì `tenThuan` chỉ cắt chữ `to` khi
nó **đứng đầu chuỗi**, mà đường thật đã cắt con số ở đầu từ trước
(`Willpower`, không phải `+151 Willpower`). Bài thử phải nhận đúng thứ hàm
kia thật sự nhận — sai một bước là mười hai dòng SAI đổ oan cho mã đang
đúng.

### 71. Biết mình vừa đánh rơi món đồ, rồi vẫn đi tiếp

Người dùng có **13 món** trong túi, quét năm lượt ra năm con số:

| lượt | nhìn thấy | đọc được | sót |
|---|---|---|---|
| 1 | 13 | 10 | 3 |
| 2 | 13 | 13 | 0 |
| 3 | 13 | 13 | 0 |
| 4 | 13 | 10 | 3 |
| 5 | 13 | 12 | 1 |

Khâu **nhìn** (chụp ảnh ô) đúng 13/13 mọi lượt. Khâu **đọc** (TTS) mới rụng.

Và chương trình **đã biết**: `DoiChieuNhinVaDoc` đối chiếu ảnh với chữ, in
ra `!! SÓT 3 ô — nhìn thấy có đồ mà không đọc ra chữ` kèm đúng tên ô. Rồi
thôi. Nó **chỉ ghi sổ**, không làm gì cả. Cái tệ nhất không phải là đọc hụt
— mà là đã cầm bằng chứng trong tay rồi vẫn đi tiếp, im ru.

→ Thêm **lượt vét sót**: lấy đúng danh sách ô đó, hỏi lại, nới ngưỡng chờ
dần (gấp 3, gấp 6, gấp 9), dừng khi hết ô hoặc một lượt không cứu thêm được
gì. Chạy **bất kể công tắc "dò lại"** — công tắc đó để đánh đổi nhanh/chắc
khi còn NGỜ, còn đây là đã biết mình thiếu. (Máy người dùng đang để
`dolai=0`, tức lưới an toàn cũ cũng đang tắt.)

**Chữ thô thì sạch.** Bật `ttslog=1` rồi soi: 22/22 khối tooltip đều có mốc
kết thúc, không khối nào đứt giữa chừng; 6 món đọc nhiều lần đều ra y hệt
nhau. Tức khi tooltip về thì về nguyên vẹn — hỏng kiểu được ăn cả ngã về
không, chứ không phải đọc thiếu vài dòng. Nên cách chữa nằm ở **chờ và hỏi
lại**, không phải ở khâu tách chữ.

`_tts.log` nay ghi kèm mốc thời gian và đánh dấu ranh giới từng ô
(`===== RÊ TỚI (x,y) · chờ tối đa 160ms`, `===== IM LẶNG hết 160ms`). Bản
trước ghi trơ mỗi câu chữ, không đo được "rê xong bao lâu thì chữ về" —
đúng con số cần để chỉnh ngưỡng chờ.

### 72. "Số dòng tăng lên" không phải bằng chứng thêm đúng dòng

**PREPARED ASSAILANT'S EAGLE'S EYE** lên sàn với `Marksman Skills` **hai
lần** và mất hẳn `All Skills`. Nhật ký nói toẹt ra:

```
form đang có 4 dòng [+ Dexterity | Damage Over Time Multiplier % |
                     + Marksman Skills | + Marksman Skills]
```

Chỗ sai nằm ở phép kiểm "đã thêm được chưa", và cái ghi chú ngay trên nó
đã tự khai:

```js
// Neu sau khi bam ma so dong TANG len thi chac chan da them duoc,
// du ten co khop hay khong -> dung ngay.
xong = await cho(() => daCoDong(tenTim) || timCacDong().length > soDongTruoc, 1600);
```

Bấm hụt thì trang đẻ ra **bản sao của dòng vừa thêm trước đó**. Số dòng vẫn
tăng, mã reo "xong", `All Skills` chưa hề có. Không một lời báo — món lên
sàn với một chỉ số không tồn tại và thiếu một chỉ số có thật.

Cái vế "dù tên có khớp hay không" sinh ra để đỡ trường hợp trang đặt nhãn
dòng khác tên trong danh mục. Nhưng nó đổi một **thất bại nhìn thấy được**
lấy một **dữ liệu sai không ai biết** — đổi ngược.

→ Điều kiện xong chỉ còn `daCoDong(tenTim)`: đúng dòng mình cần mới tính.
Trang đặt nhãn khác thì báo hỏng, còn hơn im lặng ghi bừa.

→ Thêm **dọn dòng thừa**: hỏng thì đếm lại tên, tên nào giờ nhiều hơn lúc
trước thì phần dôi ra là bản sao, xoá từ dưới lên qua `button[aria-label^="Remove "]`.
Đọc lại danh sách sau mỗi lần xoá (xoá xong là DOM đổi). Affix cố định của
đồ Unique không có nút Remove — gặp thì dừng, không cố.

**Hồ sơ trắng đúng chỗ cần xem.** "AI fix bug" chỉ chụp danh sách gợi ý khi
THẤT BẠI, mà ca này lại "thành công" giả nên không chụp gì. Nay chụp
**trước mỗi cú bấm**, đủ cả lượt thành công.

Cùng gốc với bẫy 71: cả hai đều là *có bằng chứng trong tay rồi vẫn đi
tiếp*. Ở đó là ô đồ bị bỏ qua, ở đây là dòng affix ghi sai.

### 73. Bấm phải cái NÚT LỌC, tưởng là dòng gợi ý

Sửa bẫy 72 xong, `All Skills` vẫn không thêm được — nhưng lần này hỏng
**tử tế**: báo lỗi thật, dọn dòng thừa, và chụp lại đúng khung gợi ý. Mở
ảnh ra thì thấy ngay, trong khung lúc bấm chỉ có:

```
All | Offensive | Defensive | Resource | Utility | Mobility | +[1 - 3] Marksman Skills
```

Sáu cái đầu là **nút lọc phân loại** (`<button data-slot="toggle">`), không
phải gợi ý. Gợi ý thật chỉ có một dòng, và là dòng CŨ của lượt trước.

`dongGoiYBeta` quét `li, [role=option], label, button, div, span` — tức
quét cả hàng nút lọc. Và cái nút tên **`All`** đạt **100%** với affix
`All Skills`, vì phép cắt đuôi `Skills` ở bẫy 70 làm hai bên bằng nhau.
Tôi tự mở rộng chỗ sập này khi sửa bẫy 70.

Hậu quả xếp tầng:
1. bấm vào nút lọc thay vì dòng gợi ý;
2. tệ hơn — khớp được **ngay lập tức** nên nó thôi không đợi danh sách lọc
   lại, cứ nhìn mãi vào kết quả cũ;
3. đường dự phòng "gõ Enter ở ô tìm" chọn phải dòng đang sáng
   (`aria-selected="true"`) — chính là `Marksman Skills`.

→ Chỉ chấm điểm những thẻ **nằm trong một dòng gợi ý thật**:
`[cmdk-item], [role="option"], [data-slot="command-item"], li`. Nút lọc
không lọt vào nữa, và khi danh sách chưa kịp lọc thì không có ứng viên nào
— đúng ra là phải đợi.

**Bài học rộng hơn:** khung popover không chỉ chứa gợi ý. Đem cả khung ra
so tên là mời mọi thứ chữ nghĩa trong đó dự thi — tiêu đề, nút lọc, chú
thích. Phải neo vào thẻ mang đúng vai trò, đừng quét bừa rồi lọc bằng điểm.

Bài thử chạy trên **chính ảnh DOM chụp được lúc hỏng**
(`10-add-all-skills-truoc-bam.html`), nên không phải dựng lại bằng tay.

### 74. Số hiệu bản không xếp theo thứ tự chữ

Luật đánh số là `v4.1 → v4.2 → … → v4.9`, đầy thì `v4.1.1`. Đúng luật,
nhưng mở thư mục phát hành ra thì:

```
D4Lister-v4.1.2.zip   <- MỚI NHẤT (tiện ích 9.5), nằm ĐẦU
D4Lister-v4.1.zip
D4Lister-v4.2.zip
D4Lister-v4.3.zip
D4Lister-v4.4.zip     <- cũ nhất trong nhóm (tiện ích 7.9), nằm CUỐI
```

`v4.1.2` đứng **trước** `v4.2` theo thứ tự chữ. Ai quen lấy file dưới cùng
là cầm phải bản cách đó chín đời tiện ích — và sẽ ngồi gỡ lại đúng những
lỗi vừa sửa xong.

Gói thì không sai: băm SHA-256 từng file trong zip khớp y nguồn. Sai ở chỗ
**cái tên không nói được cái nào mới**.

→ `DONG-GOI.ps1` nay đẻ thêm `D4Lister-MOI-NHAT.zip` (bản sao tên cố định)
và `MOI-NHAT.txt` ghi rõ bản nào, đóng lúc nào. Đóng xong nó còn liệt kê
những zip **nằm dưới** bản vừa đóng mà lại cũ hơn, để khỏi cầm nhầm.

Đổi luật đánh số thì gọn hơn, nhưng đó là luật người dùng đặt — nên chữa ở
chỗ cái tên, không đụng vào luật.


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
