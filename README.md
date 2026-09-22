# D4Lister v2

Đăng item Diablo 4 lên **diablo.trade** nhanh hơn. Chạy trên **một máy**.

> **v2** — tiện ích Chrome bản **4.7**.
>
> Khác v1 ở bốn chỗ:
> - **Điền thẳng vào ô, không gõ chữ.** Đọc cả khoảng hợp lệ thật từ trang
>   thay vì đoán, nên biết chắc số nào vượt khoảng.
> - **Con trỏ nhảy vào ô giá** sau khi điền xong; gõ số rồi **Enter** là đăng.
> - **Ảnh gửi lên nhẹ đi 74%** — tách bản phóng 2× (cho OCR) khỏi bản cỡ gốc
>   (cho trang).
> - **Bảng kết quả gọn lại**, thiết lập gộp vào luôn qua nút bánh răng.

Ý tưởng cốt lõi: **tách hai giai đoạn**. Gom hết item trong game trước (không
alt-tab lần nào), rồi sang trình duyệt đăng một mạch.

---

## Cài trên một máy mới

Tải đúng **một file** rồi bấm đúp:

https://raw.githubusercontent.com/mhuyhcm/D4Lister/main/CAI-DAT.bat

*(Chuột phải vào link → Save link as…)*

Nó tự lo hết: tải mã nguồn (~200 KB), **kiểm tra máy đã có AutoHotkey và
Tesseract chưa — thiếu cái nào thì tự tải cái đó về cài**, rồi chạy.
**Không cần cài Git.**

| Cần | Nặng | Bắt buộc? | Lấy ở đâu |
|---|---|---|---|
| AutoHotkey 1.1 | 3 MB | **có** | trang chủ autohotkey.com |
| Tesseract | 55 MB | không | bản xách tay ghim sẵn trong repo này |

Thiếu Tesseract thì tool vẫn chạy, chỉ là không đọc được chữ trong ảnh — quay
về cách cũ (dán ảnh, bấm SCAN, tự sửa số). Máy chặn mạng thì mở
`_he-thong\TAI-VE-TAY.txt`, trong đó có sẵn hai đường tải để làm tay.

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
F4  →  dán món 1  →  tự bấm SCAN  →  tự điền  →  tự đăng sau 5 giây
F5  →  dán món 2  →  tự bấm SCAN  →  tự điền  →  tự đăng
F5  →  ...
```

Từ bản 2.3 tiện ích **tự bấm SCAN** — nhưng chỉ khi ảnh đã nạp xong thật
(trình duyệt báo tải xong, kích thước ảnh khác 0, và đứng yên hai nhịp liền).
Món nào phải chọn base trước thì nó cũng tự chọn base trơn rồi bấm Next.

Điền xong, **con trỏ tự nhảy vào ô giá** — gõ số rồi bấm **Enter** là đăng.
Gõ phím cũng làm đếm ngược dừng lại, nên không sợ nó đăng trước khi bạn kịp
nhập giá. **Ctrl+Enter** đăng được từ bất cứ ô nào.

---

## Cách nó chạy

Mỗi lần `F3` đẻ ra ba file trong `queue\`:

```
001.png        ảnh phóng 2× — CHỈ để Tesseract đọc chữ và đo dấu sao
001-nho.png    ảnh cỡ gốc — bản này mới đưa lên clipboard cho trang
001.txt        chữ Tesseract đọc được
```

Hai bản ảnh vì hai việc khác nhau. **Phóng 2× là bắt buộc cho OCR** — đã đo,
ảnh gốc làm Tesseract đọc dấu `+` thành số `4` (`+2 to Demonology` thành
`42to Demonology`). Nhưng phóng 2× làm ảnh **nặng gấp bốn**: nội suy đẻ ra vô
số sắc độ trung gian, PNG nén kém hẳn. Đo trên 12 ảnh thật: **1322 KB so với
344 KB**.

Mà trang chỉ cần nhận ra **món gì** (tên, loại, độ hiếm) — mọi con số đã do
tiện ích ghi thẳng vào form. Nên gửi bản nhẹ là đủ.

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
| Tự bấm Scan | bật | Đợi ảnh nạp xong rồi mới bấm |
| Ghi thẳng vào form | bật | Lấy khoảng hợp lệ từ trang, thêm dòng khỏi gõ chữ |
| Nhảy vào ô giá | bật | Điền xong đặt con trỏ vào ô giá luôn |
| Tự chọn base | bật | Bước chọn hình món đồ — lấy base trơn rồi bấm Next |
| Tự thêm affix thiếu | bật | Dòng nào trang thiếu thì tự thêm |
| Tự bật dấu sao | bật | Greater Affix — xem mục dưới |
| Ghi file dò | **tắt** | Tải file chẩn đoán về máy, chỉ bật khi cần gửi đi |
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

## Dấu sao (Greater Affix)

Dấu ✳ là **hình vẽ**, OCR không đọc ra thành chữ được. D4Lister nhận nó bằng
**hai đường**, có một đường ăn là đủ:

1. **OCR đọc được cái dấu.** Dấu chấm đầu dòng ◆ hay bị đọc thành `© e ¢ @ ®`,
   còn dấu sao ✳ hay bị đọc thành `#` hoặc `*`. Đo trên 46 lần thật: 25 dòng
   OCR thấy `#`/`*` thì mật độ điểm sáng 0.176–0.524, 21 dòng không thấy thì
   0.000–0.161 — **hai nhóm không chồng nhau**.
