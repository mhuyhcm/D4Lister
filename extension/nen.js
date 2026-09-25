// =====================================================================
//  TIẾN TRÌNH NỀN — chỉ làm một việc: ghi file xuống đĩa
//
//  Dùng chrome.downloads chứ không phải thẻ <a download> trong trang, vì
//  hai lẽ:
//
//    1. Thẻ <a download> KHÔNG tạo được thư mục con — Chrome bỏ dấu gạch
//       chéo trong tên file. chrome.downloads thì giữ nguyên đường dẫn, nên
//       mỗi lượt chạy gom được vào một thư mục riêng.
//    2. Tải liên tiếp nhiều file bằng thẻ <a> là Chrome hỏi "cho phép tải
//       nhiều file?" — mỗi món hỏi một lần thì không dùng nổi.
//       chrome.downloads không hỏi.
//
//  Đường dẫn nằm dưới thư mục Tải xuống của Chrome, ví dụ:
//      d4l-hoso/20260925-153012-infernal-homunculus/03-danh-sach-goi-y.html
// =====================================================================

//  Chuỗi UTF-8 -> base64, làm theo TỪNG KHÚC.
//
//  Cách một dòng quen thuộc — String.fromCharCode(...mang) — vỡ ngăn xếp
//  khi mảng lớn, mà ảnh chụp DOM thì hàng trăm nghìn byte.
function sangBase64(chu) {
  const byte = new TextEncoder().encode(chu);
  let s = '';
  const KHUC = 0x8000;
  for (let i = 0; i < byte.length; i += KHUC)
    s += String.fromCharCode.apply(null, byte.subarray(i, i + KHUC));
  return btoa(s);
}

chrome.runtime.onMessage.addListener((tin, nguoiGui, traLoi) => {
  if (!tin || tin.kieu !== 'luu-dom') return;
  try {
    const kieuMime = /\.txt$/i.test(tin.ten) ? 'text/plain' : 'text/html';
    chrome.downloads.download({
      url: 'data:' + kieuMime + ';charset=utf-8;base64,' + sangBase64(tin.chu || ''),
      filename: tin.ten,
      saveAs: false,
      conflictAction: 'uniquify',
    }, id => {
      traLoi(chrome.runtime.lastError
        ? { ok: false, loi: chrome.runtime.lastError.message }
        : { ok: true, id });
    });
  } catch (e) {
    traLoi({ ok: false, loi: String(e) });
  }
  return true;          // trả lời bất đồng bộ
});
