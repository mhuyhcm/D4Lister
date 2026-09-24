# D4Lister — những gì cần đưa vào

Tổng hợp ngày **24/09/2026**, sau khi chạy thử **D4LF v10.0.5** và đọc mã
nguồn của họ. Hiện chốt ở **v3** (AHK v3 + tiện ích 7.1).

Đọc kèm:
- `NHAT-KY-V3.md` — 21 cái bẫy đã gỡ của v3
- `_bo-nho/README.md` — nghiên cứu đọc bộ nhớ game (thư mục riêng, không đẩy lên repo)

---

# A. LÀM NGAY — nhỏ, nằm gọn trong v3

## A1. Chốt kiểm *Advanced Tooltip Information* — ✅ ĐÃ LÀM (24/09/2026)

**Đây là lỗ hổng có thể làm đăng sai hàng loạt mà không ai biết.**

Luật nhận dấu sao của ta: *"dòng nào không in `[min - max]` thì là Greater
Affix"*. Mà cái in ra khoảng đó **chính là công tắc Advanced Tooltip
Information** trong Options → Gameplay.

Tắt công tắc ⇒ game không in khoảng cho dòng nào ⇒ D4Lister đóng dấu sao lên
**toàn bộ** affix ⇒ đăng lên sàn sai hết. Im lặng, không cảnh báo.

D4LF chặn bằng một phép đếm rẻ tiền (`src/loot/filter.py`):

```python
# If more than 80% of the items had all greater affixes that means
# something is probably wrong
if num_of_affixed_items_checked > 2 and (
        num_of_items_with_all_ga / num_of_affixed_items_checked > 0.8):
    LOGGER.warning("... You are either exceptionally lucky or have not
                    enabled Advanced Tooltip Information")
```

**Cách làm cho ta:** trong `LocMonTTS`, đếm số dòng chỉ số và số dòng không
có ngoặc. Cả món mà **mọi dòng đều không ngoặc** thì đánh dấu nghi ngờ. Một
món có thể là thật; **ba món liên tiếp** thì chắc chắn công tắc đang tắt —
lúc đó hiện cảnh báo thay vì lặng lẽ đóng sao.

Công sức: vài dòng. Giá trị: chặn đúng loại lỗi đắt nhất trong việc bán hàng.

## A2. Ba việc còn dở của v3

| | Tình trạng |
|---|---|
| **Ổ ngọc** | chỉ đếm được ổ TRỐNG. Ổ đã nhét ngọc thì game in tác dụng viên ngọc, không in chữ `Empty Socket`. Chưa có cách nhận ra — ít nhất nên báo cho người dùng biết số ổ có thể thiếu |
| **Đồ Magic / Common** | mã dùng chung đường với Rare nên chạy được, nhưng **chưa thử lần nào**. Người dùng không bán hai loại này |
| **Mã CLASSIC** trong tiện ích | còn nguyên, xoá được sau khi diablo.trade bỏ chế độ đó |

---

# B. V4 — QUÉT CẢ TAB RƯƠNG

**Đây là thao tác nặng nhất còn lại.** Hiện phải rê chuột rồi bấm F3 cho
từng món; một tab rương 33 ô là 33 lần.

Có **hai con đường**, và chúng loại trừ nhau. Chọn một.

## B1. Rê chuột tự động — đường của D4LF

**Làm được ngay.** D4LF đã chứng minh, mã ở `src/loot/filter.py` +
`src/automation/inventory.py`:

```python
occupied, _ = inv.get_item_slots()      # chup man hinh -> o nao co do
for item in occupied:
    if item.is_junk or item.is_fav:     # da co dau thi bo qua
        continue
    inv.hover_item_with_delay(item)     # TU RE CHUOT qua o do
    ...                                 # game gui tooltip qua duong ong
```

Và tự chuyển tab (`src/loot/orchestration.py`):

```python
for tab in get_settings().general.check_chest_tabs:
    stash.switch_to_tab(tab)
    check_items(stash, ...)
check_items(inv, ...)                   # roi den tui do nhan vat
```

Lưới rương của họ: **3 hàng × 11 cột = 33 ô** (`Inventory(rows=3, columns=11)`).

**D4LF không giúp được phần dữ liệu:** nó đọc xong chỉ để quyết giữ hay vứt
rồi **vứt luôn nội dung**. Không file nào chứa danh sách item — `~/.d4lf/`
chỉ có `params.ini` và `profiles/`. Mượn được **cách rê**, không mượn được
dữ liệu.

**D4Lister chỉ thiếu đúng một mảnh: tự rê chuột.** Phần đọc chữ và phần giữ
nội dung đã có sẵn và chạy ổn.

### Hai việc phải giải

