# D4Lister

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

Ý tưởng cốt lõi: **tách hai giai đoạn**. Gom hết item trong game trước (không
alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài — làm một lần

1. Cài **AutoHotkey v1.1** nếu máy chưa có → https://www.autohotkey.com/download/ahk-v1.zip
2. Chạy **`CAI-TIEN-ICH-CHROME.bat`** → làm 4 bước nó hướng dẫn để nạp tiện ích vào Chrome
3. Chạy **`CHAY.bat`**

Lần sau chỉ cần bước 3.

Không có Tesseract thì tool vẫn chạy, chỉ là không có chữ — quay về cách cũ
(dán ảnh rồi bấm SCAN, tự sửa chỉ số bằng tay).

---

## Phím

| Phím | Việc |
|---|---|
| **F3** | chụp item — kéo chọn vùng tooltip |
| **F4** | dán món đang chọn |
| **F5** | sang món kế **và dán luôn** |
| **F6** | lùi về món trước |
| **F7** | đổi chế độ xử lý ảnh (0 / 2) |
| **F9** | xóa sạch hàng đợi |
| **Ctrl+Shift+F12** | thoát hẳn |

Tất cả đều là phím **toàn cục** — đang ở game hay trình duyệt đều ăn.

---

## Quy trình

**Trong game** — rê chuột lên item, `F3`, kéo chọn vùng tooltip. Lặp cho từng
món. Bấm xong là xong ngay, phần đọc chữ chạy ngầm.

**Trên trình duyệt** — mở diablo.trade → Create Listing:

```
F4  →  dán món 1  →  SCAN  →  liếc kiểm  →  gõ giá  →  SUBMIT
F5  →  dán món 2  →  SCAN  →  liếc kiểm  →  gõ giá  →  SUBMIT
F5  →  ...
```

---

## Cách nó chạy

Mỗi lần `F3` đẻ ra hai file trong `queue\`:

```
001.png    ảnh tooltip
001.txt    chữ Tesseract đọc được
```

Lúc dán, **cả hai** được bỏ lên clipboard cùng lúc. Một lần `Ctrl+V`:

- **diablo.trade** nhặt **ảnh** → nhận ra đây là món gì, dựng các ô affix
- **tiện ích D4Lister** nhặt **chữ** → ghi đè mọi ô chỉ số

Con số đi thẳng từ Tesseract trên máy bạn vào ô nhập, **không qua bộ quét của
diablo.trade**. Đó là chỗ tránh được hết lỗi đọc sai số.

Tiện ích còn tự **thêm dòng affix** mà trang không dựng ra, và đối chiếu từng
số với khoảng hợp lệ mà trang giấu sẵn trong trang.

**Nút SUBMIT vẫn bạn tự bấm.** Cố ý để vậy.

---

## Đã đo và TỆ HƠN — đừng thử lại

| Thử | Kết quả |
|---|---|
| Phóng 3× trở lên | trang quét chậm hẳn, đọc thiếu nhiều hơn |
| Nét cứng (NearestNeighbor) | cạnh răng cưa, OCR đọc kém hẳn |
| Bão hòa 1.4 | khuếch đại viền màu ở mép chữ |
| Bộ OCR có sẵn của Windows | mất số `900`, đọc `+3 to Imbuement Skills` thành `+3 to Skills` |

Nguyên tắc: **mỗi lần chỉ đổi MỘT biến** rồi chụp lại đúng một món quen thuộc
để so. Đổi nhiều thứ cùng lúc thì không biết cái nào gây ra.

## Còn phải đo

Chế độ **0** (ảnh gốc) có thể đã đủ cho Tesseract — nếu đủ thì `F3` nhanh thêm
khoảng 0,7 giây. Bấm `F7` để nhảy qua lại 0 và 2, chụp cùng một món, rồi mở hai
file `.txt` ra so.

---

## Thư mục

```
D4Lister.ahk               tool chính
CHAY.bat                   chạy
TAT-HET.bat                tắt (không đụng script AHK khác của bạn)
CAI-TIEN-ICH-CHROME.bat    hướng dẫn nạp tiện ích
extension\                 tiện ích Chrome
queue\                     ảnh + chữ đã gom
TatThongBaoSnip.bat        tắt thông báo Snip & Sketch (+ file hoàn tác)

_cu\                       bản 2 máy dùng Syncthing — không dùng nữa, giữ phòng khi
create-listing\            bản lưu DOM của diablo.trade, dùng để tra cấu trúc
_anh-cu\  thu-nghiem\      ảnh mẫu để đo
```
