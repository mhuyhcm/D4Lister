# Ý tưởng cho V4

Ghi ngày **24/09/2026**, sau khi chạy thử **D4LF v10.0.5** và đọc mã nguồn
của họ. Chốt ở D4Lister **v3** (AHK v3 + tiện ích 7.1).

---

## 1. QUÉT CẢ TAB RƯƠNG — đáng làm nhất

**Vấn đề:** hiện phải rê chuột rồi bấm F3 cho **từng món**. Một tab rương
33 ô là 33 lần.

**D4LF đã làm được**, mã ở `src/loot/filter.py` + `src/automation/inventory.py`:

```python
occupied, _ = inv.get_item_slots()      # chup man hinh -> o nao co do
for item in occupied:
    if item.is_junk or item.is_fav:     # da co dau thi bo qua
        continue
    inv.hover_item_with_delay(item)     # TU RE CHUOT qua o do
    ...                                 # game gui tooltip qua duong ong
```

Và nó **tự chuyển tab** (`src/loot/orchestration.py`):

```python
for tab in get_settings().general.check_chest_tabs:
    stash.switch_to_tab(tab)
    check_items(stash, ...)
check_items(inv, ...)                   # roi den tui do nhan vat
```

Lưới rương của họ: **3 hàng × 11 cột = 33 ô** (`Inventory(rows=3, columns=11)`).

**Chỗ D4LF không giúp được:** nó đọc xong chỉ để quyết giữ hay vứt rồi
**vứt luôn nội dung**. Không có file nào chứa danh sách item — thư mục
`~/.d4lf/` chỉ có `params.ini` và `profiles/`. Nên không mượn dữ liệu được,
chỉ mượn **cách rê**.

**D4Lister cần thêm đúng một mảnh:** tự rê chuột. Phần đọc chữ và phần giữ
nội dung đã có sẵn và chạy ổn.

### Hai việc phải giải

**a) Biết ô nào có đồ.** D4LF chụp màn hình để dò. V3 đã bỏ hết bộ xử lý
ảnh nên đừng dựng lại — cách rẻ hơn: **rê hết 33 ô**, ô trống thì game
không gửi tooltip, mình bỏ qua. Chậm hơn chút nhưng không phải nuôi lại
GDI+.

**b) Toạ độ lưới.** Phụ thuộc độ phân giải. Cần một bước hiệu chỉnh MỘT
lần: người dùng chỉ vào ô đầu và ô cuối, mình nội suy ra lưới, lưu lại.

### Ước lượng

| | |
|---|---|
| Mỗi ô (rê + chờ tooltip) | ~150–250 ms |
| Cả tab 33 ô | ~6–8 giây, không phải ngồi trông |

**Cần đo thật trước khi làm:** chạy `F11` của D4LF rồi xem nó rê nhanh cỡ
nào và chờ bao lâu mỗi ô. Hai con số đó quyết định nhịp của mình.

### Bẫy đoán trước

- **F3 hiện tại vét ống trước khi lấy** — quét hàng loạt cũng phải vét sau
  mỗi ô, không thì dồn hàng đợi rồi lấy nhầm món (xem bẫy 3 ở
  `NHAT-KY-V3.md`).
- **Món trùng nhau**: `g_MonDaLay` chặn bấm F3 hai lần cùng một món. Quét
  hàng loạt thì phải so theo **nội dung từng món**, không phải "món cuối".
- **Chuột đang bận**: người dùng lỡ động chuột giữa chừng là hỏng cả lượt.
  Nên có phím huỷ, và trả con trỏ về chỗ cũ khi xong.

---

## 2. Những tính năng khác của D4LF — có đáng mượn không

Liệt kê đủ, kèm đánh giá cho **người bán** (không phải người chơi build).

| Tính năng D4LF | Mượn? | Vì sao |
|---|---|---|
| **Chuyển đồ rương ↔ túi** (F7/F8) | **có thể** | Lọc xong gom hết đồ đáng bán vào một tab. Nối thẳng vào quy trình đăng |
| **Vision Mode** — rê chuột là hiện đánh giá | **có thể** | Ta có sẵn chữ; hiện thêm "giá tham khảo" ngay trên món sẽ mạnh hơn D4LF |
| Lọc rác theo profile | không | Đó là việc của D4LF, chạy song song được (khác lúc) |
| Lớp phủ Paragon | **không** | Dành cho người lên đồ |
| Lớp phủ đồng hồ World Boss / Helltide | không | Hữu ích chung nhưng lạc đề |
| Vàng/giờ, EXP/giờ | không | Lạc đề |
| Nhập build từ Maxroll / D4Builds / Mobalytics | không | Lọc theo build, người bán không cần |
| Tự dùng Temper Manual khi nhặt được | không | Lạc đề |
| Lọc Sigil / Tribute / Seal / Charm | **để ngỏ** | Nếu sau này bán mấy thứ đó thì bộ lọc chữ phải học thêm dạng tooltip của chúng |