**a) Biết ô nào có đồ.** D4LF chụp màn hình để dò. V3 đã bỏ hết bộ xử lý ảnh
nên **đừng dựng lại** — cách rẻ hơn: rê hết 33 ô, ô trống thì game không gửi
tooltip, mình bỏ qua. Chậm hơn chút nhưng không phải nuôi lại GDI+.

**b) Toạ độ lưới.** Phụ thuộc độ phân giải. Cần hiệu chỉnh **một lần**:
người dùng chỉ vào ô đầu và ô cuối, nội suy ra lưới, lưu lại.
→ *Cần người dùng cho một ảnh chụp rương ở đúng độ phân giải đang chơi.*

### Rê chuột phải có nhịp

Chỗ khiến D4LF trông mượt, và là chỗ tiện ích của ta từng bị chê "gà mờ":

```python
Mouse.move(*window_to_monitor(item.center), randomize=15, delay_factor=(2, 3))
```

`randomize=15` lệch ngẫu nhiên 15 pixel quanh tâm ô; `delay_factor` cho thời
gian di chuyển ngẫu nhiên; `pytweening` làm đường đi cong có gia tốc.

AutoHotkey làm chỗ này **dễ hơn Python** — `MouseMove` có sẵn tham số tốc độ,
không cần thư viện nào.

### Ước lượng

| | |
|---|---|
| Mỗi ô (rê + chờ tooltip) | ~150–250 ms |
| Cả tab 33 ô | ~6–8 giây, không phải ngồi trông |

**Đo thật trước khi làm:** chạy `F11` của D4LF, xem nó rê nhanh cỡ nào và
chờ bao lâu mỗi ô.

### Ba cái bẫy đoán trước

- **Vét ống sau mỗi ô.** F3 hiện tại đã vét ống trước khi lấy; quét hàng
  loạt cũng phải vét sau mỗi ô, không thì dồn hàng đợi rồi lấy nhầm món
  (bẫy 3, `NHAT-KY-V3.md`).
- **Món trùng nhau.** `g_MonDaLay` chặn bấm F3 hai lần cùng một món. Quét
  hàng loạt phải so theo **nội dung từng món**, không phải "món cuối".
- **Chuột đang bận.** Người dùng lỡ động chuột giữa chừng là hỏng cả lượt.
  Cần phím huỷ, và trả con trỏ về chỗ cũ khi xong.

## B2. Đọc thẳng bộ nhớ game — tốt hơn, nhưng chưa xong

Xem `_bo-nho/README.md` (đo ngày 23/09/2026). Tóm tắt:

**Hai câu hỏi lớn đã có đáp án chắc chắn:**
- Windows **không cản** việc đọc: `OpenProcess(PROCESS_VM_READ)` thành công
  8/8 lần, không có driver kernel nào tước handle
- **Rương NẰM trong bộ nhớ client** — có bằng chứng, không phải suy đoán

**Nếu đi được đường này thì hơn hẳn B1:** không rê chuột, không phụ thuộc độ
phân giải, đọc cả rương lẫn túi trong một nhịp, và xoá sạch mọi cái bẫy sinh
ra từ việc đoán chữ.

**Nhưng chưa tới đích.** Bốn cách quét mù đều thất bại và **đừng thử lại**:
tìm theo giá trị hiển thị, tìm cụm giá trị, quét vi sai, tìm cặp mã-giá trị.

Còn đúng hai đường:
1. **Đi theo chuỗi con trỏ**, neo vào toạ độ nhân vật (ba số thực trôi đều
   khi đi bộ). Cần người dùng cho nhân vật chạy trong lúc chụp vài lượt.
2. **Dịch ngược tĩnh** bằng IDA/Ghidra. Chắc ăn nhất nhưng nặng nhất; exe
   58 MB không có RTTI để bám.

**Lưu ý đã chốt:** không dùng qqt — nó chèn DLL vào tiến trình game, mức can
thiệp cao nhất, Warden dò được. Tài khoản bán hàng là tài khoản thật. Chỉ
giữ qqt làm tài liệu tham khảo về mô hình đối tượng.

## B3. Chuyển đồ hàng loạt — sau khi có B1 hoặc B2

D4LF có `F7`/`F8` chuyển đồ rương ↔ túi, chọn được **chỉ chuyển loại nào**
(`move_to_stash_item_type` / `move_to_inv_item_type`).

Luồng đẹp cho người bán: quét cả tab → chọn món đáng bán → **gom vào một tab
riêng** → đăng dần. Hiện phải kéo tay từng món.

Chỉ đáng làm **sau** khi quét được, vì phải biết món nào đáng giữ trước.

---

# C. ĐỂ DÀNH — lớn hơn hẳn

## C1. Rê chuột là hiện giá tham khảo

Thứ **D4LF không làm được**, vì họ không có dữ liệu giá. Ta có: diablo.trade
chính là nơi đang bán.

