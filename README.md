# D4Lister

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

Ý tưởng cốt lõi: **tách hai giai đoạn**. Gom hết item trong game trước (không
alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài trên một máy mới

Cần **Git** (https://git-scm.com/download/win) rồi mở Git Bash hoặc CMD:

```
git clone https://github.com/mhuyhcm/D4Lister.git
```

Rồi trong thư mục vừa tải về:

1. Chạy **`CHAY.bat`**

Thế thôi. Lần đầu nó tự làm hết:

- Bung **Tesseract xách tay** ra từ `cai-dat\` (~4 giây, không cần cài đặt)
- Chưa có AutoHotkey thì mở bộ cài kèm sẵn — bấm *Express Installation*

2. Chạy **`CAI-TIEN-ICH-CHROME.bat`** → làm 4 bước nó hướng dẫn để nạp tiện ích
   vào Chrome. Đây là việc duy nhất phải làm tay, vì Chrome bắt buộc chính người
   dùng bấm.

Lần sau chỉ cần `CHAY.bat`.

## Tự cập nhật

Hai chỗ cùng kiểm tra bản mới:

- **`CHAY.bat`** tự `git pull` trước khi khởi động
- **Chính script AHK** kiểm tra lúc khởi động, và mỗi lần nạp lại
  (**Ctrl+Shift+F11**)

Có bản mới thì nó báo; không có mạng hoặc máy không cài git thì bỏ qua im lặng,
tool vẫn chạy.

**Một ngoại lệ:** Chrome KHÔNG tự nạp lại tiện ích đã cài kiểu *Load unpacked*.
Nên khi bản cập nhật có đụng vào thư mục `extension\`, `CHAY.bat` sẽ dừng lại và
nhắc to — lúc đó vào `chrome://extensions` bấm nút xoay vòng rồi F5 trang
diablo.trade. Không làm thì vẫn đang chạy bản cũ mà không biết.

## Sửa code ở máy chính rồi đẩy lên

```
git add -A
git commit -m "mo ta ngan"
git push
```

Các máy khác lần sau chạy `CHAY.bat` là tự có.

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
| **Ctrl+Shift+F11** | nạp lại script (kiểm tra luôn bản mới) |
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

## Tự đăng

Điền xong, nếu **mọi thứ sạch** thì tiện ích đếm ngược 5 giây rồi tự bấm SUBMIT.
Bạn không phải bấm gì.

Sạch nghĩa là: không dòng nào vượt khoảng của trang, không thiếu affix nào,
không lỗi. Có bất kỳ cảnh báo nào thì **nó dừng lại và hỏi** — vì đã đo được là
trang có thể âm thầm đổi số (12.5 thành 10 mà không báo), và OCR cũng có lúc
đọc sai.

Đang đếm ngược mà bấm **Esc**, hoặc gõ vào ô giá, là nó dừng.
Gõ giá xong thì bấm **Ctrl+Enter** để đăng — khỏi phải rê chuột.

Hai công tắc ở đầu file `extension\d4lister.js`:

```js
const TU_DANG              = true;   // false = không bao giờ tự đăng
const DANG_CA_KHI_CANH_BAO = false;  // true  = đăng cả khi có cảnh báo
const DEM_NGUOC            = 5;      // giây đếm ngược
```

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
