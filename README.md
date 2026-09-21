# D4Lister

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

Ý tưởng cốt lõi: **tách hai giai đoạn**. Gom hết item trong game trước (không
alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài trên một máy mới

Tải đúng **một file** rồi bấm đúp:

https://raw.githubusercontent.com/mhuyhcm/D4Lister/main/CAI-DAT.bat

*(Chuột phải vào link → Save link as…)*

Nó tự làm hết: tải mã nguồn, bung Tesseract, cài AutoHotkey nếu máy chưa có,
rồi chạy luôn. **Không cần cài Git.**

Xong nó sẽ nhắc bạn làm **việc duy nhất phải làm tay** — nạp tiện ích vào
Chrome. Đường dẫn đã chép sẵn vào clipboard, chỉ cần dán:

1. Gõ vào thanh địa chỉ: `chrome://extensions`
2. Bật **Developer mode** (góc trên bên phải)
3. Bấm **Load unpacked**
4. Trong ô File name bấm **Ctrl+V** rồi **Select Folder**

Chrome bắt buộc chính người dùng bấm — không chương trình nào lách được.

Kiểm tra: mở https://diablo.trade, thấy dòng **D4Lister sẵn sàng** hiện ở góc
dưới bên phải là xong.

## Tự cập nhật

**Chạy D4Lister là nó tự kiểm tra.** Mỗi lần khởi động, và mỗi lần nạp lại
bằng **Ctrl+Shift+F11**.

Có bản mới thì nó tải về rồi tự nạp lại. Mất mạng thì bỏ qua im lặng, tool vẫn
chạy. Không cần Git.

Thư mục `queue\` và các file riêng của bạn không bao giờ bị đè.

**Một ngoại lệ:** Chrome KHÔNG tự nạp lại tiện ích cài kiểu *Load unpacked*.
Nên khi bản mới có sửa tiện ích, D4Lister hiện hộp thoại nhắc — lúc đó vào
`chrome://extensions` bấm nút xoay vòng rồi F5 trang diablo.trade. Không làm
thì trình duyệt vẫn chạy bản cũ.

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
F4  →  dán món 1  →  SCAN  →  tiện ích tự điền  →  tự đăng sau 5 giây
F5  →  dán món 2  →  SCAN  →  tự điền           →  tự đăng
F5  →  ...
```

Muốn đặt giá thì cứ gõ vào ô giá — gõ là đếm ngược dừng lại, gõ xong bấm
**Ctrl+Enter**.

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
cai-dat\                   bộ cài AutoHotkey + Tesseract xách tay (nén)
tesseract\                 Tesseract đã bung ra (CHAY.bat tự làm lần đầu)
queue\                     ảnh + chữ đã gom
TatThongBaoSnip.bat        tắt thông báo Snip & Sketch (+ file hoàn tác)

_cu\                       bản 2 máy dùng Syncthing — không dùng nữa, giữ phòng khi
create-listing\            bản lưu DOM của diablo.trade, dùng để tra cấu trúc
_anh-cu\  thu-nghiem\      ảnh mẫu để đo
```
