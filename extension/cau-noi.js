// =====================================================================
//  CẦU NỐI giữa d4lister.js và tiến trình nền
//
//  d4lister.js chạy ở world "MAIN" — chung sân với trang web, nhờ vậy nó
//  với tới được bộ máy React của diablo.trade. Cái giá: ở đó KHÔNG có
//  chrome.* nào cả, nên không tự tải file xuống thư mục riêng được.
//
//  File này chạy ở world "ISOLATED": không thấy React, nhưng có chrome.*.
//  Việc của nó đúng một chuyện — nghe d4lister.js gọi qua window.postMessage
//  rồi chuyển tiếp cho tiến trình nền, và báo kết quả ngược lại.
// =====================================================================
(() => {
  //  Chuyển một lời nhờ sang tiến trình nền rồi báo kết quả ngược lại.
  //  Tên thư trả lời = tên thư gửi + "-xong", để hai bên khỏi phải bịa
  //  thêm quy ước cho mỗi việc mới.
  const chuyen = (d, thu) => {
    const traLoi = kq => window.postMessage(Object.assign(
      { d4l: d.d4l + '-xong', id: d.id, ok: !!(kq && kq.ok), loi: (kq && kq.loi) || '' },
      kq && kq.ok ? kq : {},
    ), '*');
    try {
      chrome.runtime.sendMessage(thu, kq => traLoi(chrome.runtime.lastError
        ? { ok: false, loi: chrome.runtime.lastError.message }
        : kq));
    } catch (e) {
      traLoi({ ok: false, loi: String(e) });
    }
  };

  window.addEventListener('message', ev => {
    if (ev.source !== window) return;
    const d = ev.data;
    if (!d) return;

    if (d.d4l === 'luu-dom' && d.ten)
      chuyen(d, { kieu: 'luu-dom', ten: d.ten, chu: String(d.chu || '') });


  });
})();
