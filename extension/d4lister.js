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

  const BAN = '1.1';          // doi cung luc voi version trong manifest.json
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

  // ====================================================================
  //  KHOP TEN AFFIX
  //
  //  diablo.trade la CHUAN, khong phai chu trong game. Hai ben viet khac nhau,
  //  cong them loi OCR, nen phai khop mem. Nhung mem kieu gi moi dung?
  //
  //  DO THAT tren 118 affix cua trang: cac affix KHAC HAN nhau lai giong nhau
  //  toi 0.92 neu so theo KY TU —
  //      core skills            vs  corpse skills          0.92
  //      cold damage multiplier vs  holy damage multiplier  0.91
  //  => khop o nguong 80% la bien Core thanh Corpse. Cai phan biet chung la
  //     MOT TU, ma phep so ky tu mu truoc chuyen do.
  //
  //  CACH DUNG: so THEO TU, moi tu cho sai vai ky tu tuy do dai.
  //  Do lai: loi OCR trong mot tu (Wilpower, Maximum Lite, Movement Speeb)
  //  deu ra 1.00; con core/corpse, cold/holy chi 0.50-0.67. Cap giong nhau
  //  nhat giua hai affix khac nhau la 0.80 -> nguong 0.95 rat an toan.
  // ====================================================================
  const DIEM_CHAC = 0.95;   // tu day tro len: chac chan, dung ngay
  const DIEM_NGO  = 0.80;   // 0.80-0.94: nghi ngo, dung lai hoi

  // Nhan cua trang co dang "+[1 - 180] Willpower" -> ten thuan la "Willpower"
  function tenThuan(nhan) {
    // Bo khoang gia tri "[1 - 180]" va cac dau dan "+ x # %".
    // KHONG duoc bo so tran: co affix ten that su bat dau bang so —
    // "100% Main Hand Weapon Damage" khac han "Main Hand Weapon Damage".
    let t = String(nhan || '').replace(/\[[^\]]*\]/g, ' ');
    t = t.replace(/^[\s+x#%]+/, '');
    return t.replace(/\s+/g, ' ').trim();
  }

  const tachTu = t =>
    tenThuan(t).toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter(Boolean);

  // Tu NGAN sai 1 ky tu la thanh tu KHAC HAN. Do that tren 638 affix cua
  // trang: Bash/Dash, Reap/Leap chi khac 1 ky tu ma la hai skill khac nhau;
  // Fireball/Firewall khac 2. Nen:
  //   tu <= 7 ky tu : KHONG cho sai
  //   tu >= 8 ky tu : cho sai 1   (du de cuu "Wilpower" -> "Willpower")
  const choPhep = w => (w.length >= 8 ? 1 : 0);

  // Khoang cach sua loi, bo cuoc som cho nhanh
  function khoangCach(a, b, toiDa) {
    if (Math.abs(a.length - b.length) > toiDa) return toiDa + 1;
    let truoc = [];
    for (let j = 0; j <= b.length; j++) truoc[j] = j;
    for (let i = 1; i <= a.length; i++) {
      const nay = [i];
      let nhoNhat = i;
      for (let j = 1; j <= b.length; j++) {
        nay[j] = Math.min(truoc[j] + 1, nay[j - 1] + 1,
                          truoc[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
        if (nay[j] < nhoNhat) nhoNhat = nay[j];
      }
      if (nhoNhat > toiDa) return toiDa + 1;
      truoc = nay;
    }
    return truoc[b.length];
  }

  function hopTu(x, y) {
    if (x === y) return true;
    const n = Math.max(choPhep(x), choPhep(y));
    return n > 0 && khoangCach(x, y, n) <= n;
  }

  // Diem 0..1 = bao nhieu phan tu khop duoc.
  //
  // Hai vong: vong dau chi nhan tu GIONG HET, vong sau moi cho sai.
  // Nho vay "Maximum Lite" van khop "Maximum Life" (tu "Maximum" giong het
  // lam chung cho "Lite"), nhung "Bash" khong the khop "Dash" — no tro troi
  // mot minh, khong co gi lam chung.
  function diemKhop(a, b) {
    const A = tachTu(a), B = tachTu(b);
    if (!A.length || !B.length) return 0;
    const con = B.slice();
    const conA = [];
    let khop = 0;

    for (const x of A) {                    // vong 1: giong het
      const i = con.indexOf(x);
      if (i >= 0) { khop++; con.splice(i, 1); } else conA.push(x);
    }
    // Co it nhat mot tu giong het -> cho phep tu ngan sai vai ky tu.
    const coChung = khop > 0;
    for (const x of conA) {                 // vong 2: cho sai
      for (let i = 0; i < con.length; i++) {
        const y = con[i];
        const n = coChung ? Math.max(1, choPhep(x), choPhep(y))
                          : Math.max(choPhep(x), choPhep(y));
        if (n <= 0 || khoangCach(x, y, n) > n) continue;

        // Tu TRO TROI mot minh (khong co tu nao lam chung) va DAI BANG NHAU
        // thi doi hoi giong het. Vi "Fireball" va "Firewall" cung 8 ky tu,
        // khac dung 1 ky tu — y het "Wilpower" -> "Willpower". Phan biet
        // duoc bang KIEU LOI: OCR nuot chu thi do dai doi, con hai ten khac
        // nhau thi thuong dai bang nhau.
        if (!coChung && x.length === y.length) continue;

        khop++; con.splice(i, 1); break;
      }
    }
    return khop / Math.max(A.length, B.length);
  }

  // Tim muc khop nhat trong mot danh sach. Tra ve ca diem NHI de biet co
  // nhap nhang khong - hai ung vien diem xap xi nhau la khong duoc doan bua.
  function timKhopNhat(tenCan, ds, layTen, boQua) {
    let tot = null, dTot = 0, dNhi = 0;
    for (const m of ds) {
      if (boQua && boQua.has(m)) continue;
      const r = diemKhop(tenCan, layTen ? layTen(m) : m);
      if (r > dTot) { dNhi = dTot; dTot = r; tot = m; }
      else if (r > dNhi) dNhi = r;
    }
    return { muc: tot, diem: dTot, nhi: dNhi };
  }

  // Thu vien 638 ten affix lay tu https://diablo.trade/wiki/affixes
  // (file affix-list.js, nap truoc file nay). Dung de biet mot ten OCR doc ra
  // co THAT SU ton tai khong — de bao cho dung ban chat.
  const THU_VIEN = (typeof D4L_AFFIX !== 'undefined' && D4L_AFFIX.length) ? D4L_AFFIX : [];

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
      bao([], [], [], 'Form chưa có món đồ nào. Bấm nút SCAN trước đã.');
      return;
    }

    // D4Lister chi gui dau hieu nay khi phan do dau sao THUC SU chay xong.
    // Khong co no (thieu Tesseract chang han) thi khong dung vao cong tac sao,
    // de khoi xoa nham dau sao ma trang da nhan dung.
    // Co co "m": dong #D4L-EXT nam SAU dong nay, nen khong the neo vao cuoi
    // ca chuoi duoc nua - thieu co "m" la phan do dau sao tat ngam.
    const coDoSao = /^#D4L-SAO-OK\s*$/m.test(text);

    // D4Lister gui kem so hieu ban tien ich DANG NAM TREN DIA. Lech voi ban
    // dang chay = Chrome van dung ban cu (no khong tu nap lai bao gio).
    const mExt = text.match(/#D4L-EXT:([0-9.]+)/);
    const banTrenDia = mExt ? mExt[1] : '';

    const daDung = new Set();
    const ok = [], ngoaiKhoang = [], khongThay = [], doiSao = [], nghiNgo = [];

    for (const m of muon) {
      // Khop theo TU. Ten cua DONG TREN FORM chinh la ten cua trang (doc tu
      // nut xoa "Remove ..."), nen day da la doi chieu voi chuan roi.
      const kq = timKhopNhat(m.ten, dang, d => d.ten, daDung);

      if (kq.diem < DIEM_NGO) {
        // Co ten nay trong thu vien khong? Neu co -> affix that, chi la trang
        // chua dung dong do ra. Neu khong -> nhieu kha nang OCR doc bay.
        const tv = THU_VIEN.length ? timKhopNhat(m.ten, THU_VIEN) : { diem: 0, muc: null };
        khongThay.push({ ...m, coThat: tv.diem >= DIEM_CHAC ? tv.muc : null });
        continue;
      }

      // Diem giua hai muc: co ve dung nhung khong chac. Doan bua o day la
      // tao listing sai ma khong ai biet -> dung lai, hoi.
      if (kq.diem < DIEM_CHAC || kq.nhi >= DIEM_CHAC) {
        nghiNgo.push({ ...m, dong: kq.muc, diem: kq.diem, nhi: kq.nhi });
        continue;
      }
      const dong = kq.muc;
      daDung.add(dong);

      // o nhap chi cho so nguyen thi lam tron
      const nguyen = dong.inp.getAttribute('inputmode') === 'numeric';
      const v = nguyen ? Math.round(m.so) : m.so;

      const cu = dong.inp.value;
      datGiaTri(dong.inp, v);

      // Dau sao: bat/tat cho khop voi cai do duoc tren anh.
      if (CD.tuDauSao && coDoSao && dong.nutSao && saoDangBat(dong.nutSao) !== !!m.sao) {
        bamThat(dong.nutSao);
        doiSao.push({ ten: dong.ten, bat: !!m.sao });
      }

      const reRange = (dong.min !== null && (m.so < dong.min || m.so > dong.max));
      if (reRange) ngoaiKhoang.push({ ...m, dong, v, cu });
      else ok.push({ ...m, dong, v, cu });
    }
    bao(ok, ngoaiKhoang, khongThay, '', doiSao, banTrenDia, nghiNgo);
  }

  // --- tu them dong affix ma trang khong dung ra ------------------------
  // Cai nay do duong, vi cau truc cai dropdown chua ai nhin thay.
  // Neu that bai thi bao ro, KHONG bam bua len trang.
  let loiThem = [];
  let daTuThem = false;   // moi lan dan chi tu them MOT lan
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
    // Uu tien the NAO THUONG LA NUT BAM THAT truoc, roi moi den div/span boc ngoai.
    const hang = el =>
      (el.getAttribute('role') === 'option' || el.tagName === 'LI') ? 0
      : (el.tagName === 'LABEL' || el.tagName === 'BUTTON') ? 1
      : el.querySelector('input[type="checkbox"],[role="checkbox"]') ? 2 : 3;

    const uv = [];
    for (const el of khung.querySelectorAll('li,[role="option"],label,button,div,span')) {
      const t = (el.textContent || '').trim();
      if (!t || t.length > 90) continue;
      const d = diemKhop(ten, t);
      if (d >= DIEM_NGO) uv.push({ el, t, d, h: hang(el) });
    }
    if (!uv.length) return null;

    // diem cao nhat truoc; cung diem thi lay the bam duoc that, roi the ngan nhat
    uv.sort((a, b) => b.d - a.d || a.h - b.h || a.t.length - b.t.length);
    const tot = uv[0];
    if (tot.d < DIEM_CHAC) return null;   // khong chac thi KHONG bam bua

    // Hai DONG KHAC NHAU cung dat diem cao -> nhap nhang, khong duoc doan.
    // (Nhieu the DOM boc cung mot dong thi chu giong nhau, khong tinh.)
    const khac = uv.find(x => x.d >= DIEM_CHAC && tenThuan(x.t) !== tenThuan(tot.t));
    if (khac) return null;

    return tot.el;
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
    return 'gõ "' + tk + '" | ô tìm ghi "' + (o.getAttribute('placeholder') || '?') +
      '", gõ xong ô chứa "' + o.value + '" | trong khung thấy ' + soTich +
      ' ô tích, ' + dong.length + ' dòng' +
      (dong.length ? ': ' + dong.slice(0, 4).join(' / ') : ' nào cả');
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
    nhac('Đang thêm ' + thieu.length + ' dòng còn thiếu…');
    for (const m of thieu) {
      const nut = nutThemAffix();
      if (!nut) { loiThem.push([m.ten, 'không thấy nút ADD STANDARD AFFIXES']); break; }

      const khung = await moDropdown(nut);
      if (!khung) { loiThem.push([m.ten, 'bấm nút ADD rồi mà danh sách không mở ra']); continue; }

      const o = oTimTrongKhung(khung);
      if (!o) { loiThem.push([m.ten, 'danh sách mở rồi nhưng không thấy ô tìm kiếm']); continue; }

      const tk = tuKhoa(m.ten);
      goChu(o, tk);
      await doi(700);

      let g = dongGoiY(khung, m.ten);
      if (!g) g = await doCuonTim(khung, m.ten);

      // Duong lui: co the chinh TU DEM DI LOC bi OCR doc sai ("Maxlmum"),
      // nen bo loc ra rong, khong co gi de cham diem. Xoa bo loc roi cuon
      // het danh sach ma tim. Cham hon vai giay, nhung hiem khi phai dung.
      if (!g) {
        goChu(o, '');
        await doi(600);
        g = dongGoiY(khung, m.ten) || await doCuonTim(khung, m.ten);
      }
      if (!g) { loiThem.push([m.ten, moTaThatBai(o, khung, tk)]); continue; }

      // Thu 3 duong, duong nao an thi dung. Sau moi duong deu KIEM LAI form
      // chu khong tin la da xong.
      const cach = [];
      const tick = g.querySelector('input[type="checkbox"],[role="checkbox"]');
      if (tick) cach.push(['bấm thẳng vào ô tích', () => bamThat(tick)]);
      cach.push(['bấm vào cả dòng', () => bamThat(g)]);
      cach.push(['gõ Enter ở ô tìm', () => {
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
        loiThem.push([m.ten, 'thấy dòng rồi nhưng không chọn được. Đã thử: ' + daThu.join(', ')]);

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
      '<div style="margin-top:6px;color:#e06a5a"><b>Dừng lại — không đúng món đồ</b></div>' +
      '<div style="margin-top:6px">Form đang mở: <b>' + thoat(tenForm) + '</b></div>' +
      '<div>Chữ vừa dán: <b>' + thoat(tenChu) + '</b></div>' +
      '<div style="margin-top:8px;color:#aaa">Hai tên khác nhau nên chưa ghi gì cả.</div>' +
      '<div style="margin-top:10px">' +
      '<button id="d4l-ep" style="background:#5a2020;color:#f0d0d0;border:1px solid #844;' +
      'border-radius:5px;padding:5px 10px;cursor:pointer;font:12px system-ui">Vẫn cứ điền</button>' +
      '<span style="color:#777;font-size:11px;margin-left:8px">chỉ bấm nếu bạn chắc</span></div>';
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

  // --- HỌC DANH SÁCH AFFIX CỦA TRANG ------------------------------------
  //  diablo.trade mới là chuẩn, không phải chữ trong game. Tên trong game và
  //  tên trên trang lệch nhau khá nhiều, nên phải có danh sách thật của trang
  //  để đối chiếu.
  //
  //  Danh sách này trang tải từ máy chủ lúc chạy, và KHÁC NHAU theo từng loại
  //  đồ (mũ khác dây chuyền). Nên gom theo loại đồ.
  async function hocDanhSach() {
    const nut = nutThemAffix();
    if (!nut) { nhac('Không thấy nút ADD STANDARD AFFIXES. Mở một món đồ ra đã.'); return; }
    nhac('Đang đọc danh sách affix của trang…');

    const khung = await moDropdown(nut);
    if (!khung) { nhac('Không mở được danh sách.'); return; }
    const o = oTimTrongKhung(khung);
    if (o) { goChu(o, ''); await doi(600); }   // xoá bộ lọc để hiện hết

    // Danh sách chỉ vẽ phần nhìn thấy -> phải cuộn dần mà gom
    const ten = new Set();
    const gom = () => {
      for (const el of khung.querySelectorAll('label,li,[role="option"]')) {
        const t = (el.textContent || '').trim();
        if (t && t.length < 90 && /[A-Za-z]{3}/.test(t)) ten.add(t);
      }
    };
    gom();
    const cuon = [...khung.querySelectorAll('*')].find(e => e.scrollHeight > e.clientHeight + 40);
    if (cuon) {
      const buoc = Math.max(40, cuon.clientHeight - 30);
      for (let y = 0; y <= cuon.scrollHeight; y += buoc) {
        cuon.scrollTop = y;
        await doi(130);
        gom();
      }
      cuon.scrollTop = 0;
    }
    if (dangMo(nut)) bamThat(nut);

    const loai = layLoaiDo();
    const ds = [...ten].sort();
    let kho = {};
    try { kho = JSON.parse(localStorage.getItem('d4lister-affix') || '{}'); } catch (e) {}
    kho[loai] = ds;
    try { localStorage.setItem('d4lister-affix', JSON.stringify(kho)); } catch (e) {}

    const d = khungBao();
    d.innerHTML =
      '<b style="color:#d8b978">Đã đọc xong danh sách</b>' +
      '<span id="d4l-dong" style="float:right;cursor:pointer;color:#888">&#10005;</span>' +
      '<div style="margin-top:6px">Loại đồ: <b>' + thoat(loai) + '</b></div>' +
      '<div>Số affix đọc được: <b>' + ds.length + '</b></div>' +
      '<div style="margin-top:6px;color:#888;font-size:11px">Đã lưu. Mở thêm món khác loại ' +
      'rồi bấm lại để gom đủ.</div>' +
      '<div style="margin-top:10px"><button id="d4l-chep" style="background:#23402a;' +
      'color:#cfe8cf;border:1px solid #4a7a52;border-radius:5px;padding:6px 10px;' +
      'cursor:pointer;font:12px system-ui">Chép cả kho ra clipboard</button></div>';
    d.querySelector('#d4l-dong').onclick = () => d.remove();
    d.querySelector('#d4l-chep').onclick = () => {
      const chu = JSON.stringify(kho, null, 1);
      navigator.clipboard.writeText(chu).then(
        () => nhac('Đã chép ' + Object.keys(kho).length + ' loại đồ ra clipboard.'),
        () => nhac('Chép không được. Bấm F12 → Console để xem.'));
      console.log('[D4Lister] kho affix:', kho);
    };
  }

  // Loại đồ đang mở: "Helm", "Amulet"... Lấy từ dòng loại dưới tên món.
  function layLoaiDo() {
    // Di nguoc len tu tieu de mon do cho toi khoi CO CA "Item Power" - do moi
    // la ca cai tooltip. Ban truoc chi len 2 tang nen cat mat dong loai do.
    let khoi = document.querySelector('[class*="font-tooltip-title"]');
    for (let i = 0; i < 8 && khoi; i++) {
      if (/item power/i.test(khoi.textContent || '')) break;
      khoi = khoi.parentElement;
    }
    const t = (khoi ? khoi.textContent : document.body.textContent) || '';
    const m = t.match(
      /(?:Ancestral|Sacred)?\s*(?:Unique|Legendary|Rare|Magic|Mythic|Common)\s+([A-Za-z][A-Za-z ]{2,22}?)\s*\d*\s*Item Power/i);
    return m ? m[1].trim() : 'khong-ro';
  }

  // --- BẢNG THIẾT LẬP ---------------------------------------------------
  //  Bấm vào chip góc dưới bên trái là mở ra. Lưu trong trình duyệt nên
  //  đổi xong là dùng ngay, không phải sửa file, không phải nạp lại.
  function moThietLap() {
    document.getElementById('d4l-tl')?.remove();
    const d = document.createElement('div');
    d.id = 'd4l-tl';
    d.style.cssText = 'position:fixed;left:12px;bottom:46px;z-index:999999;width:320px;' +
      'background:#14141a;color:#eee;border:1px solid #444;border-radius:8px;padding:12px 14px;' +
      'font:13px/1.5 system-ui,sans-serif;box-shadow:0 8px 28px rgba(0,0,0,.6)';

    const o = (khoa, nhan, ghiChu) =>
      '<label style="display:flex;gap:8px;align-items:flex-start;margin-top:9px;cursor:pointer">' +
      '<input type="checkbox" data-k="' + khoa + '"' + (CD[khoa] ? ' checked' : '') +
      ' style="margin-top:3px">' +
      '<span><b>' + nhan + '</b>' +
      (ghiChu ? '<br><span style="color:#888;font-size:11px">' + ghiChu + '</span>' : '') +
      '</span></label>';

    d.innerHTML =
      '<b style="color:#d8b978">Thiết lập D4Lister</b>' +
      '<span id="d4l-tl-dong" style="float:right;cursor:pointer;color:#888">&#10005;</span>' +
      o('tuDang', 'Tự đăng', 'Điền xong, mọi thứ sạch thì tự bấm SUBMIT.') +
      o('dangCaKhiCanhBao', 'Đăng cả khi có cảnh báo',
        'Nguy hiểm: số sai vẫn lên sàn mà bạn không biết.') +
      o('tuThemAffix', 'Tự thêm affix thiếu',
        'Trang không dựng ra dòng nào thì tự mở danh sách thêm vào.') +
      o('tuDauSao', 'Tự bật dấu sao', 'Greater Affix — đo bằng pixel từ ảnh chụp.') +
      '<div style="margin-top:12px;display:flex;align-items:center;gap:8px">' +
      '<span>Đếm ngược</span>' +
      '<input id="d4l-tl-giay" type="number" min="1" max="60" value="' + (CD.demNguoc | 0) + '"' +
      ' style="width:56px;background:#0d0d12;color:#eee;border:1px solid #555;border-radius:4px;' +
      'padding:3px 6px;font:13px system-ui">' +
      '<span>giây trước khi đăng</span></div>' +
      '<div style="margin-top:12px;border-top:1px solid #333;padding-top:10px">' +
      '<button id="d4l-tl-hoc" style="width:100%;background:#22303f;color:#bcd8ee;' +
      'border:1px solid #3d5f7d;border-radius:5px;padding:6px 10px;cursor:pointer;' +
      'font:12px system-ui">Đọc danh sách affix của trang</button>' +
      '<div style="color:#888;font-size:11px;margin-top:4px">Mở một món đồ ra rồi bấm. ' +
      'Dùng để khớp tên cho đúng với trang.</div></div>' +
      '<div style="margin-top:12px;display:flex;gap:8px">' +
      '<button id="d4l-tl-luu" style="flex:1;background:#23402a;color:#cfe8cf;border:1px solid #4a7a52;' +
      'border-radius:5px;padding:6px 10px;cursor:pointer;font:12px system-ui">Lưu</button>' +
      '<button id="d4l-tl-goc" style="background:#2a2a32;color:#bbb;border:1px solid #555;' +
      'border-radius:5px;padding:6px 10px;cursor:pointer;font:12px system-ui">Về mặc định</button>' +
      '</div>';
    document.body.appendChild(d);

    d.querySelector('#d4l-tl-dong').onclick = () => d.remove();
    d.querySelector('#d4l-tl-hoc').onclick = () => { d.remove(); hocDanhSach(); };
    d.querySelector('#d4l-tl-luu').onclick = () => {
      d.querySelectorAll('input[type=checkbox]').forEach(i => { CD[i.dataset.k] = i.checked; });
      const g = parseInt(d.querySelector('#d4l-tl-giay').value, 10);
      if (g >= 1 && g <= 60) CD.demNguoc = g;
      luuCaiDat();
      d.remove();
      nhac('Đã lưu thiết lập.');
      setTimeout(() => document.getElementById('d4l-bao')?.remove(), 1800);
    };
    d.querySelector('#d4l-tl-goc').onclick = () => {
      CD = Object.assign({}, MAC_DINH);
      luuCaiDat();
      d.remove();
      moThietLap();
    };
  }

  // --- TỰ ĐĂNG ----------------------------------------------------------
  //  Mặc định chỉ tự đăng khi MỌI THỨ SẠCH: không dòng nào vượt khoảng, không
  //  thiếu affix, không lỗi. Có cảnh báo thì dừng lại và hỏi.
  //
  //  Lý do có cái chốt này: đã đo được là trang có thể âm thầm đổi số (12.5
  //  thành 10 mà không báo gì), và OCR cũng có lúc đọc sai. Đăng bừa thì món
  //  hàng lên sàn với chỉ số sai mà không ai biết.
  //
  //  Muốn đăng tất bằng mọi giá: đổi DANG_CA_KHI_CANH_BAO thành true.
  //  Muốn tắt hẳn tự đăng:       đổi TU_DANG thành false.
  const MAC_DINH = {
    tuDang:           true,   // tự bấm SUBMIT khi mọi thứ sạch
    dangCaKhiCanhBao: false,  // đăng cả khi có cảnh báo
    demNguoc:         5,      // giây đếm ngược trước khi bấm đăng
    tuThemAffix:      true,   // tự thêm dòng affix trang không dựng ra
    tuDauSao:         true,   // tự bật/tắt dấu sao Greater Affix
  };
  const KHOA_LUU = 'd4lister-cai-dat';

  // Lưu trong trình duyệt, theo từng máy. Chặn lỗi vì chế độ ẩn danh hoặc
  // trình duyệt khoá bộ nhớ trang thì đọc/ghi đều ném lỗi.
  function docCaiDat() {
    try {
      const t = localStorage.getItem(KHOA_LUU);
      return t ? Object.assign({}, MAC_DINH, JSON.parse(t)) : Object.assign({}, MAC_DINH);
    } catch (e) { return Object.assign({}, MAC_DINH); }
  }
  function luuCaiDat() {
    try { localStorage.setItem(KHOA_LUU, JSON.stringify(CD)); } catch (e) {}
  }
  let CD = docCaiDat();

  let dongHoDang = null;

  const nutDang = () =>
    [...document.querySelectorAll('button')]
      .find(b => /^\+?\s*submit\s*$/i.test((b.textContent || '').trim()));

  function huyDang(el, viSao) {
    if (dongHoDang) { clearInterval(dongHoDang); dongHoDang = null; }
    if (el) el.innerHTML = '<span style="color:#888;font-size:12px">' + thoat(viSao) + '</span>';
  }

  function xetTuDang(el, sach) {
    if (!el) return;
    if (dongHoDang) { clearInterval(dongHoDang); dongHoDang = null; }

    if (!CD.tuDang) {
      el.innerHTML = '<span style="color:#888;font-size:12px">Tự đăng đang tắt.</span>';
      return;
    }
    const nut = nutDang();
    if (!nut) {
      el.innerHTML = '<span style="color:#888;font-size:12px">Không thấy nút Submit.</span>';
      return;
    }
    if (!sach && !CD.dangCaKhiCanhBao) {
      el.innerHTML =
        '<div style="color:#e8c05a;font-size:12px">Không tự đăng — xem mấy dòng cảnh báo ở trên.</div>' +
        '<button id="d4l-dangluon" style="margin-top:6px;background:#3a3a22;color:#e8e0c0;' +
        'border:1px solid #7a6a30;border-radius:5px;padding:5px 10px;cursor:pointer;' +
        'font:12px system-ui">Cứ đăng</button>';
      el.querySelector('#d4l-dangluon').onclick = () => { bamThat(nut); huyDang(el, 'Đã bấm đăng.'); };
      return;
    }

    let con = Math.max(1, CD.demNguoc | 0);
    const ve = () => {
      el.innerHTML =
        '<div style="color:#7ec97e;font-size:13px">Tự đăng sau <b>' + con + '</b> giây…</div>' +
        '<div style="color:#888;font-size:11px;margin-top:2px">Bấm Esc, hoặc gõ vào ô giá, để dừng.</div>' +
        '<button id="d4l-dung" style="margin-top:6px;background:#3a2020;color:#f0d0d0;' +
        'border:1px solid #844;border-radius:5px;padding:4px 10px;cursor:pointer;' +
        'font:12px system-ui">Dừng</button>';
      const b = el.querySelector('#d4l-dung');
      if (b) b.onclick = () => huyDang(el, 'Đã dừng. Bạn tự bấm Submit.');
    };
    ve();
    dongHoDang = setInterval(() => {
      con--;
      if (con > 0) { ve(); return; }
      clearInterval(dongHoDang); dongHoDang = null;
      bamThat(nut);
      el.innerHTML = '<span style="color:#7ec97e;font-size:13px">Đã đăng. Bấm F5 để sang món kế.</span>';
    }, 1000);
  }

  document.addEventListener('keydown', e => {
    // Ctrl+Enter = đăng ngay. Dùng khi bạn vừa gõ giá xong: gõ phím làm dừng
    // đếm ngược, nên cần một phím để nói "tôi xong rồi, đăng đi".
    if (e.ctrlKey && e.key === 'Enter') {
      const nut = nutDang();
      if (!nut) return;
      e.preventDefault();
      huyDang(document.getElementById('d4l-dang'), 'Đã bấm đăng.');
      bamThat(nut);
      return;
    }
    // Esc hoặc gõ phím bất kỳ (kể cả gõ giá) thì dừng đếm ngược.
    if (!dongHoDang) return;
    const el = document.getElementById('d4l-dang');
    huyDang(el, e.key === 'Escape'
      ? 'Đã dừng. Bấm Ctrl+Enter khi muốn đăng.'
      : 'Đã dừng vì bạn đang gõ. Gõ xong bấm Ctrl+Enter để đăng.');
  }, true);

  // --- bang bao ket qua ------------------------------------------------
  function bao(ok, ngoai, thieu, loi, doiSao, banTrenDia, nghiNgo) {
    const d = khungBao();
    let h = '<b style="color:#d8b978">D4Lister</b> ';
    h += '<span id="d4l-dong" style="float:right;cursor:pointer;color:#888">&#10005;</span><br>';
    const ten = layTenItemTrenForm();
    if (ten) h += '<div style="color:#9aa;font-size:12px">' + thoat(ten) + '</div>';
    if (loi) h += '<span style="color:#e08a5a">' + loi + '</span>';
    // ok + ngoai DEU da duoc ghi vao o. Khac nhau o cho ngoai khung co ban.
    const daGhi = ok.concat(ngoai);
    if (daGhi.length) {
      h += '<div style="margin-top:6px;color:#7ec97e">Đã điền ' + daGhi.length + ' dòng</div>';
      h += daGhi.map(x => '&nbsp;&nbsp;' + thoat(x.dong.ten) + ' = <b>' + x.v + '</b>' +
        (x.cu && String(x.cu) !== String(x.v)
          ? ' <span style="color:#777">(trước đó: ' + thoat(x.cu) + ')</span>' : '')).join('<br>');
    }
    if (ngoai.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Cao hơn khoảng thường của trang</div>';
      h += ngoai.map(x => '&nbsp;&nbsp;' + thoat(x.dong.ten) + ' = <b>' + x.v + '</b> ' +
        '<span style="color:#888">(trang ghi ' + x.dong.min + '–' + x.dong.max + ')</span>').join('<br>');
      h += '<div style="color:#888;font-size:11px;margin-top:3px">Đồ masterwork thì bình thường. ' +
        'Trang vẫn nhận, chỉ tô viền vàng.</div>';
    }
    if (nghiNgo && nghiNgo.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Không chắc — bạn xem giúp</div>';
      h += nghiNgo.map(x =>
        '&nbsp;&nbsp;' + thoat(x.ten) + ' = <b>' + x.so + (x.phanTram ? '%' : '') + '</b>' +
        '<br>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#888">giống nhất: ' +
        thoat(x.dong ? x.dong.ten : '?') + ' (' + Math.round(x.diem * 100) + '%)</span>'
      ).join('<br>');
      h += '<div style="color:#888;font-size:11px;margin-top:3px">Chưa điền mấy dòng này. ' +
        'Đoán bừa ở đây là đăng nhầm chỉ số.</div>';
    }
    if (thieu.length) {
      const coThat = thieu.filter(x => x.coThat);
      const laRac  = thieu.filter(x => !x.coThat);
      if (coThat.length) {
        h += '<div style="margin-top:8px;color:#e08a5a">Trang chưa có dòng này</div>';
        h += coThat.map(x => '&nbsp;&nbsp;' + thoat(x.coThat) + ' = <b>' + x.so +
          (x.phanTram ? '%' : '') + '</b>').join('<br>');
      }
      if (laRac.length) {
        h += '<div style="margin-top:8px;color:#e06a5a">Không có affix nào tên như vậy</div>';
        h += laRac.map(x => '&nbsp;&nbsp;' + thoat(x.ten) + ' = <b>' + x.so +
          (x.phanTram ? '%' : '') + '</b>').join('<br>');
        h += '<div style="color:#888;font-size:11px;margin-top:3px">Nhiều khả năng ' +
          'chụp thiếu hoặc OCR đọc sai. Chụp lại món này xem sao.</div>';
      }
      h += '<div style="margin-top:8px"><button id="d4l-them" style="background:#23402a;' +
        'color:#cfe8cf;border:1px solid #4a7a52;border-radius:5px;padding:5px 10px;cursor:pointer;' +
        'font:12px system-ui">Thêm giúp tôi</button>' +
        '<span style="color:#777;font-size:11px;margin-left:8px">hoặc tự bấm ADD STANDARD AFFIXES</span></div>';
    }
    if (doiSao && doiSao.length) {
      h += '<div style="margin-top:8px;color:#c9a227">Dấu sao (Greater Affix)</div>';
      h += doiSao.map(x => '&nbsp;&nbsp;' + (x.bat ? 'bật' : 'tắt') + ' — ' +
        thoat(x.ten)).join('<br>');
    }
    if (loiThem.length) {
      h += '<div style="margin-top:8px;color:#e06a5a">Thêm không được</div>';
      h += loiThem.map(x => '&nbsp;&nbsp;' + thoat(x[0]) + ': ' + thoat(x[1])).join('<br>');
    }

    // Ban tren dia moi hon ban dang chay -> Chrome chua nap lai.
    if (banTrenDia && banTrenDia !== BAN) {
      h = '<div style="background:#4a1f1f;border:1px solid #a04040;border-radius:6px;' +
          'padding:8px 10px;margin-bottom:10px">' +
          '<b style="color:#ffb0b0">Tiện ích đang chạy bản cũ</b><br>' +
          '<span style="font-size:12px;color:#e8c0c0">Đang chạy <b>' + thoat(BAN) +
          '</b>, trên đĩa đã là <b>' + thoat(banTrenDia) + '</b>.<br>' +
          'Vào <b>chrome://extensions</b> bấm nút xoay vòng trên ô D4Lister, rồi F5 trang này.' +
          '</span></div>' + h;
    }

    // chỗ dành cho phần đếm ngược tự đăng
    h += '<div id="d4l-dang" style="margin-top:10px"></div>';
    h += '<div style="margin-top:8px;color:#888;font-size:11px">Ctrl+Shift+D để chạy lại</div>';
    d.innerHTML = h;
    d.querySelector('#d4l-dong').onclick = () => d.remove();
    const nt = d.querySelector('#d4l-them');
    if (nt) nt.onclick = () => themCacAffixThieu(thieu);

    // Sạch = không có dòng nào vượt khoảng, không thiếu affix, không lỗi.
    const sach = !ngoai.length && !thieu.length && !loiThem.length && !loi
               && !(nghiNgo && nghiNgo.length) && daGhi.length > 0;

    // Thiếu affix mà bật tự thêm -> thêm luôn, khỏi bấm nút.
    // CHỈ MỘT LẦN cho mỗi lần dán: thêm không được thì `thieu` vẫn còn,
    // không chặn thì nó gọi lại chính nó mãi mãi.
    if (CD.tuThemAffix && thieu.length && !daTuThem) {
      daTuThem = true;
      themCacAffixThieu(thieu);   // xong sẽ tự gọi lại apDung -> vẽ lại bảng
      return;
    }
    xetTuDang(d.querySelector('#d4l-dang'), sach);
  }

  // --- bat su kien dan --------------------------------------------------
  document.addEventListener('paste', e => {
    const t = (e.clipboardData || window.clipboardData)?.getData('text/plain') || '';
    if (!t.trim()) return;
    chuDaDan = t;
    loiThem = [];          // lan dan moi -> xoa loi cu
    daTuThem = false;
    choFormDungXong(t);
  }, true);

  // Khong hen gio cung nhac nua: trang con bat bam SCAN roi moi dung form,
  // nhanh cham tuy luc. Cu ngo lien tuc den khi cac dong affix hien ra VA
  // so luong dung yen hai nhip -> luc do form moi thuc su xong.
  function choFormDungXong(text) {
    if (dongHo) clearInterval(dongHo);
    const batDau = Date.now();
    let truoc = -1, yen = 0;
    nhac('Đã nhận chữ. Đang đợi form… (chưa bấm SCAN thì bấm đi)');
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
        bao([], [], [], 'Đợi lâu quá vẫn chưa thấy dòng affix nào. Bấm SCAN rồi bấm Ctrl+Shift+D.');
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
      else bao([], [], [], 'Chưa có dữ liệu món đồ. Bấm Ctrl+V trước đã.');
    }
  }, true);

  // Bao co mat ngay khi nap, de khoi phai mo DevTools moi biet no co vao
  // trang hay khong. Tu bien mat sau 2,5 giay.
  // ------------------------------------------------------------------
  //  DAU HIEU SONG - o lai vinh vien o goc duoi ben TRAI.
  //
  //  diablo.trade la ung dung mot trang: bam sang muc khac la React dung
  //  lai toan bo noi dung va XOA LUON the nay. Bo bat su kien thi van song
  //  (no gan vao document), nhung thu nhin thay duoc thi mat -> trong nhu
  //  la tien ich chet. Nen phai tu gan lai khi bi xoa.
  // ------------------------------------------------------------------
  console.log('[D4Lister] da nap - ban ' + BAN);

  let chip = null;
  function dungChip() {
    const c = document.createElement('div');
    c.id = 'd4l-chip';
    c.textContent = 'D4Lister ' + BAN;
    c.title = 'D4Lister đang chạy. Bấm để mở thiết lập.';
    c.onmouseenter = () => c.style.opacity = '1';
    c.onmouseleave = () => c.style.opacity = '.55';
    c.onclick = moThietLap;
    c.style.cssText = 'position:fixed;left:12px;bottom:12px;z-index:999998;' +
      'background:rgba(20,52,26,.85);color:#9fe0a0;border:1px solid #3a7a44;' +
      'border-radius:999px;padding:3px 10px;font:11px system-ui,sans-serif;' +
      'cursor:pointer;user-select:none;opacity:.55;transition:opacity .3s';
    return c;
  }
  function giuChip() {
    if (!document.body) return;
    if (chip && document.body.contains(chip)) return;
    chip = dungChip();
    document.body.appendChild(chip);
  }
  giuChip();
  document.addEventListener('DOMContentLoaded', giuChip);
  // React dung lai trang thi gan lai. 2 giay mot lan, nhe khong dang ke.
  setInterval(giuChip, 2000);

})();
