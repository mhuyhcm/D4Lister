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

  const BAN = '2.5';          // doi cung luc voi version trong manifest.json
  const NHIP_DO   = 500;     // ms giua hai lan ngo xem form da dung xong chua
  const CHO_TOI_DA = 120000; // ms bo cuoc neu mai khong thay dong affix nao
  let chuDaDan = '';
  let dongHo = null;

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
    // CLASSIC viet cho trong bang ngoac tron: "+(0) Strength",
    // "x(0)% Critical Strike Damage Multiplier".
    t = t.replace(/\(\s*[\d.,\s–—-]*\s*\)/g, ' ');
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
  // Chi con chu va so, bo het dau cach. OCR font nay hay NUOT DAU CACH:
  // "LifeonKill", "AllSkills", "MaximumLife". DO DUOC: bo het dau cach thi
  // ca 638 ten cua trang VAN KHAC NHAU (0 cap trung), va "CoreSkills" van
  // khac "CorpseSkills" - nen so kieu nay an toan, mien la GIONG HET.
  const lienChu = t => tenThuan(t).toLowerCase().replace(/[^a-z0-9]/g, '');

  function diemKhop(a, b) {
    const A = tachTu(a), B = tachTu(b);
    if (!A.length || !B.length) return 0;

    // Nuot dau cach: chap lien lai ma giong het thi chac chan la mot.
    const la = lienChu(a);
    if (la && la === lienChu(b)) return 1;

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
    // "812 Armor" la giap GOC cua mon do — bo. Con "+56 Armor" la affix
    // that (trang cung co ten nay) — phai giu. Khac nhau o CHO CO DAU.
    /item power/i, /^[\d.,]+\s*armor\b/i, /toughness/i,
    /^requires level/i, /empty socket/i,
    // Ba dong CHI SO GOC cua vu khi. User khong dung den, ma de vao thi lan
    // nao cung bao "trang chua co dong nay" — bao sai chu khong bat duoc gi.
    /^damage per second/i, /damage per hit/i, /^attacks per second/i,
    // Khu o ngoc: OCR hay nha ra rac tu may cai hinh o ("7NE Sock").
    // Thu vien 638 ten khong co affix nao chua chu "socket" ca.
    /sock/i, /scroll down/i,
    /unlocks new look/i, /sell value/i, /durability/i, /tempers?\s*:/i,
    /unique equipped/i, /lord of hatred/i,
    // Chi so GOC cua day chuyen/nhan. Ten that cua affix la
    // "Resistance to All Elements", KHAC han - nen chan cai nay an toan.
    /\ball resist\b/i,
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
      // "+1,813 Maximum Life" | "x25% Critical Strike Damage Multiplier"
      // | "+282LifeonKill" | "173 All Resist"
      //
      // Hai cho tung de LOT DONG, deu im lang:
      //   - Dau "x": MOI affix Damage Multiplier trong D4 deu viet "x25%",
      //     ma regex cu chi nhan dau "+".
      //   - Giua so va chu CO KHI KHONG CO DAU CACH ("+282LifeonKill"),
      //     nen phai la \s* chu khong phai \s+. Doi lai bat buoc ten phai
      //     bat dau bang CHU CAI, de khong vo nham vao so.
      const m = d2.match(/^([+x])?\s*([\d.,]+)\s*(%?)\s*([A-Za-z].*)$/i);
      if (!m) continue;
      const dauSo = (m[1] || '').toLowerCase();   // '+' | 'x' | ''
      const so = parseFloat(m[2].replace(/,/g, ''));
      if (!isFinite(so)) continue;
      let ten = m[4].replace(/^to\s+/i, '').trim();
      if (!ten || ten.length < 3) continue;
      // Do CA dong goc LAN ten da tach. Co dong chi lo ra o ten: "1,234
      // Damage Per Second" khong khop "^damage per second", nhung ten thi co.
      if (BO_QUA.some(r => r.test(d2) || r.test(ten))) continue;
      ra.push({ ten, so, phanTram: m[3] === '%', nhan: dauSo, sao });
    }
    return ra;
  }

  // ====================================================================
  //  HAI CHE DO CUA TRANG: CLASSIC va BETA
  //
  //  Goc tren ben phai trang Create co cong tac doi CLASSIC / BETA. Hai ban
  //  ve form KHAC HAN nhau, nen moi lan dung den DOM deu phai hoi lai dang
  //  o ban nao — user doi qua doi lai duoc, khong tai lai trang.
  //
  //  Nhan dang bang PHAN TU THAT, khong dem chu: goi ngon ngu cua trang co
  //  du ca hai chuoi ("Affix value", "Remove attribute") o ca hai che do.
  // ====================================================================
  function cheDo() {
    if (document.querySelector('button[title="Remove attribute"]')) return 'classic';
    if (document.querySelector('input[aria-label="Affix value"]')) return 'beta';
    // form con trong: chi con o "+ ADD AFFIX" de nhan ra CLASSIC
    if (document.querySelector('input[cmdk-input][placeholder*="ADD AFFIX"]')) return 'classic';
    return 'beta';
  }

  // Mot dong affix cua CLASSIC la mot the div chua dung nam thu anh em:
  //   nut sao (role=checkbox) | nut xoa | o so | span ten | nut sua
  // Doi phai co NUT XOA thi moi tinh la dong affix — nho vay o "%" cua
  // Unique Power (cung la input[inputmode=decimal]) tu dong bi loai ra.
  function dongClassic() {
    const ra = [];
    for (const nutXoa of document.querySelectorAll('button[title="Remove attribute"]')) {
      const khoi = nutXoa.parentElement;
      if (!khoi) continue;
      const inp = khoi.querySelector('input[inputmode="decimal"]');
      if (!inp) continue;
      const sp = [...khoi.children].find(e => e.tagName === 'SPAN');
      const ten = tenThuan(sp ? sp.textContent : '');
      if (!ten) continue;
      const nutSao = [...khoi.querySelectorAll('button[role="checkbox"]')]
        .find(b => b.querySelector('img[alt="Greater Affix"]')) || null;
      // CLASSIC khong nhung khoang hop le vao DOM — doc nguoc tu cau canh
      // bao cua trang, xem docCanhBaoNgoai() ben duoi.
      ra.push({ ten, inp, min: null, max: null, nutSao, khoi });
    }
    return ra;
  }

  // CLASSIC bao vuot khoang bang mot cau chu:
  //   "Willpower: 250 is outside its 1-180 roll range."
  // Doc lai cau do de biet dong nao vuot va khoang dung la bao nhieu.
  const RE_NGOAI =
    /([A-Za-z][A-Za-z0-9 %+'\-]{2,60}?):\s*([\d.,]+)\s+is outside its\s*([\d.,]+)\s*[–—-]\s*([\d.,]+)\s*roll range/i;

  function docCanhBaoNgoai() {
    const ra = [], da = new Set();
    const xet = chu => {
      const m = String(chu || '').match(RE_NGOAI);
      if (!m) return;
      const ten = tenThuan(m[1]);
      if (!ten || da.has(ten)) return;
      da.add(ten);
      ra.push({
        ten,
        min: parseFloat(m[3].replace(/,/g, '')),
        max: parseFloat(m[4].replace(/,/g, '')),
      });
    };
    // Lay o cac the THUAN CHU truoc: cau nao ra cau nay, khong dinh chu khac.
    for (const el of document.querySelectorAll('[role="alert"],p,span,div,li'))
      if (!el.children.length) xet(el.textContent);
    // Khong thay thi vet lai ca trang theo tung dong.
    if (!ra.length)
      for (const d of ((document.body && document.body.innerText) || '').split(/\r?\n/))
        xet(d);
    return ra;
  }

  // --- tim cac dong affix dang co tren form ---------------------------
  function timCacDong() {
    return cheDo() === 'classic' ? dongClassic() : dongBeta();
  }

  function dongBeta() {
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
    // O CLASSIC lop chu nay dung cho CA nhan "Gold" cua o gia. Nhan do boc
    // mot the input ben trong -> bo qua, chi lay the thuan chu.
    for (const a of document.querySelectorAll('[class*="font-tooltip-title"]')) {
      if (a.querySelector('input,textarea,select')) continue;
      const t = (a.textContent || '').trim();
      if (t) return t;
    }
    return '';
  }

  // --- ap dung ---------------------------------------------------------
  function apDung(text, epBuoc) {
    // KHONG con chot kiem TEN MON nua. Truoc day chu dan phai trung ten mon
    // dang mo, khong thi tu choi ghi. Nhung ten mon la chu to, font rieng,
    // chu O viet kieu Ø — OCR doc sai luon, nen chot nay bao lech oan nhieu
    // hon la bat duoc loi that. Trong khi bo quet cua trang nhan ten mon
    // gan nhu luon dung, va cai user can la CON SO chay vao dung o.
    const tenForm = layTenItemTrenForm();

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

    // Viet xong roi phai DOC LAI O. Trang co quyen khong nhan so minh viet
    // — no tu cat ve muc toi da chang han. Khong doc lai thi bang bao "da
    // dien 3500" trong khi o dang ghi 2800, user tin nham roi dang len san.
    const lech = [];
    const chot = () => {
      for (let i = ok.length - 1; i >= 0; i--) {
        const thuc = parseFloat(String(ok[i].dong.inp.value).replace(/,/g, ''));
        if (isFinite(thuc) && Math.abs(thuc - ok[i].v) > 0.001) {
          lech.unshift(Object.assign({}, ok[i], { thuc: thuc }));
          ok.splice(i, 1);
        }
      }
      bao(ok, ngoaiKhoang, khongThay, '', doiSao, banTrenDia, nghiNgo, lech);
    };

    if (ok.length) {
      setTimeout(() => {
        // CLASSIC khong ghi san khoang hop le vao trang, chi bao bang mot
        // cau chu sau khi da nhan so. Doc nguoc tu cau do.
        if (cheDo() === 'classic') {
          for (const c of docCanhBaoNgoai()) {
            const i = ok.findIndex(o => diemKhop(c.ten, o.dong.ten) >= DIEM_CHAC);
            if (i < 0) continue;
            ok[i].dong.min = c.min;
            ok[i].dong.max = c.max;
            ngoaiKhoang.push(ok[i]);
            ok.splice(i, 1);
          }
        }
        chot();
      }, 900);
      return;
    }
    bao(ok, ngoaiKhoang, khongThay, '', doiSao, banTrenDia, nghiNgo, lech);
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

  // CLASSIC khong co nut rieng: chinh O GO CHU "+ ADD AFFIX" vua la nut mo
  // danh sach vua la o loc. No cung noi ra aria-expanded / aria-controls
  // nhu nut cua BETA, nen phan con lai dung chung duoc.
  const oAddClassic = () =>
    document.querySelector('input[cmdk-input][placeholder*="ADD AFFIX"]') ||
    document.querySelector('input[cmdk-input]');

  const nutMoDs = () => (cheDo() === 'classic' ? oAddClassic() : nutThemAffix());

  // Nut Add la mot Radix Popover. No noi thang ra trang thai cua no:
  //   aria-expanded / data-state  -> dang mo hay dang dong
  //   aria-controls               -> id cua dung cai khung dropdown
  // Nho vay khong phai do dam gi ca. Ban truoc do dam nen go nham vao
  // o 44% cua Unique Power.
  const dangHien = el => !!(el && el.getClientRects().length);

  // BAY DA SUP MOT LAN: o go chu cua cmdk LUON ghi aria-expanded="true",
  // ke ca luc danh sach dang dong (do tren hai trang da luu: dong va mo deu
  // aria-expanded="true", khac nhau o cho DONG thi trong trang khong co
  // [cmdk-list] nao). Tin vao aria-expanded la khong bam nut bao gio, roi
  // ngoi doi mot cai khung khong bao gio duoc ve ra.
  // => Dau hieu DUY NHAT tin duoc: khung danh sach co that va dang nhin thay.
  const khungPopover = nut => {
    const id = nut.getAttribute('aria-controls');
    const k = id ? document.getElementById(id) : null;
    if (dangHien(k)) return k;
    if (nut.tagName !== 'INPUT') return null;
    // cmdk co the ve danh sach sang cho khac, id khong con khop
    const ds = [...document.querySelectorAll('[cmdk-list]')].filter(dangHien);
    return ds.find(x => x.querySelector('[cmdk-item]')) || ds[0] || null;
  };

  const dangMo = nut =>
    nut.tagName === 'INPUT'
      ? !!khungPopover(nut)
      : (nut.getAttribute('aria-expanded') === 'true' || nut.getAttribute('data-state') === 'open');

  async function moDropdown(nut) {
    if (dangMo(nut)) return khungPopover(nut);
    if (nut.tagName !== 'INPUT') {
      nut.click();
      return await cho(() => khungPopover(nut), 3000);
    }
    // O go chu khong mo ra bang .click() — bam nhu chuot that roi dat con
    // tro vao. Khong an thi thu phim mui ten xuong (loi mo quen thuoc cua
    // o combobox). Van khong an thi tra ve rong, de vong ngoai go chu vao
    // da — co ban chi xo danh sach khi da co chu trong o loc.
    bamThat(nut); nut.focus();
    let k = await cho(() => khungPopover(nut), 1200);
    if (k) return k;
    for (const loai of ['keydown', 'keyup'])
      nut.dispatchEvent(new KeyboardEvent(loai, {
        key: 'ArrowDown', code: 'ArrowDown', keyCode: 40, which: 40,
        bubbles: true, cancelable: true,
      }));
    return await cho(() => khungPopover(nut), 1200);
  }

  // Dong danh sach lai. Voi o go chu thi bam lai vao no KHONG dong duoc
  // (dang mo ma bam vao thi van mo) — phai go phim Esc va xoa chu da loc.
  function dongDs(nut) {
    if (nut.tagName !== 'INPUT') { bamThat(nut); return; }
    datGiaTri(nut, '');
    for (const loai of ['keydown', 'keyup'])
      nut.dispatchEvent(new KeyboardEvent(loai, {
        key: 'Escape', code: 'Escape', keyCode: 27, which: 27,
        bubbles: true, cancelable: true,
      }));
    try { nut.blur(); } catch (e) {}
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
    return cheDo() === 'classic'
      ? dongGoiYClassic(khung, ten)
      : dongGoiYBeta(khung, ten);
  }

  // Mot dong trong danh sach CLASSIC:
  //   <div cmdk-item role=option aria-disabled=...>
  //     <div><div class=flex-1><div>+(0) Strength</div> <nut hoi> </div>
  //          <span>Affix <img alt=GENERIC></span></div></div>
  // Chu cua ca the gom ca "View attribute description" lan "Affix" -> khong
  // khop duoc. Ten that nam o the DIV RONG dau tien (khong con the con).
  // Lay chu, BO nhung thu khong phai ten: nut hoi, hinh, va chu danh rieng
  // cho trinh doc man hinh ("View attribute description").
  function chuThuan(el) {
    let t = '';
    for (const n of el.childNodes) {
      if (n.nodeType === 3) { t += n.nodeValue; continue; }
      if (n.nodeType !== 1) continue;
      if (/^(BUTTON|IMG|SVG)$/i.test(n.tagName)) continue;
      if (String(n.className || '').indexOf('sr-only') >= 0) continue;
      t += chuThuan(n);
    }
    return t.replace(/\s+/g, ' ').trim();
  }

  // BAY DA SUP MOT LAN: trang TO SANG doan chu vua go ("Vuln" trong
  // "Vulnerable"), tuc no boc doan do vao mot the rieng — o chua ten khong
  // con la the RONG nua. Ban truoc chi nhan the rong nen tut xuong duong du
  // phong, lay ca chu cua nut hoi lan chu "Affix" o cuoi -> khong khop noi.
  // => Nhan o chua ten bang cach KHAC: la the div dau tien KHONG chua nut,
  //    khong chua hinh. Cai do thi to sang bao nhieu cung khong anh huong.
  function nhanDongClassic(el) {
    for (const d of el.querySelectorAll('div')) {
      if (d.querySelector('button,img,svg')) continue;
      const t = chuThuan(d);
      if (t && /[A-Za-z]{3}/.test(t)) return t;
    }
    return chuThuan(el);
  }

  function dongGoiYClassic(khung, ten) {
    const uv = [];
    for (const el of khung.querySelectorAll('[cmdk-item],[role="option"]')) {
      const t = nhanDongClassic(el);
      if (!t || t.length > 90) continue;
      const d = diemKhop(ten, t);
      if (d >= DIEM_CHAC) uv.push({ el, t });
    }
    if (!uv.length) return null;
    // Hai dong KHAC NHAU cung dat diem cao -> nhap nhang, khong duoc doan.
    if (uv.some(x => tenThuan(x.t) !== tenThuan(uv[0].t))) return null;
    return uv[0].el;
  }

  function dongGoiYBeta(khung, ten) {
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
  // Danh sach cua CLASSIC chi VE RA chung muoi dong quanh cho dang nhin, du
  // ben trong co gan 700 dong — cuon toi dau moi ve toi do. Vi vay phai cuon
  // TUNG MAN MOT, nhay quang la lot mat dong can tim. Con dai qua thi bo ve
  // ngay, de vong ngoai go tu khoa khac cho danh sach ngan lai.
  async function doCuonTimClassic(khung, ten) {
    if (khung.scrollHeight <= khung.clientHeight) return null;
    if (khung.scrollHeight > 4000) return null;   // ~75 dong: loc chua du chat
    const buoc = Math.max(80, Math.round(khung.clientHeight * 0.8));
    for (let y = 0; y <= khung.scrollHeight; y += buoc) {
      khung.scrollTop = y;
      await doi(160);
      const g = dongGoiYClassic(khung, ten);
      if (g) return g;
    }
    khung.scrollTop = 0;
    return null;
  }

  async function doCuonTim(khung, ten) {
    if (cheDo() === 'classic') return await doCuonTimClassic(khung, ten);
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
    const cl = cheDo() === 'classic';
    const dong = [...khung.querySelectorAll('label,li,[role="option"]')]
      .map(e => (cl ? nhanDongClassic(e) : (e.textContent || '')).trim())
      .filter(t => t && t.length < 80);
    // Chi tiet de do loi thi day ra Console — dung bat user doc chuoi DOM tho.
    console.log('[D4Lister] tim khong ra:', { go: tk, o: o.value, dong: dong });
    return dong.length
      ? 'gõ "' + tk + '" ra ' + dong.length + ' dòng, không dòng nào khớp'
      : 'gõ "' + tk + '" không ra dòng nào';
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
    timCacDong().some(d => diemKhop(ten, d.ten) >= DIEM_CHAC);

  // Go tu ngan nhung chac an: "Imbuements Skills" -> go "Imbuement".
  // Neu go nguyen ten ma OCR ra so it ("Imbuement Skills") thi bo loc cua
  // trang khong ra gi, vi nhan cua no la so nhieu ("Imbuements Skills").
  // Tra ve DANH SACH tu khoa de thu LAN LUOT. Khong doan truoc duoc cai nao
  // trung, vi con phu thuoc OCR nuot dau cach cho nao.
  //   "LifeonKill" -> ["Lifeon", "Life", ""]      (Lifeon truot, Life trung)
  //   "AllSkills"  -> ["All", "AllS", ""]
  // "" o cuoi = xoa bo loc, cuon het danh sach ma tim. Cham nhung chac.
  function dsTuKhoa(ten) {
    if (cheDo() === 'classic') return dsTuKhoaClassic(ten);
    const tu = tenThuan(ten).split(/\s+/).filter(Boolean);
    const dau = (tu[0] || '').replace(/s$/i, '');
    const ra = [];
    const them = k => { if (k && k.length >= 3 && ra.indexOf(k) < 0) ra.push(k); };

    if (tu.length === 1 && dau.length >= 8) {
      // OCR giu CHU HOA o dau moi tu -> tach tai do
      them(dau.replace(/([a-z0-9])([A-Z])/g, '$1 $2').split(' ')[0]);
      them(dau.slice(0, 4));
    } else {
      them(dau);
    }
    ra.push('');            // duong cuoi: bo het bo loc
    return ra;
  }

  // CLASSIC KHONG duoc bo het bo loc: danh sach gan 700 dong ma chi ve ra
  // muoi dong mot, cuon het la mat ca phut. Nen di tu DAI xuong NGAN, loc
  // cang chat cang tot, nhung khong bao gio de trong.
  //   "Life On Kill" -> ["life on kill", "life on", "life", "kill"]
  //   "LifeonKill"   -> ["lifeonkill", "Lifeon Kill", "Lifeon", "life"]
  function dsTuKhoaClassic(ten) {
    const t = tenThuan(ten);
    const tu = t.split(/\s+/).filter(Boolean);
    const ra = [];
    const them = k => {
      k = (k || '').trim();
      if (k.length >= 3 && ra.indexOf(k) < 0) ra.push(k);
    };

    them(t);
    if (tu.length > 2) them(tu.slice(0, 2).join(' '));
    // OCR nuot dau cach nhung con giu chu hoa -> tach tai cho chu hoa
    const tach = t.replace(/([a-z0-9])([A-Z])/g, '$1 $2');
    if (tach !== t) { them(tach); them(tach.split(' ')[0]); }
    them((tu[0] || '').replace(/s$/i, ''));
    // tu dai nhat thuong la tu dac trung nhat ("Vulnerable", "Overpower")
    them(tu.slice().sort((a, b) => b.length - a.length)[0]);
    // OCR dinh lien ma KHONG con chu hoa ("Lifeon") -> cat lay dau tu
    const d0 = (tach.split(/\s+/)[0] || '');
    if (d0.length >= 6) them(d0.slice(0, 4));
    return ra;
  }

  async function themCacAffixThieu(thieu) {
    loiThem = [];
    nhac('Đang thêm ' + thieu.length + ' dòng còn thiếu…');
    for (const m of thieu) {
      // Tim bang TEN CHUAN CUA TRANG (thu vien da xac nhan), khong phai ten
      // OCR doc ra. "Life On Kill" de tim hon "LifeonKill".
      const tenTim = m.coThat || m.ten;

      const cl = cheDo() === 'classic';
      const tenNut = cl ? '+ ADD AFFIX' : 'ADD STANDARD AFFIXES';

      const nut = nutMoDs();
      if (!nut) { loiThem.push([m.ten, 'không thấy ô ' + tenNut]); break; }

      let khung = await moDropdown(nut);

      // Chua mo duoc cung dung bo cuoc ngay: o CLASSIC chinh o go chu la
      // nut mo, co ban chi xo danh sach khi trong o DA CO CHU. Cu go vao
      // roi ngo lai; go het duong ma van khong xo thi luc do moi bao.
      const o = cl ? nut : (khung && oTimTrongKhung(khung));
      if (!o) {
        loiThem.push([m.ten, khung
          ? 'danh sách mở rồi nhưng không thấy ô tìm kiếm'
          : 'bấm ' + tenNut + ' rồi mà danh sách không mở ra']);
        continue;
      }

      let g = null, tk = '';
      for (const k of dsTuKhoa(tenTim)) {
        tk = k;
        if (cl && !dangMo(nut)) { bamThat(o); o.focus(); }
        goChu(o, k);
        await doi(k ? 550 : 700);
        if (!dangHien(khung)) khung = await cho(() => khungPopover(nut), 1500);
        if (!khung) continue;
        g = dongGoiY(khung, tenTim) || await doCuonTim(khung, tenTim);
        if (g) break;
      }
      if (!khung) {
        loiThem.push([m.ten, 'gõ vào ô ' + tenNut + ' rồi mà danh sách vẫn không xổ ra']);
        continue;
      }
      if (!g) { loiThem.push([m.ten, moTaThatBai(o, khung, tk)]); continue; }

      // CLASSIC lam mo di nhung dong DA CO tren form (aria-disabled). Gap
      // dong mo la affix von da nam tren form roi, bam cung khong an gi —
      // coi nhu xong, luot dien lai o cuoi se tim ra no.
      if (g.getAttribute && g.getAttribute('aria-disabled') === 'true') {
        if (dangMo(nut)) dongDs(nut);
        await doi(300);
        continue;
      }

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

      // Dem so dong TRUOC khi bam. Neu sau khi bam ma so dong TANG len thi
      // chac chan da them duoc, du ten co khop hay khong -> dung ngay.
      //
      // Can chot nay vi bam vao o tich la BAT/TAT qua lai: kiem sai mot cai
      // la no bam tiep cach 2, cach 3, va co the TAT lai cai vua bat.
      const soDongTruoc = timCacDong().length;
      let xong = false, daThu = [];
      for (const [ten, lam] of cach) {
        lam();
        xong = await cho(
          () => daCoDong(tenTim) || timCacDong().length > soDongTruoc, 1600);
        if (xong) break;
        daThu.push(ten);
      }
      if (!xong)
        loiThem.push([m.ten, 'thấy dòng rồi nhưng không chọn được. Đã thử: ' + daThu.join(', ')]);

      if (dangMo(nut)) dongDs(nut);   // dong danh sach lai cho gon
      await doi(400);
    }
    if (chuDaDan) apDung(chuDaDan, true);   // dien lai, lan nay co dong moi
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
    // CLASSIC viet "Unique Gloves Ancestral (Item Power 900)", BETA viet
    // "Legendary Gloves 750 Item Power" -> nhan ca hai, roi cat duoi.
    const m = t.match(
      /(?:Ancestral|Sacred)?\s*(?:Unique|Legendary|Rare|Magic|Mythic|Common)\s+([A-Za-z][A-Za-z ]{2,22}?)\s*\(?\s*\d*\s*Item Power/i);
    if (!m) return 'khong-ro';
    return m[1].replace(/\s*(?:Ancestral|Sacred)\s*$/i, '').trim() || 'khong-ro';
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
      o('tuQuet', 'Tự bấm Scan', 'Đợi ảnh nạp xong rồi mới bấm.') +
      o('tuThemAffix', 'Tự thêm affix thiếu',
        'Dòng nào trang thiếu thì tự mở danh sách thêm vào.') +
      o('tuDauSao', 'Tự bật dấu sao', 'Greater Affix — đo bằng pixel từ ảnh chụp.') +
      o('tuChonBase', 'Tự chọn base',
        'Sau khi quét: lấy base trơn rồi bấm Next.') +
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
    tuQuet:           true,   // ảnh nạp xong thì tự bấm Scan
    tuChonBase:       true,   // tự chọn base rồi bấm Next, khỏi phải chọn hình
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
  function bao(ok, ngoai, thieu, loi, doiSao, banTrenDia, nghiNgo, lech) {
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
      h += '<div style="color:#888;font-size:11px;margin-top:3px">Đồ masterwork thì bình thường, ' +
        'trang vẫn nhận.</div>';
    }
    if (nghiNgo && nghiNgo.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Không chắc — bạn xem giúp</div>';
      h += nghiNgo.map(x =>
        '&nbsp;&nbsp;' + thoat(x.ten) + ' = <b>' + x.so + (x.phanTram ? '%' : '') + '</b>' +
        '<br>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#888">giống nhất: ' +
        thoat(x.dong ? x.dong.ten : '?') + ' (' + Math.round(x.diem * 100) + '%)</span>'
      ).join('<br>');
      h += '<div style="color:#888;font-size:11px;margin-top:3px">Chưa điền — đoán bừa ' +
        'là đăng nhầm chỉ số.</div>';
    }
    if (thieu.length) {
      const coThat = thieu.filter(x => x.coThat);
      const laRac  = thieu.filter(x => !x.coThat);
      if (coThat.length) {
        h += '<div style="margin-top:8px;color:#e08a5a">Trang chưa có dòng này</div>';
        h += coThat.map(x => '&nbsp;&nbsp;' + thoat(x.coThat) + ' = <b>' + x.so +
          (x.phanTram ? '%' : '') + '</b>').join('<br>');
      }
      // Dong doc khong ra ten affix nao: gan nhu luon la RAC cua OCR
      // ("7NE Sock" tu may cai hinh o ngoc). To do len cho user lo lang la
      // bao sai — de mot dong chu xam, ai can thi liec.
      if (laRac.length) {
        h += '<div style="margin-top:8px;color:#777;font-size:11px">Bỏ qua ' +
          laRac.length + ' dòng đọc không ra: ' +
          laRac.map(x => thoat(x.ten)).join(', ') + '</div>';
      }
      // Nut nay chi them duoc nhung dong thu vien xac nhan la co that.
      // Chi co dong rac thi dung bay nut ra — bam cung khong lam gi.
      if (coThat.length)
        h += '<div style="margin-top:8px"><button id="d4l-them" style="background:#23402a;' +
          'color:#cfe8cf;border:1px solid #4a7a52;border-radius:5px;padding:5px 10px;cursor:pointer;' +
          'font:12px system-ui">Thêm giúp tôi</button>' +
          '<span style="color:#777;font-size:11px;margin-left:8px">hoặc tự bấm ADD STANDARD AFFIXES</span></div>';
    }
    // Viet vao roi doc lai thay o ghi so khac -> trang khong nhan. Phai
    // noi that, khong duoc bao "da dien" cho cai no khong nhan.
    if (lech && lech.length) {
      h += '<div style="margin-top:8px;color:#e06a5a">Trang không nhận số này</div>';
      h += lech.map(x => '&nbsp;&nbsp;' + thoat(x.dong.ten) + ': viết <b>' + x.v +
        '</b>, ô đang là <b>' + x.thuc + '</b>').join('<br>');
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
    if (nt) nt.onclick = () => themCacAffixThieu(thieu.filter(x => x.coThat));

    // Sạch = không có dòng nào vượt khoảng, không thiếu affix, không lỗi.
    const sach = !ngoai.length && !thieu.length && !loiThem.length && !loi
               && !(nghiNgo && nghiNgo.length) && !(lech && lech.length)
               && daGhi.length > 0;

    // Thiếu affix mà bật tự thêm -> thêm luôn, khỏi bấm nút.
    // CHỈ MỘT LẦN cho mỗi lần dán: thêm không được thì `thieu` vẫn còn,
    // không chặn thì nó gọi lại chính nó mãi mãi.
    // CHI them nhung cai thu vien xac nhan la CO THAT. Cai nao thu vien bao
    // "khong co affix nao ten nhu vay" thi di tim lam gi cho mat cong — vua
    // roi no con mo dropdown di tim "All Resist", ma do la chi so GOC cua
    // day chuyen, khong phai affix.
    const themDuoc = thieu.filter(x => x.coThat);
    if (CD.tuThemAffix && themDuoc.length && !daTuThem) {
      daTuThem = true;
      themCacAffixThieu(themDuoc);   // xong sẽ tự gọi lại apDung -> vẽ lại bảng
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
  // ====================================================================
  //  BUOC CHON BASE
  //
  //  Quet anh xong, voi do khong phai Unique thi trang bat chon "item
  //  variant" truoc roi moi cho khai affix. Cac variant chi KHAC NHAU CAI
  //  HINH, khong doi gi den chi so, nen khong co ly do bat user ngoi chon.
  //
  //  Moi the la mot button co anh, ben trong:
  //     ten variant  (font-tooltip-title)
  //     loai do      ("Ring")
  //     co the co    "Unlocks new look on salvage"
  //  Dong cuoi nghia la ban co ngoai hinh rieng, salvage ra thi mo khoa
  //  ngoai hinh do. The KHONG CO dong do la base mac dinh — tron nhat.
  //  (Do tren trang da luu: trong 24 the ring, dung MOT the khong co dong
  //  do, va no ten "Band" — dung ten base pho thong cua nhan trong game.)
  // ====================================================================
  const khungBase = () => document.querySelector('[data-slot="data-picker-results"]');

  const theBase = khung =>
    [...khung.querySelectorAll('button')].filter(b => b.querySelector('img'));

  function tenTheBase(b) {
    const sp = b.querySelector('[class*="font-tooltip-title"]');
    if (sp && sp.textContent.trim()) return sp.textContent.trim();
    const img = b.querySelector('img');
    return img ? (img.alt || '').trim() : '';
  }

  const laBaseTron = b => !/unlocks new look/i.test(b.textContent || '');

  // Uu tien the TRUNG TEN mon do vua quet; khong co thi lay the tron.
  // Danh sach cung ao hoa (chi ve ra phan dang nhin) nen phai cuon ma tim.
  async function timTheBase(khung, tenMuon) {
    let tron = null, dau = null;
    const xet = () => {
      for (const b of theBase(khung)) {
        if (!dau) dau = b;
        const t = tenTheBase(b);
        if (tenMuon && t && diemKhop(tenMuon, t) >= DIEM_CHAC) return b;
        if (!tron && laBaseTron(b)) tron = b;
      }
      return null;
    };
    let g = xet();
    if (g) return g;
    if (!tenMuon && tron) return tron;

    const buoc = Math.max(100, khung.clientHeight - 40);
    for (let y = buoc; y <= khung.scrollHeight; y += buoc) {
      khung.scrollTop = y;
      await doi(150);
      g = xet();
      if (g) return g;
      if (!tenMuon && tron) break;
    }
    khung.scrollTop = 0;
    return tron || dau || null;
  }

  const nutNext = () =>
    [...document.querySelectorAll('button')].find(b =>
      /^next$/i.test((b.textContent || '').trim()) && !b.disabled && b.offsetParent !== null);

  let dangChonBase = false, soLanChonBase = 0;

  async function chonBase(tenMuon) {
    const khung = khungBase();
    if (!khung || !theBase(khung).length) return;
    soLanChonBase++;
    nhac('Đang chọn base cho món đồ…');
    const b = await timTheBase(khung, tenMuon);
    if (!b) return;
    bamThat(b);
    await doi(450);
    const n = nutNext();
    if (n) { bamThat(n); await doi(450); }
  }

  // ====================================================================
  //  TU BAM SCAN
  //
  //  Dan xong, trang nhan anh roi van doi user bam SCAN. Bam ho — nhung
  //  chi khi ANH DA NAP XONG THAT, khong phai chi vua thay the <img>:
  //     complete = true      trinh duyet da tai xong
  //     naturalWidth > 0     tai duoc that, khong phai anh hong
  //     do HAI NHIP lien     kich thuoc dung yen -> khong con dang doi anh
  //  Thieu ba chot nay thi co luc bam SCAN vao mot khung anh rong, trang
  //  quet ra so lieu cua mon TRUOC do.
  // ====================================================================
  const anhDaNap = () =>
    [...document.querySelectorAll('img')].find(im =>
      /^(blob:|data:image)/.test(im.currentSrc || im.src || '') &&
      im.complete && im.naturalWidth > 0 && im.getClientRects().length);

  const nutQuet = () =>
    [...document.querySelectorAll('button')].find(b =>
      /^scan$/i.test((b.textContent || '').trim()) &&
      !b.disabled && b.getClientRects().length);

  // BAY DA SUP MOT LAN: truoc day cho nay do chu "Scanning screenshot" trong
  // document.body.textContent de biet trang co dang quet dang do khong.
  // Nhung textContent GOM CA NOI DUNG THE <script>, ma trang nhung goi ngon
  // ngu ngay trong script — trong do co dung chuoi "Scanning screenshot".
  // Vay la vua mo trang da thay, tu bam Scan bi chan ngay cau dau, KHONG
  // BAO GIO chay. Bo han phep do nay: da co daBamQuet (moi lan dan chi bam
  // mot lan) va nut Scan phai dang HIEN + khong bi khoa — dang quet do thi
  // nut bien mat, khong the bam trung.

  let anhTruoc = '', daBamQuet = false;

  // Tra ve true khi vua bam SCAN, de vong cho bo qua nhip nay.
  function thuBamQuet() {
    if (daBamQuet) return false;
    const im = anhDaNap();
    if (!im) { anhTruoc = ''; return false; }
    const dau = (im.currentSrc || im.src) + '|' + im.naturalWidth + 'x' + im.naturalHeight;
    if (dau !== anhTruoc) { anhTruoc = dau; return false; }   // doi them mot nhip
    const nut = nutQuet();
    if (!nut) return false;
    daBamQuet = true;
    nhac('Ảnh đã nạp xong — bấm Scan.');
    bamThat(nut);
    return true;
  }

  function choFormDungXong(text) {
    if (dongHo) clearInterval(dongHo);
    const batDau = Date.now();
    let truoc = -1, yen = 0;
    const tenChu = (text.split(/\r?\n/).find(l => l.trim()) || '').trim();
    dangChonBase = false;
    soLanChonBase = 0;
    daBamQuet = false;
    anhTruoc = '';
    nhac('Đã nhận chữ. Đang đợi form…');
    dongHo = setInterval(() => {
      // Dang o buoc chon base thi chon giup roi bam Next, dung bat user ngoi
      // chon cai hinh. Thu toi da hai lan cho khoi bam mai.
      if (CD.tuChonBase && !dangChonBase && soLanChonBase < 2 && khungBase()) {
        dangChonBase = true;
        chonBase(tenChu).then(() => { dangChonBase = false; });
        return;
      }
      if (dangChonBase) return;
      if (CD.tuQuet && thuBamQuet()) return;
      const n = timCacDong().length;
      if (n > 0 && n === truoc) {
        if (++yen >= 2) { clearInterval(dongHo); dongHo = null; apDung(text); return; }
      } else {
        yen = 0;
      }
      truoc = n;
      if (Date.now() - batDau > CHO_TOI_DA) {
        clearInterval(dongHo); dongHo = null;
        bao([], [], [], 'Đợi lâu quá chưa thấy dòng affix nào. Bấm SCAN rồi Ctrl+Shift+D.');
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
    c.title = 'D4Lister — bấm để mở thiết lập.';
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