### Hai cái đáng để ý nhất

**Chuyển đồ hàng loạt (F7/F8).** D4LF có `move_to_stash_item_type` và
`move_to_inv_item_type` — chọn loại đồ nào được chuyển. Với người bán,
luồng đẹp sẽ là: quét cả tab → chọn món đáng bán → **gom vào một tab
riêng** → đăng dần. Hiện phải kéo tay từng món.

**Vision Mode.** D4LF rê chuột là hiện đánh giá ngay trên màn hình. Ta có
lợi thế hơn họ: **ta có giá thật trên diablo.trade**. Rê chuột lên món mà
hiện được "món tương tự đang rao 40–60 triệu" thì đó là thứ D4LF không làm
được, và đúng thứ người bán cần.

---

## 3. Việc còn dở của V3

- Đường **đẩy một phát** vào form: đã chốt là **ngõ cụt**, đừng đào lại.
  Lý do đầy đủ ở `NHAT-KY-V3.md`, mục *Kết luận về đường "đẩy một phát"*.
- **Ổ ngọc**: chỉ đếm được ổ trống. Ổ đã nhét ngọc thì game in tác dụng của
  viên ngọc, không in chữ `Empty Socket`.
- **Đồ Magic / Common**: mã dùng chung đường với Rare nên chạy được nhưng
  chưa thử — người dùng không bán hai loại này.
- **Mã CLASSIC** còn nguyên trong tiện ích, xoá được sau khi diablo.trade
  bỏ chế độ đó.

---

## 4. Danh mục offline của D4LF — ĐÃ KIỂM, KHÔNG dùng thay được

`F:\Project\Website\D4LF\d4lf\assets\lang\enUS\` có `affixes.json`,
`aspects.json`, `uniques.json`, `sigils.json`…

**Thoạt nhìn tưởng là bản dự phòng cho danh mục lấy từ bộ nhớ React của
trang. Mở ra kiểm thì KHÔNG PHẢI.** Ghi lại đây để lần sau khỏi mừng hụt.

### `aspects.json` — chỉ có tên trần

```json
["accelerating", "aggressive", ..., "needleflare"]
```

584 tên, **không mô tả**. Mà bài toán của ta đi **ngược**: game đọc cho ta
MÔ TẢ, ta cần tìm ra TÊN. Danh sách tên trần không giải được.

### `affixes.json` — khác hệ đặt tên

Đo thật:

```
thu vien cua ta   : 638 ten   (lay tu diablo.trade/wiki/affixes)
affixes.json D4LF : 888 ten   (ten phia GAME)
ta khong co       : 796
ho khong co       : 546
```

Chênh cả hai chiều gần hết ⇒ **hai hệ đặt tên khác nhau**, không phải cái
này rộng hơn cái kia:

| diablo.trade gọi | game gọi |
|---|---|
| `abyss skills` | `abyss damage` |
| `+1 charm slot` | `aegis cooldown reduction` |

**Đừng đổ chung.** `THU_VIEN` tồn tại để trả lời *"diablo.trade có affix tên
này không"*. Nhét tên phía game vào là ext sẽ đi thêm affix mà trang không
hề có.

### Kết luận

Ta cần **từ điển của diablo.trade**, D4LF mang **từ điển của game**.

Bản dự phòng thật sự thì đã có sẵn: `extension/affix-list.js` — 638 tên hứng
từ chính diablo.trade. Thứ duy nhất chưa có bản offline là **mô tả của
aspect**; muốn có phải hứng từ diablo.trade một lần rồi cất, không lấy từ
D4LF được.

### Còn dùng được vào việc gì

- `aspects.json` (584) và `uniques.json` (328): danh sách tên hợp lệ phía
  game — dùng để **kiểm tra** một tên có thật không, không dùng để tra ngược.
- Nếu sau này cần đi từ **chữ của game → mã định danh của game** (đúng việc
  D4LF làm) thì mấy file này là nguồn đúng. Quy trình hiện tại không đi
  đường đó.
