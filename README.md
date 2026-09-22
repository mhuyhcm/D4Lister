# D4Lister

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

Ý tưởng cốt lõi: **tách hai giai đoạn**. Gom hết item trong game trước (không
alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài trên một máy mới

Tải đúng **một file** rồi bấm đúp:

https://raw.githubusercontent.com/mhuyhcm/D4Lister/main/CAI-DAT.bat

*(Chuột phải vào link → Save link as…)*

Nó tự tải mã nguồn, bung Tesseract, cài AutoHotkey nếu máy chưa có, rồi chạy.
**Không cần cài Git.**

Xong nó nhắc bạn làm **việc duy nhất phải làm tay** — nạp tiện ích vào Chrome.
Đường dẫn đã chép sẵn vào clipboard:

1. Gõ vào thanh địa chỉ: `chrome://extensions`
2. Bật **Developer mode** (góc trên bên phải)
3. Bấm **Load unpacked**
4. Trong ô File name bấm **Ctrl+V** rồi **Select Folder**

Chrome bắt buộc chính người dùng bấm — không chương trình nào lách được.

## Từ đó về sau: bấm đúp `D4Lister.ahk`

Chỉ một file. Mỗi lần chạy nó tự làm ba việc:

```
1. Chưa có Tesseract  →  bung ra (chỉ lần đầu, ~4 giây)
2. Hỏi GitHub có bản mới không
       có   →  tải về, ghi đè, tự nạp lại  ↺
       không →  đi tiếp
3. Sẵn sàng
```

Bấm **Ctrl+Shift+F11** lúc nào cũng được để nạp lại và kiểm tra bản mới.

Mất mạng thì bỏ qua im lặng. Thư mục `queue\` và file riêng của bạn không bao
giờ bị đè.

## Cập nhật tiện ích Chrome

Chrome **không bao giờ** tự nạp lại tiện ích cài kiểu *Load unpacked*. File trên
đĩa đã mới mà trình duyệt vẫn chạy bản cũ — không ai biết.

Nên D4Lister gửi kèm số hiệu bản trên đĩa mỗi lần bạn dán. Tiện ích so với bản
nó đang chạy, lệch thì **hiện băng đỏ ngay trên trang**:

> **Tiện ích đang chạy bản cũ** — đang chạy 0.7, trên đĩa đã là 0.8.
> Vào chrome://extensions bấm nút xoay vòng, rồi F5 trang này.

Không thể bỏ sót được.

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

## Thiết lập

Bấm vào chip **D4Lister** ở góc dưới bên trái là mở bảng thiết lập. Đổi xong
dùng ngay, không phải sửa file, không phải nạp lại.

| Mục | Mặc định | Nghĩa |
|---|---|---|
| Tự đăng | bật | Điền xong, mọi thứ sạch thì tự bấm SUBMIT |
| Đăng cả khi có cảnh báo | **tắt** | Bật lên là số sai vẫn lên sàn mà bạn không biết |
| Tự thêm affix thiếu | bật | Trang không dựng ra dòng nào thì tự mở danh sách thêm |
| Tự bật dấu sao | bật | Greater Affix — đo bằng pixel từ ảnh chụp |
| Đếm ngược | 5 giây | Thời gian chờ trước khi bấm đăng |

Thiết lập lưu trong trình duyệt, mỗi máy một bản riêng.

## Tự đăng

Điền xong, nếu **mọi thứ sạch** thì đếm ngược rồi tự bấm SUBMIT. Bạn không phải
bấm gì.

Sạch nghĩa là: không dòng nào vượt khoảng của trang, không thiếu affix nào,
không lỗi. Có bất kỳ cảnh báo nào thì **nó dừng lại và hỏi** — vì đã đo được là
trang có thể âm thầm đổi số (12.5 thành 10 mà không báo), và OCR cũng có lúc
đọc sai.

Đang đếm ngược mà bấm **Esc**, hoặc gõ vào ô giá, là nó dừng.
Gõ giá xong thì bấm **Ctrl+Enter** để đăng — khỏi phải rê chuột.

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
D4Lister.ahk      ← bấm đúp cái này, hết
CAI-DAT.bat       ← chỉ dùng một lần trên máy mới
extension\        ← Chrome trỏ vào đây
queue\            ← ảnh + chữ đã gom
tesseract\        ← tự bung ra lần đầu
_he-thong\        ← không cần đụng vào
     d4lister-nen.ps1          cài / cập nhật
     CHAY.bat                  dự phòng nếu không bấm đúp .ahk được
     TAT-HET.bat
     CAI-TIEN-ICH-CHROME.bat
     TatThongBaoSnip.bat  (+ file hoàn tác)
     bo-cai\                   bộ cài AutoHotkey + Tesseract nén
```