Rê chuột lên món trong game mà hiện được *"món tương tự đang rao 40–60
triệu"* thì đó đúng là thứ người bán cần.

Cần một mảng hoàn toàn mới: đọc giá từ trang, gom, đối chiếu. Không phải
chuyện vài buổi.

## C2. Mô tả aspect bản offline

Hiện tiện ích moi danh mục aspect từ **bộ nhớ React của trang**. Trang đổi
cấu trúc là gãy.

Bản dự phòng phải **hứng từ chính diablo.trade** một lần rồi cất, giống cách
`extension/affix-list.js` đã làm với 638 tên affix. **Không lấy từ D4LF
được** — xem mục D3.

## C3. Sigil · Tribute · Seal · Charm

Nếu sau này bán mấy thứ đó thì bộ lọc chữ phải học thêm dạng tooltip riêng
của chúng. Hiện chỉ biết đồ trang bị.

---

# D. ĐÃ ĐÓNG — đừng đào lại

## D1. Đẩy một phát vào form diablo.trade

Đo thật 5 lượt dán trong 16 phút, 5 món khác nhau: form mà tiện ích với tới
được **luôn** chứa đúng bốn chỉ số của một món từ lâu, đã chết, và là form
**duy nhất** trong cả cây React. Lưới vét quét cả cây cũng không ra cái thứ
hai.

⇒ Form đang sống của chế độ BETA **không phơi ra `getValues`/`setValue`**.
`replace()` / `append()` / `reset()` đều không với tới. Lý do đầy đủ ở
`NHAT-KY-V3.md`, mục *Kết luận về đường "đẩy một phát"*.

Đường đang dùng (mở danh sách `ADD STANDARD AFFIXES` một lần rồi thêm từng
dòng) chạy ổn định **160–300 ms mỗi dòng**.

## D2. Bốn cách quét mù bộ nhớ

Tìm theo giá trị hiển thị, tìm cụm giá trị, quét vi sai, tìm cặp mã-giá trị.
Đều thất bại, lý do ghi trong `_bo-nho/README.md` mục 3.

## D3. Danh mục offline của D4LF

`assets/lang/enUS/*.json` **không thay được** danh mục của diablo.trade. Đã
mở ra kiểm, không đoán:

- `aspects.json` = 584 **tên trần**, không mô tả. Bài toán của ta đi **ngược**
  (game cho MÔ TẢ → cần tìm TÊN) nên vô dụng.
- `affixes.json` = 888 tên **phía GAME**, khác hệ đặt tên:

```
thu vien cua ta   : 638 ten   (lay tu diablo.trade/wiki/affixes)
affixes.json D4LF : 888 ten   (ten phia GAME)
ta khong co       : 796
ho khong co       : 546
```

Chênh cả hai chiều gần hết ⇒ hai hệ khác nhau, không phải cái này rộng hơn.
diablo.trade gọi `abyss skills`, game gọi `abyss damage`.

**Đừng đổ chung.** `THU_VIEN` tồn tại để trả lời *"diablo.trade có affix tên
này không"*. Nhét tên phía game vào là tiện ích đi thêm affix mà trang không
hề có.

Còn dùng được: `aspects.json` / `uniques.json` để **kiểm tra** một tên phía
game có thật không; và nếu sau này cần đi từ chữ của game → mã định danh của
game (đúng việc D4LF làm).

## D4. Các tính năng D4LF không liên quan việc bán

Lớp phủ Paragon · đồng hồ World Boss/Legion/Helltide · vàng/giờ · EXP/giờ ·
nhập build từ Maxroll/D4Builds/Mobalytics · tự dùng Temper Manual · chế độ
mù màu · đổi giao diện sáng tối.

---

# Thứ tự đề nghị

```
1.  A1  chốt kiểm Advanced Tooltip      nhỏ, chặn lỗi đắt nhất
2.  B1  quét cả tab bằng rê chuột       cắt thao tác nặng nhất
3.  B3  chuyển đồ hàng loạt             nối tiếp B1
4.  A2  dọn nốt việc dở của v3
5.  C1  giá tham khảo                   dự án riêng
```

**B2 (đọc bộ nhớ) thay thế được B1 và tốt hơn hẳn** — nhưng còn hai đường
đều nặng. Nếu quyết đi B2 thì đừng làm B1 trước, phí công.

---

# Ghi chú vận hành

**D4LF và D4Lister không chạy cùng lúc được.** Cả hai dùng đường ống
`\\.\pipe\d4lf`, mà ống chỉ cho một mối nối. D4Lister v3 tự thử lại mỗi
giây nên thoát D4LF là nó cầm lại ống ngay, không cần khởi động lại.

Thứ tự tự nhiên:

```
farm xong  →  D4LF lọc rác + gom vào rương  →  F12 thoát
           →  D4Lister lấy từng món  →  đăng lên sàn
```