2. **Đếm điểm sáng** trong ô bên trái con số. Đây là lưới đỡ cho lúc OCR nuốt
   mất cái dấu. Ngưỡng `SAO_NGUONG` = 0.25.

Phải có cả hai vì mỗi đường đều có lỗ: phép đếm điểm sáng **yếu đi khi chữ to**
(cùng một dấu sao, chữ `h=25` cho 0.45 nhưng chữ `h=39` chỉ còn 0.216 — tụt
dưới ngưỡng), còn OCR thì có lúc không thấy cái dấu.

**Chỉ đo đúng dòng affix.** Mọi từ đứng trước con số phải là **một ký tự**.
Dòng affix thật chỉ có đúng một ký tự đứng trước (cái dấu). Có từ thật đứng
trước nghĩa là đang ở giữa một câu văn — ô soi sẽ trùm lên chữ, chữ sáng rực,
báo có sao oan. Đã gặp thật: `they are 70% more potent.` đo được 0.490.

Số đo ghi ra `queue\_sao.log` để còn dò lại khi sai.

## Hai chế độ CLASSIC / BETA

Trang có công tắc **Classic | Beta** ở đầu trang Create, cùng hàng với dòng
`Home / Marketplace / Create`, dạt về mép phải. Hai bản dựng form **khác hẳn
nhau**.

Tiện ích đỡ cả hai: mỗi lần chạm vào trang nó hỏi lại đang ở bản nào rồi dùng
bộ mốc tương ứng — gạt qua gạt lại không cần tải lại trang.

Đang dùng **Beta**. Gói ngôn ngữ của trang ghi *"Classic is retiring after
Season 15"* nên không đầu tư thêm cho Classic; mã đỡ Classic vẫn giữ, nằm im.

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

## Chế độ 0 hay 2 — đã đo xong, dùng 2

Câu hỏi để ngỏ lâu nay: ảnh gốc (chế độ 0) có đủ cho Tesseract không? Đã đo
trên 9 ảnh chụp thật, chạy Tesseract ở cả hai cỡ:

| | ảnh gốc (1×) | phóng 2× (đang dùng) |
|---|---|---|
| thời gian OCR | 0,70 giây | 1,04 giây |
| `+2to Demonology Skills` | đọc thành **`42to`** | đúng |
| `+3to Sigil of Subversion` | đọc thành **`43to`** | đúng |

Ảnh gốc nhanh hơn 32%, nhưng **dấu `+` bị đọc thành số `4`** — đúng kiểu lỗi
đã dính với `psm 6` (`+12.5%` → `412.5%`). Số sai mà trông vẫn hợp lệ là lỗi
tệ nhất của tool này. **Giữ 2×.**

---

## Thư mục

```
D4Lister.ahk      ← bấm đúp cái này, hết
CAI-DAT.bat       ← chỉ dùng một lần trên máy mới
extension\        ← Chrome trỏ vào đây
queue\            ← ảnh + chữ đã gom
tesseract\        ← tự tải về lần đầu, không nằm trong bản tải
_he-thong\        ← không cần đụng vào
     d4lister-nen.ps1          cài / cập nhật
     TAI-VE-TAY.txt            hai đường tải, dùng khi máy chặn mạng
     CHAY.bat                  dự phòng nếu không bấm đúp .ahk được
     TAT-HET.bat
     CAI-TIEN-ICH-CHROME.bat
     TatThongBaoSnip.bat  (+ file hoàn tác)
```

Bản tải về nặng khoảng **200 KB**. Trước đây nó kéo theo cả bộ cài Tesseract và
AutoHotkey nên nặng **59 MB** — mỗi lần cập nhật vài dòng mã cũng phải tải lại
từng ấy. Hai bộ cài vẫn nằm trong repo ở mốc `v1`, chỉ tải khi máy thực sự
thiếu.
