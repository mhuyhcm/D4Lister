// D4Lister - dien du lieu item vao form diablo.trade
// Ban extension cho Chrome. Ban Tampermonkey nam trong thu muc userscript.
(function () {
  'use strict';

  // ------------------------------------------------------------------
  //  Cach hoat dong:
  //  1. Ban Ctrl+V nhu binh thuong. Clipboard chua CA anh LAN chu.
  //  2. Trang lay ANH -> tu nhan ra mon do, dung san cac dong affix.
  //  3. Script nay lay CHU tu cung lan dan do -> sua lai tung con so.
  //  Chu do may ban OCR ra, KHONG qua bo quet cua trang -> khong sai so.
  // ------------------------------------------------------------------

  const NHIP_DO   = 500;     // ms giua hai lan ngo xem form da dung xong chua
  const CHO_TOI_DA = 120000; // ms bo cuoc neu mai khong thay dong affix nao
  let chuDaDan = '';
  let dongHo = null;

  const chuan = s => (s || '')
    .toLowerCase()
    .replace(/[^a-z0-9%]+/g, ' ')
    .trim();

  // bo chu "s" cuoi moi tu -> chiu duoc lech so it/so nhieu.
  // Can that: trang viet "Imbuements Skills", game viet "Imbuement Skills".
  const chuanManh = s => chuan(s).split(' ').map(t => t.replace(/s$/, '')).join(' ');

  // Dong KHONG phai affix: ten do, loai do, chi so goc. Nhom thu hai la phan
  // cuoi tooltip D4 - chung lot qua duoc vi cung co dang "<so> <chu>",
  // vi du "84 Unlocks new look on salvage".
  const BO_QUA = [
    /item power/i, /^armor\b/i, /^damage per second/i, /toughness/i,
    /^requires level/i, /empty socket/i,
    /unlocks new look/i, /sell value/i, /durability/i, /tempers?\s*:/i,
    /unique equipped/i, /lord of hatred/i,
  ];

  // --- doc chu item thanh danh sach {ten, so} -------------------------
  function docChuItem(text) {
    const ra = [];
    for (const dongGoc of text.split(/\r?\n/)) {
      const d = dongGoc.trim();
      if (!d) continue;
      // "**" o dau = dong co dau sao (Greater Affix). D4Lister do bang pixel
      // roi danh dau, vi dau sao la HINH VE nen OCR khong doc duoc.
      const sao = d.startsWith('**');
      const d2 = sao ? d.slice(2).trim() : d;
      // "+1,813 Maximum Life" | "+12.5% Attack Speed" | "+3 Imbuements Skills"
      const m = d2.match(/^\+?\s*([\d.,]+)\s*(%?)\s+(.+)$/);
      if (!m) continue;
      const so = parseFloat(m[1].replace(/,/g, ''));
      if (!isFinite(so)) continue;
      let ten = m[3].replace(/^to\s+/i, '').trim();
      if (!ten || ten.length < 3) continue;
      if (BO_QUA.some(r => r.test(d2))) continue;
      ra.push({ ten, so, phanTram: m[2] === '%', sao });
    }
    return ra;
  }

  // --- tim cac dong affix dang co tren form ---------------------------
  function timCacDong() {
    const ra = [];
    for (const inp of document.querySelectorAll('input[aria-label="Affix value"]')) {
      // di nguoc len tim khoi chua ca nut Remove -> do la mot dong affix
      let khoi = inp, nutXoa = null;
      for (let i = 0; i < 8 && khoi; i++) {
        khoi = khoi.parentElement;
        if (!khoi) break;
        nutXoa = khoi.querySelector('button[aria-label^="Remove "]');
        if (nutXoa) break;
      }
      if (!nutXoa) continue;
      const ten = nutXoa.getAttribute('aria-label').replace(/^Remove\s+/, '').trim();

      // khoang hop le nam trong tooltip an canh o nhap
      let min = null, max = null;
      for (const sp of khoi.querySelectorAll('span[aria-hidden="true"]')) {
        const m = (sp.textContent || '').match(/^\s*([\d.,]+)\s*[\u2013\u2014-]\s*([\d.,]+)\s*$/);
        if (m) {
          min = parseFloat(m[1].replace(/,/g, ''));
          max = parseFloat(m[2].replace(/,/g, ''));
          break;
        }
      }
      // cong tac dau sao cua chinh dong nay (Radix: role=checkbox + aria-checked)
      const nutSao = khoi.querySelector('button[aria-label="Greater Affix"]');
      ra.push({ ten, inp, min, max, nutSao });
    }
    return ra;
  }

  const saoDangBat = n => n && n.getAttribute('aria-checked') === 'true';

  // --- dat gia tri cho o input cua React ------------------------------
  function datGiaTri(inp, giaTri) {
    const setter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype, 'value').set;
    setter.call(inp, String(giaTri));
    inp.dispatchEvent(new Event('input',  { bubbles: true }));
    inp.dispatchEvent(new Event('change', { bubbles: true }));
  }

  // --- lay ten mon do dang mo tren form --------------------------------
  // Chi tin dung mot cho: tieu de tooltip mon do do trang tu ve.
  // KHONG duoc do sang alt cua anh - se vo nham logo trang ("Diablo.Trade").
  function layTenItemTrenForm() {
    const a = document.querySelector('[class*="font-tooltip-title"]');
    return a && a.textContent.trim() ? a.textContent.trim() : '';
  }

  // --- ap dung ---------------------------------------------------------
  function apDung(text, epBuoc) {
    // CHOT AN TOAN: chu phai dung mon dang mo, khong thi KHONG ghi gi ca.
    // Khong co cho nay thi script se am tham ghi so cua mon A vao form mon B.
    const tenForm = layTenItemTrenForm();
    const tenChu  = (text.split(/\r?\n/).find(l => l.trim()) || '').trim();
    if (!epBuoc && tenForm && tenChu && chuanManh(tenForm) !== chuanManh(tenChu)) {
      baoLechTen(tenForm, tenChu, text);
      return;
    }

    const muon = docChuItem(text);
    const dang = timCacDong();
    if (!dang.length) {
      bao([], [], [], 'Form chua co mon do nao. Hay bam nut SCAN truoc.');
      return;
    }

    // D4Lister chi gui dau hieu nay khi phan do dau sao THUC SU chay xong.
    // Khong co no (thieu Tesseract chang han) thi khong dung vao cong tac sao,
    // de khoi xoa nham dau sao ma trang da nhan dung.
    const coDoSao = /(^|\n)#D4L-SAO-OK\s*$/.test(text);

    const daDung = new Set();
    const ok = [], ngoaiKhoang = [], khongThay = [], doiSao = [];

    for (const m of muon) {
      const c = chuan(m.ten);
      const cm = chuanManh(m.ten);
      let dong = dang.find(d => !daDung.has(d) && chuan(d.ten) === c);
      if (!dong) dong = dang.find(d => !daDung.has(d) && chuanManh(d.ten) === cm);
      if (!dong) dong = dang.find(d => !daDung.has(d) &&
        (chuanManh(d.ten).includes(cm) || cm.includes(chuanManh(d.ten))));
      if (!dong) { khongThay.push(m); continue; }
      daDung.add(dong);

      // o nhap chi cho so nguyen thi lam tron
      const nguyen = dong.inp.getAttribute('inputmode') === 'numeric';
      const v = nguyen ? Math.round(m.so) : m.so;

      const cu = dong.inp.value;
      datGiaTri(dong.inp, v);

      // Dau sao: bat/tat cho khop voi cai do duoc tren anh.
      if (coDoSao && dong.nutSao && saoDangBat(dong.nutSao) !== !!m.sao) {
        bamThat(dong.nutSao);
        doiSao.push({ ten: dong.ten, bat: !!m.sao });
      }

      const reRange = (dong.min !== null && (m.so < dong.min || m.so > dong.max));
      if (reRange) ngoaiKhoang.push({ ...m, dong, v, cu });
      else ok.push({ ...m, dong, v, cu });
    }
    bao(ok, ngoaiKhoang, khongThay, '', doiSao);
  }

  // --- tu them dong affix ma trang khong dung ra ------------------------
  // Cai nay do duong, vi cau truc cai dropdown chua ai nhin thay.
  // Neu that bai thi bao ro, KHONG bam bua len trang.
  let loiThem = [];
  const doi = ms => new Promise(r => setTimeout(r, ms));

  async function cho(ham, hanMs) {
    const het = Date.now() + hanMs;
    while (Date.now() < het) {
      const v = ham();
      if (v) return v;
      await doi(120);
    }
    return null;
  }

  const nutThemAffix = () =>
    [...document.querySelectorAll('button')]
      .find(b => /add standard affixes/i.test((b.textContent || '').trim()));

  // Nut Add la mot Radix Popover. No noi thang ra trang thai cua no:
  //   aria-expanded / data-state  -> dang mo hay dang dong
  //   aria-controls               -> id cua dung cai khung dropdown
  // Nho vay khong phai do dam gi ca. Ban truoc do dam nen go nham vao
  // o 44% cua Unique Power.
  const dangMo = nut =>
    nut.getAttribute('aria-expanded') === 'true' || nut.getAttribute('data-state') === 'open';

  const khungPopover = nut => {
    const id = nut.getAttribute('aria-controls');
    return id ? document.getElementById(id) : null;
  };

  async function moDropdown(nut) {
    if (!dangMo(nut)) nut.click();
    return await cho(() => {
      const k = khungPopover(nut);
      return k && k.offsetParent !== null ? k : null;
    }, 3000);
  }

  // o loc nam TRONG khung dropdown, khong tim o ngoai
  const oTimTrongKhung = khung =>
    [...khung.querySelectorAll('input')].find(i =>
      i.type !== 'checkbox' && i.type !== 'file' && i.offsetParent !== null) || null;

  // Chi tim TRONG khung dropdown, khong quet ca trang - tranh bam nham
  // vao tooltip mon do (cho do cung co ten affix).

  // Moi dong trong danh sach la mot o tick, chu ghi kem khoang gia tri:
  //   "+[1 - 3] Imbuements Skills"
  // Uu tien the NAO CO O TICH ben trong; khong co thi lay the nho nhat
  // con chua du chu -> tranh bam trung vao khoi cha.
  function dongGoiY(khung, ten) {
    const c = chuanManh(ten);
    // Uu tien the NAO THUONG LA NUT BAM THAT truoc, roi moi den div/span boc ngoai.
    const hang = el =>
      (el.getAttribute('role') === 'option' || el.tagName === 'LI') ? 0
      : (el.tagName === 'LABEL' || el.tagName === 'BUTTON') ? 1
      : el.querySelector('input[type="checkbox"],[role="checkbox"]') ? 2 : 3;

    let tot = null, hangTot = 99, daiTot = 1e9;
    for (const el of khung.querySelectorAll('li,[role="option"],label,button,div,span')) {
      const t = (el.textContent || '').trim();
      if (!t || t.length > 80 || !chuanManh(t).includes(c)) continue;
      const h = hang(el);
      if (h < hangTot || (h === hangTot && t.length < daiTot)) {
        tot = el; hangTot = h; daiTot = t.length;
      }
    }
    return tot;
  }

  // Go chu vao o loc. Ngoai su kien input cua React con ban them su kien
  // ban phim, phong khi o loc nghe phim that chu khong nghe input.
  function goChu(o, chu) {
    o.focus();
    datGiaTri(o, chu);
    for (const loai of ['keydown', 'keypress', 'keyup']) {
      o.dispatchEvent(new KeyboardEvent(loai, {
        key: chu.slice(-1), bubbles: true, cancelable: true,
      }));
    }
  }

  // Danh sach co the chi ve phan dang nhin thay (cuon toi dau ve toi do).
  // Neu tim khong ra thi cuon dan xuong roi tim lai.
  async function doCuonTim(khung, ten) {
    const cuonDuoc = [...khung.querySelectorAll('*')].find(e =>
      e.scrollHeight > e.clientHeight + 40);
    if (!cuonDuoc) return null;
    for (let i = 0; i < 12; i++) {
      cuonDuoc.scrollTop = Math.round(cuonDuoc.scrollHeight * (i + 1) / 12);
      await doi(180);
      const g = dongGoiY(khung, ten);
      if (g) return g;
    }
    return null;
  }

  // Ke lai that ro rang no NHIN THAY gi, de con sua dung cho.
  function moTaThatBai(o, khung, tk) {
    const dong = [...khung.querySelectorAll('label,li,[role="option"]')]
      .map(e => (e.textContent || '').trim())
      .filter(t => t && t.length < 80);
    const soTich = khung.querySelectorAll('input[type="checkbox"],[role="checkbox"]').length;
    return 'go "' + tk + '" | o loc ghi "' + (o.getAttribute('placeholder') || '?') +
      '", sau khi go o co gia tri "' + o.value + '" | trong khung thay ' + soTich +
      ' o tich, ' + dong.length + ' dong' +
      (dong.length ? ': ' + dong.slice(0, 4).join(' / ') : ' nao ca');
  }

  // Bam nhu chuot THAT. el.click() chi phat mot su kien "click"; cac component
  // kieu Radix/cmdk lai nghe pointerdown/mousedown -> bam kieu cu khong an.
  // (Da gap that: dong "+[1 - 180] Willpower" hien ra, bam vao khong tich.)
  function bamThat(el) {
    const r = el.getBoundingClientRect();
    const x = r.left + r.width / 2, y = r.top + r.height / 2;
    const cn = { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y, button: 0 };
    const pt = Object.assign({}, cn, { pointerId: 1, isPrimary: true, pointerType: 'mouse' });
    try { el.scrollIntoView({ block: 'nearest' }); } catch (e) {}
    for (const [Loai, ten, o] of [
      [PointerEvent, 'pointerover', pt], [PointerEvent, 'pointerenter', pt],
      [MouseEvent, 'mouseover', cn], [MouseEvent, 'mousemove', cn],
      [PointerEvent, 'pointerdown', pt], [MouseEvent, 'mousedown', cn],
      [PointerEvent, 'pointerup', pt], [MouseEvent, 'mouseup', cn],
      [MouseEvent, 'click', cn],
    ]) {
      try { el.dispatchEvent(new Loai(ten, o)); } catch (e) {}
    }
  }

  // Co mat trong form chua? Dung de xac nhan sau moi lan thu.
  const daCoDong = ten =>
    timCacDong().some(d => chuanManh(d.ten) === chuanManh(ten)
      || chuanManh(d.ten).includes(chuanManh(ten)));

  // Go tu ngan nhung chac an: "Imbuements Skills" -> go "Imbuement".
  // Neu go nguyen ten ma OCR ra so it ("Imbuement Skills") thi bo loc cua
  // trang khong ra gi, vi nhan cua no la so nhieu ("Imbuements Skills").
  function tuKhoa(ten) {
    const dau = (ten.split(/\s+/)[0] || '').replace(/s$/i, '');
    return dau.length >= 3 ? dau : ten;
  }

  async function themCacAffixThieu(thieu) {
    loiThem = [];
    nhac('Dang thu them ' + thieu.length + ' dong...');
    for (const m of thieu) {
      const nut = nutThemAffix();
      if (!nut) { loiThem.push([m.ten, 'khong thay nut ADD STANDARD AFFIXES']); break; }

      const khung = await moDropdown(nut);
      if (!khung) { loiThem.push([m.ten, 'bam nut ADD roi ma dropdown khong mo ra']); continue; }

      const o = oTimTrongKhung(khung);
      if (!o) { loiThem.push([m.ten, 'dropdown mo roi nhung khong co o loc nao ben trong']); continue; }

      const tk = tuKhoa(m.ten);
      goChu(o, tk);
      await doi(700);

      let g = dongGoiY(khung, m.ten);
      if (!g) g = await doCuonTim(khung, m.ten);
      if (!g) { loiThem.push([m.ten, moTaThatBai(o, khung, tk)]); continue; }

      // Thu 3 duong, duong nao an thi dung. Sau moi duong deu KIEM LAI form
      // chu khong tin la da xong.
      const cach = [];
      const tick = g.querySelector('input[type="checkbox"],[role="checkbox"]');
      if (tick) cach.push(['bam thang vao o tich', () => bamThat(tick)]);
      cach.push(['bam vao ca dong', () => bamThat(g)]);
      cach.push(['go phim Enter o o loc', () => {
        o.focus();
        for (const loai of ['keydown', 'keypress', 'keyup'])
          o.dispatchEvent(new KeyboardEvent(loai, {
            key: 'Enter', code: 'Enter', keyCode: 13, which: 13,
            bubbles: true, cancelable: true,
          }));
      }]);

      let xong = false, daThu = [];
      for (const [ten, lam] of cach) {
        lam();
        xong = await cho(() => daCoDong(m.ten), 1600);
        if (xong) break;
        daThu.push(ten);
      }
      if (!xong)
        loiThem.push([m.ten, 'thay dong roi nhung khong chon duoc. Da thu: ' + daThu.join(', ')]);

      if (dangMo(nut)) bamThat(nut);   // dong dropdown lai cho gon
      await doi(400);
    }
    if (chuDaDan) apDung(chuDaDan, true);   // dien lai, lan nay co dong moi
  }

  // --- bao lech ten: KHONG ghi gi, hoi lai ------------------------------
  function baoLechTen(tenForm, tenChu, text) {
    const d = khungBao();
    d.innerHTML =
      '<b style="color:#d8b978">D4Lister</b>' +
      '<span id="d4l-dong" style="float:right;cursor:pointer;color:#888">&#10005;</span><br>' +
      '<div style="margin-top:6px;color:#e06a5a"><b>KHONG DIEN - sai mon do</b></div>' +
      '<div style="margin-top:6px">Form dang mo: <b>' + thoat(tenForm) + '</b></div>' +
      '<div>Chu vua dan : <b>' + thoat(tenChu) + '</b></div>' +
      '<div style="margin-top:8px;color:#aaa">Hai cai khac nhau nen khong ghi gi ca.</div>' +
      '<div style="margin-top:10px">' +
      '<button id="d4l-ep" style="background:#5a2020;color:#f0d0d0;border:1px solid #844;' +
      'border-radius:5px;padding:5px 10px;cursor:pointer;font:12px system-ui">Van cu dien</button>' +
      '<span style="color:#777;font-size:11px;margin-left:8px">chi bam neu ban chac</span></div>';
    d.querySelector('#d4l-dong').onclick = () => d.remove();
    d.querySelector('#d4l-ep').onclick = () => { d.remove(); apDung(text, true); };
  }

  const thoat = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));

  function khungBao() {
    document.getElementById('d4l-bao')?.remove();
    const d = document.createElement('div');
    d.id = 'd4l-bao';
    d.style.cssText = 'position:fixed;right:14px;bottom:14px;z-index:999999;max-width:460px;' +
      'max-height:70vh;overflow:auto;overflow-wrap:break-word;' +
      'background:#14141a;color:#eee;border:1px solid #444;border-radius:8px;padding:12px 14px;' +
      'font:13px/1.5 system-ui,sans-serif;box-shadow:0 8px 28px rgba(0,0,0,.6)';
    document.body.appendChild(d);
    return d;
  }

  // --- bang bao ket qua ------------------------------------------------
  function bao(ok, ngoai, thieu, loi, doiSao) {
    const d = khungBao();
    let h = '<b style="color:#d8b978">D4Lister</b> ';
    h += '<span id="d4l-dong" style="float:right;cursor:pointer;color:#888">&#10005;</span><br>';
    const ten = layTenItemTrenForm();
    if (ten) h += '<div style="color:#9aa;font-size:12px">' + thoat(ten) + '</div>';
    if (loi) h += '<span style="color:#e08a5a">' + loi + '</span>';
    // ok + ngoai DEU da duoc ghi vao o. Khac nhau o cho ngoai khung co ban.
    const daGhi = ok.concat(ngoai);
    if (daGhi.length) {
      h += '<div style="margin-top:6px;color:#7ec97e">Da dien ' + daGhi.length + ' dong:</div>';
      h += daGhi.map(x => '&nbsp;&nbsp;' + thoat(x.dong.ten) + ' = <b>' + x.v + '</b>' +
        (x.cu && String(x.cu) !== String(x.v)
          ? ' <span style="color:#777">(truoc: ' + thoat(x.cu) + ')</span>' : '')).join('<br>');
    }
    if (ngoai.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Vuot khung co ban cua trang:</div>';
      h += ngoai.map(x => '&nbsp;&nbsp;' + thoat(x.dong.ten) + ' = <b>' + x.v + '</b> (khung ' +
        x.dong.min + '-' + x.dong.max + ')').join('<br>');
      h += '<div style="color:#888;font-size:11px;margin-top:3px">Do masterwork thi binh thuong. ' +
        'Trang van nhan, chi to vien vang.</div>';
    }
    if (thieu.length) {
      h += '<div style="margin-top:8px;color:#e08a5a">Trang khong co dong nay:</div>';
      h += thieu.map(x => '&nbsp;&nbsp;' + thoat(x.ten) + ' = <b>' + x.so +
        (x.phanTram ? '%' : '') + '</b>').join('<br>');
      h += '<div style="margin-top:8px"><button id="d4l-them" style="background:#23402a;' +
        'color:#cfe8cf;border:1px solid #4a7a52;border-radius:5px;padding:5px 10px;cursor:pointer;' +
        'font:12px system-ui">Thu tu them</button>' +
        '<span style="color:#777;font-size:11px;margin-left:8px">hoac tu bam ADD STANDARD AFFIXES</span></div>';
    }
    if (doiSao && doiSao.length) {
      h += '<div style="margin-top:8px;color:#c9a227">Dau sao (Greater Affix):</div>';
      h += doiSao.map(x => '&nbsp;&nbsp;' + (x.bat ? 'BAT' : 'tat') + ' &mdash; ' +
        thoat(x.ten)).join('<br>');
    }
    if (loiThem.length) {
      h += '<div style="margin-top:8px;color:#e06a5a">Tu them khong duoc:</div>';
      h += loiThem.map(x => '&nbsp;&nbsp;' + thoat(x[0]) + ': ' + thoat(x[1])).join('<br>');
    }
    h += '<div style="margin-top:8px;color:#888;font-size:11px">Ctrl+Shift+D de chay lai</div>';
    d.innerHTML = h;
    d.querySelector('#d4l-dong').onclick = () => d.remove();
    const nt = d.querySelector('#d4l-them');
    if (nt) nt.onclick = () => themCacAffixThieu(thieu);
  }

  // --- bat su kien dan --------------------------------------------------
  document.addEventListener('paste', e => {
    const t = (e.clipboardData || window.clipboardData)?.getData('text/plain') || '';
    if (!t.trim()) return;
    chuDaDan = t;
    loiThem = [];          // lan dan moi -> xoa loi cu
    choFormDungXong(t);
  }, true);

  // Khong hen gio cung nhac nua: trang con bat bam SCAN roi moi dung form,
  // nhanh cham tuy luc. Cu ngo lien tuc den khi cac dong affix hien ra VA
  // so luong dung yen hai nhip -> luc do form moi thuc su xong.
  function choFormDungXong(text) {
    if (dongHo) clearInterval(dongHo);
    const batDau = Date.now();
    let truoc = -1, yen = 0;
    nhac('Da nhan chu. Dang doi form... (bam SCAN neu chua bam)');
    dongHo = setInterval(() => {
      const n = document.querySelectorAll('input[aria-label="Affix value"]').length;
      if (n > 0 && n === truoc) {
        if (++yen >= 2) { clearInterval(dongHo); dongHo = null; apDung(text); return; }
      } else {
        yen = 0;
      }
      truoc = n;
      if (Date.now() - batDau > CHO_TOI_DA) {
        clearInterval(dongHo); dongHo = null;
        bao([], [], [], 'Doi lau qua van chua thay dong affix nao. Bam SCAN roi bam Ctrl+Shift+D.');
      }
    }, NHIP_DO);
  }

  // dong nhac nho nho, tu tat
  function nhac(chu) {
    const d = khungBao();
    d.innerHTML = '<b style="color:#d8b978">D4Lister</b><br>' +
      '<span style="color:#9aa">' + thoat(chu) + '</span>';
  }

  // chay lai bang tay neu lo nhip
  document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.shiftKey && (e.key === 'D' || e.key === 'd')) {
      e.preventDefault();
      if (chuDaDan) apDung(chuDaDan);
      else bao([], [], [], 'Chua co chu nao trong bo nho. Hay Ctrl+V truoc.');
    }
  }, true);

  console.log('[D4Lister] userscript da nap');
})();
