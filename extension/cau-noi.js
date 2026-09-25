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
  window.addEventListener('message', ev => {
    if (ev.source !== window) return;
    const d = ev.data;
    if (!d || d.d4l !== 'luu-dom' || !d.ten) return;

    const traLoi = kq => window.postMessage({
      d4l: 'luu-dom-xong',
      id: d.id,
      ok: !!(kq && kq.ok),
      loi: (kq && kq.loi) || '',
    }, '*');

    try {
      chrome.runtime.sendMessage(
        { kieu: 'luu-dom', ten: d.ten, chu: String(d.chu || '') },
        kq => traLoi(chrome.runtime.lastError
          ? { ok: false, loi: chrome.runtime.lastError.message }
          : kq),
      );
    } catch (e) {
      traLoi({ ok: false, loi: String(e) });
    }
  });
})();
