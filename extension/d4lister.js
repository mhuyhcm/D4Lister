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

  const BAN = '9.5';          // doi cung luc voi version trong manifest.json

  // So sanh hai so hieu ban: -1 a cu hon, 0 bang, 1 a moi hon.
  //
  // So tung DOAN SO, khong so chuoi. So chuoi thi '7.10' < '7.2' vi ky tu
  // '1' dung truoc '2' — den ban 7.10 la canh bao cap nhat im lang luon.
  function soSanhBan(a, b) {
    const A = String(a).split('.'), B = String(b).split('.');
    for (let i = 0; i < Math.max(A.length, B.length); i++) {
      const x = parseInt(A[i], 10) || 0, y = parseInt(B[i], 10) || 0;
      if (x !== y) return x > y ? 1 : -1;
    }
    return 0;
  }
  // Ngo NHANH, nhung "form da dung yen chua" thi tinh bang THOI GIAN THAT.
  // Truoc day tron hai thu: dung yen = "2 nhip lien" -> moi thu bi lam tron
  // len boi so cua nua giay. Tach ra thi ngo nhanh duoc ma van khong cuop co
  // luc trang dang dung form do dang.
  // ====================================================================
  //  NHAT KY TRONG MAY
  //
  //  Moi dong ext ghi ra Console deu duoc giu lai o day. Bam banh rang >
  //  "Chép nhật ký" la ca xap vao clipboard — khoi phai mo Console roi ngoi
  //  loc tung dong giua hang tram dong quang cao cua trang.
  // ====================================================================
  // ------------------------------------------------------------------
  //  DONG HO DO TUNG BUOC
  //  Moi moc ghi ra: tong thoi gian tu luc dan, va rieng buoc do ton bao
  //  lau. Cho nao khung se lo ngay trong nhat ky.
  // ------------------------------------------------------------------
  let mocGoc = 0;
  const gioNay = () => (mocGoc ? Math.round(performance.now() - mocGoc) : 0);
  const batGio = () => { mocGoc = performance.now(); };
  const dem = () => performance.now();
  const nhip = (ten, tu) =>
    ghi('[D4Lister] ⏱ ' + String(gioNay()).padStart(6) + 'ms'
      + (tu === undefined ? '' : '  (bước này ' + Math.round(performance.now() - tu) + 'ms)')
      + '  ' + ten);

  const nhatKy = [];
  function ghi() {
    try {
      const d = [].slice.call(arguments).map(x => {
        if (typeof x === 'string') return x;
        try { return JSON.stringify(x); } catch (e) { return String(x); }
      }).join(' ');
      nhatKy.push(new Date().toLocaleTimeString('vi-VN') + '  ' + d);
      if (nhatKy.length > 500) nhatKy.shift();
    } catch (e) { /* ghi nhat ky hong thi cung khong duoc chan viec chinh */ }
    console.log.apply(console, arguments);
  }

  const NHIP_DO   = 150;     // ms giua hai lan ngo
  const YEN_TOI_DA = 400;    // form khong doi suot ngan nay = dung xong
  const CHO_TOI_DA = 120000; // ms bo cuoc neu mai khong thay dong affix nao
  let chuDaDan = '';
  let chuDaDoc = [];      // cac dong doc duoc tu anh, de ghi vao file do
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
    // Trang viet "+# to Demonology Skills", con chu OCR doc ra chi la
    // "Demonology Skills" (phan doc chu da cat chu "to" roi). Khong cat o
    // day nua thi hai ben lech dung mot tu -> 67%, truot ca khau dien lan
    // khau them. Da do: trong 638 ten affix cua trang KHONG ten nao bat dau
    // bang "to", nen cat la an toan.
    t = t.replace(/^to\s+/i, '');
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
    let A = tachTu(a), B = tachTu(b);
    if (!A.length || !B.length) return 0;

    // Duoi "Skills" la TUY trang dat. Game luon viet du: "+4 to Dust Devil
    // Skills". Danh muc cua trang thi khi co khi khong — "Core Skills",
    // "Blood Skills" co, ma "Dust Devil", "Golem", "Hydra", "Arrow Storm"
    // lai de tron.
    //
    // Lech dung mot tu thoi nhung 2/3 = 67%, hut nguong, va the la dong do
    // KHONG them duoc — dung ca mon lai.
    //
    // Chi cat khi MOT ben co duoi con ben kia khong. Hai ben cung co thi de
    // nguyen, "Core Skills" van phai khac "Corpse Skills".
    //
    // Do tren ca 640 ten cua trang: cat duoi nay khong lam hai ten nao dung
    // nhau (0 cap), nen cat la an toan.
    const coDuoi = x => x[x.length - 1] === 'skills';
    if (coDuoi(A) !== coDuoi(B)) {
      if (coDuoi(A) && A.length > 1) A = A.slice(0, -1);
      else if (coDuoi(B) && B.length > 1) B = B.slice(0, -1);
    }

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
      ra.push(Object.assign({ ten, inp, min: null, max: null, nutSao, khoi },
        cachDungO(inp, nutSao)));
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

  // Moi dong affix deu phai tra loi duoc 5 cau nay, du no la O NHAP tren
  // trang hay la MOT MUC trong bo dieu khien form. Nho vay phan dien so o
  // apDung() khong can biet minh dang ghi bang duong nao.
  const cachDungO = (inp, nutSao) => ({
    qua:    'o nhap',
    nguyen: inp.getAttribute('inputmode') === 'numeric',
    coSao:  !!nutSao,
    lay:    () => inp.value,
    dat:    x => datGiaTri(inp, x),
    laySao: () => saoDangBat(nutSao),
    datSao: bat => { if (nutSao && saoDangBat(nutSao) !== !!bat) bamThat(nutSao); },
  });

  // ====================================================================
  //  GHI THANG VAO BO DIEU KHIEN FORM
  //
  //  Trang dung react-hook-form. Bo dieu khien cua no giu san ca mang
  //  affixes, moi phan tu co:
  //     description "+# Willpower"   <- ten chuan, # la cho dien so
  //     values      [112]            <- con so
  //     isGreater   true/false       <- dau sao
  //     minValue / maxValue          <- khoang hop le
  //  Ghi thang vao day thi KHONG phai go chu, khong phai bam chuot gia,
  //  va co luon khoang hop le — thay vi di mo tung o nhap tren man hinh.
  //  Khong voi toi duoc thi tra ve null, apDung() tu quay ve duong cu.
  // ====================================================================
  function dongForm() {
    const fm = timFormTrang();
    if (!fm) return null;
    let v;
    try { v = fm.getValues(); } catch (e) { return null; }
    if (!v || !Array.isArray(v.affixes) || !v.affixes.length) return null;

    // GHI QUA DAU? Qua chinh O NHAP tren man hinh, khong ghi thang vao so
    // sach cua form.
    //
    // BAY DA SUP MOT LAN: setValue() co doi so sach that, doc lai cung ra so
    // moi — nhung O TREN MAN HINH KHONG DOI THEO. Da gap: viet 196 vao
    // Weapon Damage, getValues tra ve 196, ma o van hien 19, va bang bao
    // "da dien" nen khong ai biet. O nhap la thanh phan co trang thai rieng,
    // no chi doc gia tri form luc dung ra.
    // => Ghi vao O NHAP bang setter goc + su kien 'input', dung y het luc
    //    nguoi ta go tay: o doi, va form cung nhan duoc.
    // Form van rat co gia: no cho KHOANG HOP LE (minValue/maxValue) ma o
    // che do CLASSIC khong he co, va cho duong THEM DONG MOI.
    const dsDom = cheDo() === 'classic' ? dongClassic() : dongBeta();
    const daGhep = {};
    const ghepTheoTen = ten => {
      for (let j = 0; j < dsDom.length; j++) {
        if (daGhep[j]) continue;
        if (diemKhop(ten, dsDom[j].ten) >= DIEM_CHAC) { daGhep[j] = true; return dsDom[j]; }
      }
      return null;
    };

    const ra = [];
    v.affixes.forEach((a, i) => {
      const ten = tenThuan(a.description || a.name || '');
      if (!ten) return;
      const duong = 'affixes.' + i;
      const o = ghepTheoTen(ten);
      ra.push({
        ten,
        qua:    'form',
        min:    typeof a.minValue === 'number' ? a.minValue : null,
        max:    typeof a.maxValue === 'number' ? a.maxValue : null,
        nguyen: o ? o.nguyen : false,
        coSao:  true,
        // Doc tu O NHAP neu ghep duoc — do moi la cai user nhin thay.
        lay:    () => {
          if (o) return o.lay();
          const x = fm.getValues(duong + '.values.0');
          return (x === null || x === undefined) ? '' : String(x);
        },
        dat:    x => {
          if (o) o.dat(x);
          else fm.setValue(duong + '.values.0', x,
                 { shouldDirty: true, shouldTouch: true, shouldValidate: true });
        },
        laySao: () => (o && o.coSao) ? o.laySao() : !!fm.getValues(duong + '.isGreater'),
        datSao: bat => {
          if (o && o.coSao) o.datSao(bat);
          else fm.setValue(duong + '.isGreater', !!bat, { shouldDirty: true });
        },
      });
    });
    return ra.length ? ra : null;
  }

  // So dong affix THAT SU HIEN RA TREN MAN HINH (dem o nhap, khong dem so
  // sach cua form). Day moi la thuoc do dung cho cau hoi "trang ve xong
  // chua" va "day dong vao co an thua khong" — so sach cua form thay doi
  // ngay khi ext ghi, con man hinh thi chua chac.
  const soDongManHinh = () =>
    (cheDo() === 'classic' ? dongClassic() : dongBeta()).length;

  // --- tim cac dong affix dang co tren form ---------------------------
  function timCacDong() {
    if (CD.ghiThangForm) {
      const f = dongForm();
      if (f) return f;
    }
    return cheDo() === 'classic' ? dongClassic() : dongBeta();
  }

  // BAY DA SUP MOT LAN (23/09/2026, mon Galvanic Azurite):
  // ban truoc tim khoi cua mot dong bang cach di nguoc len cho den khi gap
  // nut "Remove ...", khong gap thi BO QUA dong do. Nhung affix CO DINH cua
  // do Unique thi trang khong cho xoa -> dong do khong co nut Remove -> ext
  // khong nhin thay no, tuong la con thieu, roi them vao mot dong thu hai y
  // het. Man hinh hien "Shock Skills" hai lan, con dong that thi khong ai
  // dien so cho.
  // => Khoi cua mot dong = to tien gan nhat ma BEN TRONG chi co DUNG MOT o
  //    "Affix value". Cach nhan nay khong phu thuoc nut Remove co hay khong.
  function khoiDongBeta(inp) {
    let khoi = inp;
    for (let i = 0; i < 10; i++) {
      const cha = khoi.parentElement;
      if (!cha) break;
      if (cha.querySelectorAll('input[aria-label="Affix value"]').length > 1) break;
      khoi = cha;
      if (khoi.querySelector('button[aria-label^="Remove "],[aria-label^="Reorder "]')) break;
    }
    return khoi;
  }

  function tenDongBeta(khoi) {
    const b = khoi.querySelector('button[aria-label^="Remove "]')
           || khoi.querySelector('[aria-label^="Reorder "]');
    if (b) return b.getAttribute('aria-label').replace(/^(Remove|Reorder)\s+/, '').trim();
    // Khong co ca hai nut: lay chu hien ra canh o nhap. Chi nhan the KHONG
    // chua nut/o nhap/hinh, de doan chu trang to sang khong lam lech.
    for (const e of khoi.querySelectorAll('span,div,label,p')) {
      if (e.querySelector('button,input,img,svg')) continue;
      const t = (e.textContent || '').replace(/\s+/g, ' ').trim();
      if (t.length >= 3 && /[A-Za-z]{3}/.test(t) && !/^[\d.,%+–—\-x\s]+$/.test(t))
        return t;
    }
    return '';
  }

  function dongBeta() {
    const ra = [];
    for (const inp of document.querySelectorAll('input[aria-label="Affix value"]')) {
      const khoi = khoiDongBeta(inp);
      const ten = tenDongBeta(khoi);
      if (!ten) continue;

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
      ra.push(Object.assign({ ten, inp, min, max, nutSao }, cachDungO(inp, nutSao)));
    }
    return ra;
  }

  const saoDangBat = n => n && n.getAttribute('aria-checked') === 'true';

  // ====================================================================
  //  MUC UNIQUE POWER
  //
  //  Suc manh rieng cua do Unique (va Aspect cua do Legendary) khong phai
  //  affix — trang xep no o muc rieng, co mot o so va mot cong tac
  //  "Maxxed out Unique Power".
  //
  //  Trang MAC DINH dat kich tran luc dung mon: Galvanic Azurite ra 60%
  //  trong khi mon that chi 44%. Khong sua thi moi mon Unique deu bi khai
  //  khong dung — ma cho nay nguoi mua nhin rat ky.
  //
  //  D4Lister gui kem dong  #D4L-UNIQUE:44.0|40.0|60.0
  //  (gia tri | tran duoi | tran tren), doc ra tu chinh chu cua game.
  // ====================================================================
  const oHieuUngRieng = () =>
    [...document.querySelectorAll('input[aria-label="Effect value"]')].find(dangHien);

  const nutKichTran = () =>
    [...document.querySelectorAll('button[role="checkbox"]')]
      .find(b => dangHien(b) && b.getAttribute('aria-label') === 'Maxxed out Unique Power');

  // ====================================================================
  //  MUC SOCKETS
  //
  //  Trang de moi so o mot nut rieng, hinh luc giac:
  //     button[aria-label="1 socket"]  aria-pressed="true|false"
  //     button[aria-label="2 sockets"] aria-pressed="true|false"
  //  Doc duoc aria-pressed nen biet dang bat hay tat, khong bam thua.
  //
  //  D4Lister chi gui  #D4L-SOCKET:n  khi n > 0 (xem chu thich ben AHK).
  // ====================================================================
  const nutOngoc = n => {
    const a1 = n + ' socket', a2 = n + ' sockets';
    return [...document.querySelectorAll('button[aria-label]')].find(b => {
      if (!dangHien(b)) return false;
      const a = (b.getAttribute('aria-label') || '').trim().toLowerCase();
      return a === a1 || a === a2;
    });
  };

  function datOngoc(text) {
    const m = text.match(/^#D4L-SOCKET:(\d+)\s*$/m);
    if (!m) return null;
    const n = parseInt(m[1], 10);
    if (!n) return null;
    const b = nutOngoc(n);
    if (!b) return { loi: 'không thấy nút ' + n + ' socket' };
    if (b.getAttribute('aria-pressed') === 'true') return { n, daCo: true };
    bamThat(b);
    return { n };
  }

  function datSucManhRieng(text) {
    const m = text.match(/^#D4L-UNIQUE:([\d.]+)(?:\|([\d.]+)\|([\d.]+))?\s*$/m);
    if (!m) return null;
    const o = oHieuUngRieng();
    if (!o) return { loi: 'không thấy ô Effect value' };

    const gt  = parseFloat(m[1]);
    const tran = m[3] ? parseFloat(m[3]) : null;
    if (!isFinite(gt)) return null;
    const kichTran = tran !== null && Math.abs(gt - tran) < 0.001;

    // Cong tac truoc, o so sau — giong het chuyen dau sao cua affix: dang
    // kich tran thi o so bi khoa cung, ghi vao khong an.
    const nut = nutKichTran();
    if (nut && saoDangBat(nut) !== kichTran) bamThat(nut);

    setTimeout(() => {
      const o2 = oHieuUngRieng();
      if (o2) datGiaTri(o2, gt);
    }, 150);
    return { gt, tran, kichTran };
  }

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

  //  LOẠI ĐỒ mà TRANG đã dựng ra, đọc từ ô xem trước bên trái.
  //
  //  Ô xem trước in y như tooltip trong game:
  //      INFERNAL HOMUNCULUS          <- font-tooltip-title
  //      Ancestral Unique Charm       <- dòng ngay dưới, cái cần lấy
  //      900 Item Power
  //
  //  Dùng để TỰ KIỂM: chữ của game nói "Focus" mà trang dựng ra "Charm" thì
  //  cả cái listing sai, và trước nay không ai biết.
  //
  //  Không nhắm vào một thẻ cụ thể — leo lên khối bao ngoài rồi dò từng
  //  dòng chữ. Đoán cấu trúc DOM của trang này tôi đã sai ba lần rồi.
  function loaiTrenForm() {
    for (const a of document.querySelectorAll('[class*="font-tooltip-title"]')) {
      if (a.querySelector('input,textarea,select')) continue;
      let k = a;
      for (let i = 0; i < 4 && k; i++) {
        const dong = ((k.innerText || k.textContent || '') + '')
          .split(/\r?\n/).map(x => x.trim()).filter(Boolean);
        for (const d of dong) {
          if (d.length > 44) continue;
          if (RE_DO_HIEM.test(d) && /[A-Za-z]/.test(d.replace(RE_DO_HIEM, '')))
            return d;
        }
        k = k.parentElement;
      }
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
    chuDaDoc = muon.map(m => m.ten + ' = ' + m.so + (m.phanTram ? '%' : '') +
      (m.sao ? ' *' : ''));
    const dang = timCacDong();
    // V3 tu dung ra mon, nen form vua tao xong CHUA CO dong affix nao la
    // chuyen binh thuong — cac dong se do chinh ext them vao. Chi coi la
    // "chua co mon" khi ca o ADD STANDARD AFFIXES cung khong co.
    if (!dang.length && !nutMoDs()) {
      bao([], [], [], 'Trang chưa có món đồ nào để điền.');
      return;
    }

    // D4Lister chi gui dau hieu nay khi phan do dau sao THUC SU chay xong.
    // Khong co no (thieu Tesseract chang han) thi khong dung vao cong tac sao,
    // de khoi xoa nham dau sao ma trang da nhan dung.
    // Co co "m": dong #D4L-EXT nam SAU dong nay, nen khong the neo vao cuoi
    // ca chuoi duoc nua - thieu co "m" la phan do dau sao tat ngam.
    const coDoSao = /^#D4L-SAO-OK\s*$/m.test(text);
    // Thiếu cờ = game đang KHÔNG in khoảng [min - max] (Advanced Tooltip
    // Information tắt), nên không biết dòng nào là Greater Affix. Trước đây
    // tiện ích lặng lẽ không đụng tới dấu ✻; im lặng thì người bán tưởng
    // trang tự nhận đúng. Nay nói ra.
    khongBietSao = !coDoSao;

    // D4Lister gui kem so hieu ban tien ich DANG NAM TREN DIA. Lech voi ban
    // dang chay = Chrome van dung ban cu (no khong tu nap lai bao gio).
    const mExt = text.match(/#D4L-EXT:([0-9.]+)/);
    const banTrenDia = mExt ? mExt[1] : '';

    const daDung = new Set();
    const ok = [], ngoaiKhoang = [], khongThay = [], doiSao = [], nghiNgo = [];

    nhip('apDung ' + (epBuoc ? '(gọi lại)' : '(lần đầu)'));
    ghi('[D4Lister] apDung(' + (epBuoc ? 'gọi lại' : 'lần đầu') + '): muốn '
      + muon.length + ' dòng [' + muon.map(x => x.ten).join(' | ') + ']'
      + '  ·  form đang có ' + dang.length + ' dòng [' + dang.map(x => x.ten).join(' | ') + ']'
      + '  ·  màn hình ' + soDongManHinh() + ' ô nhập');

    for (const m of muon) {
      // Khop theo TU. Ten cua DONG TREN FORM chinh la ten cua trang (doc tu
      // nut xoa "Remove ..."), nen day da la doi chieu voi chuan roi.
      const kq = timKhopNhat(m.ten, dang, d => d.ten, daDung);

      if (kq.diem < DIEM_NGO) {
        // Co ten nay trong thu vien khong? Neu co -> affix that, chi la trang
        // chua dung dong do ra. Neu khong -> nhieu kha nang OCR doc bay.
        const tv = THU_VIEN.length ? timKhopNhat(m.ten, THU_VIEN) : { diem: 0, muc: null };
        const that = tv.diem >= DIEM_CHAC ? tv.muc : null;
        ghi('[D4Lister]   form chưa có "' + m.ten + '" (giống dòng sẵn có nhất '
          + Math.round(kq.diem * 100) + '%)  ·  thư viện ' + THU_VIEN.length + ' tên: "'
          + (tv.muc || '—') + '" ' + Math.round(tv.diem * 100) + '%  ->  '
          + (that ? 'sẽ tự thêm' : 'KHÔNG tự thêm'));
        khongThay.push({ ...m, coThat: that });
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

      // DAU SAO PHAI BAT TRUOC KHI GHI SO.
      //
      // Trang chan gia tri trong khoang binh thuong cua affix, va CHI khi
      // cong tac Greater Affix dang BAT no moi cho vuot tran. Poison
      // Resistance khoang 1-2800: ghi 3500 luc sao con tat thi trang cat
      // ngay con 2800, roi bat sao sau do cung khong keo lai duoc.
      // Dung thu tu nay thi tran duoc noi ra truoc, so moi vao tron.
      if (CD.tuDauSao && coDoSao && dong.coSao && dong.laySao() !== !!m.sao) {
        dong.datSao(!!m.sao);
        doiSao.push({ ten: dong.ten, bat: !!m.sao });
      }

      // o nhap chi cho so nguyen thi lam tron
      const v = dong.nguyen ? Math.round(m.so) : m.so;

      const cu = dong.lay();
      dong.dat(v);

      const reRange = (dong.min !== null && (m.so < dong.min || m.so > dong.max));
      if (reRange) ngoaiKhoang.push({ ...m, dong, v, cu });
      else ok.push({ ...m, dong, v, cu });
    }

    // Hai muc nam NGOAI khoi affix nen lam rieng: UNIQUE POWER va SOCKETS.
    const ngoai = [];
    const kqRieng = datSucManhRieng(text);
    if (kqRieng && kqRieng.loi) ngoai.push('Unique Power: ' + kqRieng.loi);
    else if (kqRieng)
      ngoai.push('Unique Power ' + kqRieng.gt + (kqRieng.kichTran ? ' (kịch trần)' : ''));

    const kqO = datOngoc(text);
    if (kqO && kqO.loi) ngoai.push('Ổ ngọc: ' + kqO.loi);
    else if (kqO) ngoai.push(kqO.n + ' ổ ngọc' + (kqO.daCo ? ' (trang đã chọn sẵn)' : ''));

    if (ngoai.length) nhac(ngoai.join('  ·  '));

    // Viet xong roi phai DOC LAI O. Trang co quyen khong nhan so minh viet
    // — no tu cat ve muc toi da chang han. Khong doc lai thi bang bao "da
    // dien 3500" trong khi o dang ghi 2800, user tin nham roi dang len san.
    // BAY DA SUP MOT LAN: ban truoc chi doc lai nhung dong SACH, bo qua dong
    // vuot khoang. Ma dung cai dong vuot khoang moi la cai trang hay khong
    // nhan — "+196 Weapon Damage" bi trang giu lai thanh 19, ma bang van bao
    // "da dien 4 dong". Gio doc lai CA HAI nhom.
    const lech = [];
    const doLai = ds => {
      for (let i = ds.length - 1; i >= 0; i--) {
        const thuc = parseFloat(String(ds[i].dong.lay()).replace(/,/g, ''));
        if (isFinite(thuc) && Math.abs(thuc - ds[i].v) > 0.001) {
          lech.unshift(Object.assign({}, ds[i], { thuc: thuc }));
          ds.splice(i, 1);
        }
      }
    };
    const chot = () => {
      doLai(ok);
      doLai(ngoaiKhoang);
      bao(ok, ngoaiKhoang, khongThay, '', doiSao, banTrenDia, nghiNgo, lech);
    };

    let daXepLaiClassic = false, daVietLaiSao = false;
    const kiemLai = () => {
      // CLASSIC khong ghi san khoang hop le vao trang, chi bao bang mot
      // cau chu sau khi da nhan so. Doc nguoc tu cau do.
      if (cheDo() === 'classic' && !daXepLaiClassic) {
        daXepLaiClassic = true;
        for (const c of docCanhBaoNgoai()) {
          const i = ok.findIndex(o => diemKhop(c.ten, o.dong.ten) >= DIEM_CHAC);
          if (i < 0) continue;
          ok[i].dong.min = c.min;
          ok[i].dong.max = c.max;
          ngoaiKhoang.push(ok[i]);
          ok.splice(i, 1);
        }
      }

      // Cong tac Greater Affix vua bat thi trang can mot nhip moi noi tran
      // ra, nen so ghi ngay sau do van co the bi cat. Ghi lai DUNG MOT lan
      // cho nhung dong co dau sao ma so chua vao dung.
      if (!daVietLaiSao) {
        const lam = [];
        for (const d of ok.concat(ngoaiKhoang)) {
          if (!d.sao) continue;
          const thuc = parseFloat(String(d.dong.lay()).replace(/,/g, ''));
          if (isFinite(thuc) && Math.abs(thuc - d.v) > 0.001) { d.dong.dat(d.v); lam.push(d); }
        }
        if (lam.length) {
          daVietLaiSao = true;
          ghi('[D4Lister] ghi lại ' + lam.length +
            ' dòng có dấu sao sau khi trần đã được nới:',
            lam.map(x => x.dong.ten + ' = ' + x.v).join(', '));
          setTimeout(kiemLai, 300);
          return;
        }
      }

      chot();
      tuDo();          // tu di do, im lang neu on
    };

    if (ok.length || ngoaiKhoang.length) {
      setTimeout(kiemLai, 350);
      return;
    }
    bao(ok, ngoaiKhoang, khongThay, '', doiSao, banTrenDia, nghiNgo, lech);
  }

  // --- tu them dong affix ma trang khong dung ra ------------------------
  // Cai nay do duong, vi cau truc cai dropdown chua ai nhin thay.
  // Neu that bai thi bao ro, KHONG bam bua len trang.
  let loiThem = [];
  // Canh bao loai do: giu RIENG, khong nhap vao loiThem — loiThem bi xoa
  // sach moi lan chay phan them affix, ma phan do chay sau.
  let canhBaoLoaiDo = '';
  // Gia bi trang doi khac di luc dien. Giu rieng, nhu canhBaoLoaiDo.
  let giaBiDoi = null;
  // Khong biet dong nao la Greater Affix (game khong in khoang [min-max]).
  let khongBietSao = false;

  // ====================================================================
  //  CHỤP TỪNG BƯỚC  ("AI fix bug")
  //
  //  Bật lên thì mỗi lần dán một món, tiện ích chụp lại cấu trúc trang ở
  //  TỪNG bước — từ lúc nhận chữ, qua chọn món, thêm affix, điền giá, cho
  //  tới lúc tự bấm Submit — và ghi thẳng ra đĩa. Mỗi lượt một THƯ MỤC
  //  riêng, đặt tên theo giờ:
  //
  //      Tải xuống/d4l-hoso/20260925-153012-infernal-homunculus/
  //          01-vua-dan-chu.html
  //          02-1a-truoc-go-ten-mon.html
  //          ...
  //          17-sau-bam-submit.html
  //          00-nhat-ky.txt
  //
  //  Đọc cả thư mục là thấy lượt đó đi tới đâu thì đứng.
  //
  //  GHI NGAY từng bước, không gom chờ cuối như bản trước: gom lại thì lượt
  //  nào kẹt cứng giữa chừng — đúng lượt cần xem nhất — lại chẳng để lại
  //  file nào.
  //
  //  Ghi được nhiều file vào thư mục con là nhờ chrome.downloads bên nen.js
  //  (lý do chép ở đầu file đó); từ đây gọi sang qua cau-noi.js.
  //
  //  Cắt bớt trước khi ghi: bỏ script/style/svg, cắt ngắn ảnh nhúng dạng
  //  data:. Giữ nguyên thẻ và thuộc tính — đó mới là thứ cần đọc.
  // ====================================================================
  let thuMucLuot = '';        // 'd4l-hoso/<giờ>-<tên món>' của lượt đang chạy
  let soBuocDaChup = 0;
  let soLanLuuNhatKy = 0;
  let hencNhatKy = null;
  let idLuuFile = 0;
  const dangChoGhi = new Map();

  //  Nhờ tiến trình nền ghi một file xuống đĩa.
  //
  //  d4lister.js chạy ở world "MAIN" nên không có chrome.* — phải qua
  //  cau-noi.js (world "ISOLATED"). Bốn giây không ai trả lời thì coi như
  //  cầu nối chưa nạp (bản cũ của tiện ích còn sót lại chẳng hạn), lui về
  //  cách cũ: tải thẳng bằng thẻ <a download>, chịu nằm rải trong thư mục
  //  Tải xuống chứ không vào được thư mục con.
  function luuFileQuaNen(ten, chu) {
    const id = ++idLuuFile;
    const dongHo = setTimeout(() => {
      if (!dangChoGhi.has(id)) return;
      dangChoGhi.delete(id);
      ghi('AI fix bug: cầu nối không trả lời — tải thẳng ' + ten);
      taiThang(ten, chu);
    }, 4000);
    dangChoGhi.set(id, kq => {
      clearTimeout(dongHo);
      dangChoGhi.delete(id);
      if (!kq.ok) {
        ghi('AI fix bug: ghi "' + ten + '" hỏng (' + kq.loi + ') — tải thẳng');
        taiThang(ten, chu);
      }
    });
    window.postMessage({ d4l: 'luu-dom', id, ten, chu }, '*');
  }

  window.addEventListener('message', ev => {
    if (ev.source !== window) return;
    const d = ev.data;
    if (!d || d.d4l !== 'luu-dom-xong') return;
    const f = dangChoGhi.get(d.id);
    if (f) f(d);
  });

  //  Đường lui. Thẻ <a download> không tạo được thư mục con nên dẹp luôn
  //  đường dẫn, chỉ giữ tên file — dấu gạch chéo Chrome cũng bỏ, nhưng bỏ
  //  sẵn thì tên còn đọc được.
  function taiThang(duong, chu) {
    try {
      const ten = String(duong).split('/').pop();
      const u = URL.createObjectURL(new Blob([chu], { type: 'text/plain;charset=utf-8' }));
      const a = document.createElement('a');
      a.href = u;
      a.download = ten;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(u), 4000);
    } catch (e) { ghi('AI fix bug: tải thẳng cũng hỏng — ' + e); }
  }

  const tenSach = (s, dai) => String(s || '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, dai);

  //  Mở thư mục cho lượt mới. Gọi một lần lúc nhận chữ dán, mọi bước sau
  //  ghi chung vào đó.
  function moThuMucLuot(tenMon) {
    const g = new Date();
    const hai = n => String(n).padStart(2, '0');
    const gio = g.getFullYear() + hai(g.getMonth() + 1) + hai(g.getDate())
      + '-' + hai(g.getHours()) + hai(g.getMinutes()) + hai(g.getSeconds());
    const sach = tenSach(tenMon, 40);
    thuMucLuot = 'd4l-hoso/' + gio + (sach ? '-' + sach : '');
    soBuocDaChup = 0;
    soLanLuuNhatKy = 0;
    hanChoNhatKy = 0;
    if (hencNhatKy) { clearTimeout(hencNhatKy); hencNhatKy = null; }
    if (CD.aiChup) nhac('AI fix bug: đang ghi vào ' + thuMucLuot);
    return thuMucLuot;
  }

  function rutGonHtml(el) {
    if (!el) return '(không có)';
    let c;
    try { c = el.cloneNode(true); } catch (e) { return '(không sao chép được)'; }
    c.querySelectorAll('script,style,noscript,svg,canvas,iframe,video,audio')
      .forEach(x => x.remove());
    c.querySelectorAll('img,image,source').forEach(x => {
      const s = x.getAttribute('src') || '';
      if (/^data:/i.test(s)) x.setAttribute('src', 'data:…(cắt ' + s.length + ' ký tự)');
    });
    return c.outerHTML || '(rỗng)';
  }

  //  Chụp một bước: ghi NGAY ra file riêng trong thư mục của lượt.
  //
  //  Tên file mang số thứ tự để đọc theo đúng trình tự chạy — thư mục sắp
  //  theo tên, mà tên bước thì không nói gì về trước sau.
  function chupBuoc(ten, el) {
    if (!CD.aiChup) return;
    try {
      if (!thuMucLuot) moThuMucLuot('');
      soBuocDaChup++;
      const stt = String(soBuocDaChup).padStart(2, '0');
      // Bỏ số dẫn đầu trong tên bước ('0-vua-dan-chu') — số thứ tự thật
      // đã nằm ở đầu tên file rồi, để cả hai chỉ tổ rối.
      const sach = tenSach(String(ten).replace(/^\d+-/, ''), 50) || 'buoc';
      luuFileQuaNen(thuMucLuot + '/' + stt + '-' + sach + '.html',
        rutGonHtml(el || document.body));
      henLuuNhatKy();
    } catch (e) { ghi('chụp bước "' + ten + '" hỏng: ' + e); }
  }

  //  Lượt còn đang chạy hay không.
  //
  //  Không đo bằng "im lặng bao lâu" được: giữa lượt có quãng trống dài hơn
  //  hẹn giờ — đợi trang dựng form mất tới ba giây mà chẳng có bước nào để
  //  chụp. Lần chạy thử đầu tiên vấp đúng chỗ đó, đẻ ra một cuốn nhật ký
  //  cụt lúc 7 bước rồi cuốn thứ hai lúc 9 bước.
  //
  //  Nên hỏi thẳng mấy cái cờ đang chạy. Đủ cả năm việc dài hơi: đợi form,
  //  dựng món, chọn base, thêm affix, đếm ngược tự đăng.
  const conChay = () => !!(dongHo || dongHoDang || dangTaoItem
    || dangChonBase || dangThemAffix);

  //  Hẹn ghi nhật ký vào cùng thư mục. Ghi SAU CÙNG, vì nhật ký chỉ đầy đủ
  //  khi lượt đã chạy hết; mỗi bước mới lại dời hẹn ra sau.
  let hanChoNhatKy = 0;
  function henLuuNhatKy() {
    if (!CD.aiChup) return;
    // Hạn chờ đặt từ lần hẹn đầu: lượt kẹt cứng thì cờ không bao giờ hạ,
    // mà hồ sơ của lượt KẸT mới đúng là hồ sơ cần đọc — quá hạn là ghi.
    if (!hanChoNhatKy) hanChoNhatKy = Date.now() + 60000;
    if (hencNhatKy) clearTimeout(hencNhatKy);
    hencNhatKy = setTimeout(() => {
      hencNhatKy = null;
      if (conChay() && Date.now() < hanChoNhatKy) { henLuuNhatKy(); return; }
      hanChoNhatKy = 0;
      luuNhatKy();
    }, 2500);
  }

  function luuNhatKy() {
    if (!CD.aiChup || !thuMucLuot || !soBuocDaChup) return;
    soLanLuuNhatKy++;
    const ten = thuMucLuot + '/00-nhat-ky'
      + (soLanLuuNhatKy > 1 ? '-' + soLanLuuNhatKy : '') + '.txt';
    const t = 'D4Lister ' + BAN + ' — nhật ký lượt ' + thuMucLuot + '\n'
      + 'lúc: ' + new Date().toLocaleString('vi-VN') + '\n'
      + 'trang: ' + location.href + '\n'
      + 'số bước đã chụp: ' + soBuocDaChup + '\n'
      + '='.repeat(70) + '\n\n'
      + nhatKy.join('\n') + '\n';
    luuFileQuaNen(ten, t);
    ghi('AI fix bug: đã ghi ' + ten + ' (' + soBuocDaChup + ' bước)');
    nhac('AI fix bug: xong ' + thuMucLuot + ' — ' + soBuocDaChup + ' bước');
  }
  let daTuThem = false;   // moi lan dan chi tu them MOT lan
  // Đang chạy phần thêm affix. Chỉ "AI fix bug" dùng, để biết lượt đã hết
  // chạy chưa mà ghi nhật ký — mấy việc dài hơi khác đều đã có cờ riêng.
  let dangThemAffix = false;
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

    // CHỈ xét thứ nằm TRONG một dòng gợi ý thật.
    //
    // Khung popover còn chứa hàng nút lọc phân loại — All · Offensive ·
    // Defensive · Resource · Utility · Mobility — và chúng là
    // <button data-slot="toggle">, không phải gợi ý.
    //
    // Quét bừa cả button/div/span thì cái nút "All" đạt 100% với affix
    // "All Skills" (phép cắt đuôi "Skills" ở bẫy 70 làm hai bên bằng
    // nhau). Tiện ích bấm vào nút lọc, tưởng xong, rồi Enter chọn phải
    // dòng đang sáng — ra "Marksman Skills" lần thứ hai. Tệ hơn nữa: khớp
    // được NGAY nên nó thôi không đợi danh sách lọc lại, thành ra cứ nhìn
    // vào kết quả cũ của lượt trước. (Món PREPARED ASSAILANT'S EAGLE'S
    // EYE, 25/09/2026.)
    const DONG = '[cmdk-item],[role="option"],[data-slot="command-item"],li';
    const uv = [];
    for (const dong of khung.querySelectorAll(DONG)) {
      for (const el of [dong, ...dong.querySelectorAll('label,button,div,span')]) {
        const t = (el.textContent || '').trim();
        if (!t || t.length > 90) continue;
        const d = diemKhop(ten, t);
        if (d >= DIEM_NGO) uv.push({ el, t, d, h: hang(el) });
      }
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
    ghi('[D4Lister] tim khong ra:', { go: tk, o: o.value, dong: dong });
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

  //  Xoá những dòng vừa MỌC THÊM mà không phải dòng mình cần.
  //
  //  Nhận ra bằng cách đếm tên: so với lúc trước khi bấm, tên nào giờ xuất
  //  hiện nhiều hơn thì phần dôi ra là bản sao thừa. Đếm chứ không so vị
  //  trí, vì trang chèn dòng mới vào đâu là quyền của nó.
  //
  //  Xoá từ DƯỚI lên: dòng mới thường nằm cuối, mà xoá từ dưới thì mấy
  //  dòng trên không xê dịch. Đọc lại danh sách sau mỗi lần xoá — xoá xong
  //  là DOM đổi, danh sách cũ hết dùng được.
  //
  //  Chỉ làm ở chế độ BETA: CLASSIC dựng dòng theo lối khác, và người dùng
  //  không còn dùng nó.
  async function xoaDongThua(tenTruoc) {
    if (cheDo() === 'classic') return 0;
    const demTruoc = new Map();
    for (const t of tenTruoc) demTruoc.set(t, (demTruoc.get(t) || 0) + 1);

    let daXoa = 0;
    for (let vong = 0; vong < 4; vong++) {
      const nay = timCacDong();
      const demNay = new Map();
      for (const d of nay) demNay.set(d.ten, (demNay.get(d.ten) || 0) + 1);

      let i = -1;
      for (let k = nay.length - 1; k >= 0; k--)
        if ((demNay.get(nay[k].ten) || 0) > (demTruoc.get(nay[k].ten) || 0)) { i = k; break; }
      if (i < 0) break;

      const nut = nay[i].inp && khoiDongBeta(nay[i].inp)
        .querySelector('button[aria-label^="Remove "]');
      if (!nut) break;          // affix cố định của đồ Unique: không xoá được
      ghi('dọn dòng thừa: xoá "' + nay[i].ten + '"');
      bamThat(nut);
      daXoa++;
      await doi(160);
    }
    return daXoa;
  }

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

  // ====================================================================
  //  THEM AFFIX BANG CACH DAY THANG VAO FORM — khong bam phat nao
  //
  //  Muc trong danh muc affix cua trang co du: ma, cau mo ta "+# Willpower",
  //  loai, khoang hop le. Chi can them "values" va "isGreater" la thanh mot
  //  dong affix hoan chinh, day vao mang affixes la xong.
  //  Khong tim duoc danh muc, hoac day vao ma mang khong dai ra, thi tra ve
  //  false — vong ngoai tu quay ve duong go chu cu.
  // ====================================================================
  // Danh muc chi duoc trang dung ra khi danh sach ADD AFFIX mo. Hot duoc
  // mot lan roi thi NHO LUON VAO MAY — khong bao gio phai mo lai nua, ke ca
  // sau khi dong trinh duyet. Do la cai mo duy nhat con sot lai ma user
  // nhin thay; nho roi thi het han.
  const KHOA_KHO = 'd4lister-kho-affix-2';   // -2: ban truoc nho nham danh muc ASPECT
  let khoAffix = null;

  function nhoKho(ds) {
    try {
      localStorage.setItem(KHOA_KHO, JSON.stringify({ ngay: Date.now(), ds: ds }));
    } catch (e) { /* day bo nho thi thoi, lan sau mo lai */ }
  }

  function docKhoDaNho() {
    try {
      const t = localStorage.getItem(KHOA_KHO);
      if (!t) return null;
      const o = JSON.parse(t);
      // Qua 30 ngay thi hot lai — trang co the them affix moi theo mua.
      if (!o || !Array.isArray(o.ds) || Date.now() - o.ngay > 30 * 864e5) return null;
      return laKhoAffix(o.ds) ? o.ds : null;
    } catch (e) { return null; }
  }

  function layKhoAffix() {
    if (khoAffix) return khoAffix;
    const k = timKhoAffix();
    if (k) {
      khoAffix = k;
      nhoKho(k.ds);
      ghi('[D4Lister] danh mục affix: ' + k.ds.length + ' mục (' + k.tu + ')');
      return khoAffix;
    }
    const cu = docKhoDaNho();
    if (cu) {
      khoAffix = { ds: cu, tu: 'nhớ sẵn trong máy' };
      ghi('[D4Lister] danh mục affix: ' + cu.length + ' mục (nhớ sẵn)');
    }
    return khoAffix;
  }

  // react-hook-form quan ly mang dong bang useFieldArray, no tra ve
  //    { fields: [...], append(), remove(), ... }
  // Ghi de setValue('affixes', [...]) co khi KHONG dung ra dong moi, vi
  // useFieldArray giu so sach rieng. Phai goi dung append() cua no.
  // Lung trong cay React tim bo do.
  const laBoMang = o => !!o && typeof o === 'object' &&
    typeof o.append === 'function' && typeof o.remove === 'function' &&
    Array.isArray(o.fields);

  // Trang co nhieu mang dong (affixes, inherents, priceGroups...). Nhan ra
  // DUNG cai cua affixes bang cach DOI CHIEU voi chinh mang affixes dang co:
  // phai cung so muc, va muc dau phai cung ma. Doan theo hinh dang thi co
  // luc them nham vao inherents.
  const dungMangAffix = (o, cu) => {
    if (!laBoMang(o) || !Array.isArray(cu)) return false;
    if (o.fields.length !== cu.length) return false;
    if (!cu.length) return false;            // ca hai rong thi khong phan biet noi
    return !!o.fields[0] && !!cu[0] && o.fields[0].id === cu[0].id;
  };

  // ====================================================================
  //  BAY DA SUP MOT LAN — va no lam CHAM moi lan dan cua V3
  //
  //  Phep nhan dang tren doi chieu id cua muc dau tien, nen mang RONG thi
  //  chiu. Viet hoi V2 thi khong sao: luc do trang tu quet anh roi dung san
  //  cac dong, mang chua bao gio rong.
  //  V3 thi NGUOC LAI: ext tu dung mon, mon moi LUON co mang affixes rong.
  //  Vay la lan nao cung khong tim ra bo quan ly mang -> khong goi duoc
  //  append() -> ma setValue() len mot mang dong thi react-hook-form KHONG
  //  ve lai man hinh -> lan nao cung phai lui ve duong go chu tung dong.
  //  Do la cai "cham, giong kieu nguoi lam" ma user thay.
  //
  //  Mang rong thi doi chieu bang VI TRI thay vi bang ma: di nguoc len tu
  //  nut "ADD STANDARD AFFIXES", bo quan ly mang dong gan nhat tren duong
  //  di chinh la cua khoi affix. Khong ra thi quet ca cay lay moi bo dang
  //  rong lam ung vien, roi thu tung cai — thu bang chinh viec day that,
  //  khong an thi tra lai nguyen trang roi sang cai ke.
  // ====================================================================
  function boMangTuNut() {
    const nut = nutMoDs();
    if (!nut) return [];
    const k = Object.keys(nut).find(x => x.indexOf('__reactFiber$') === 0);
    if (!k) return [];
    const ra = [];
    for (let f = nut[k], i = 0; f && i < 60; f = f.return, i++) {
      let h = f.memoizedState, j = 0;
      while (h && typeof h === 'object' && j < 80) {
        const x = h.memoizedState;
        if (laBoMang(x)) ra.push(x);
        else if (x && typeof x === 'object' && !Array.isArray(x))
          for (const t of Object.keys(x)) if (laBoMang(x[t])) ra.push(x[t]);
        h = h.next; j++;
      }
    }
    return ra;
  }

  function quetBoMangRong() {
    const goc = fiberGoc();
    if (!goc) return [];
    const ra = [], ngan = [goc];
    let n = 0;
    const xet = x => { if (laBoMang(x) && !x.fields.length && ra.indexOf(x) < 0) ra.push(x); };
    while (ngan.length && n < 30000) {
      const f = ngan.pop();
      if (!f) continue;
      n++;
      let h = f.memoizedState, i = 0;
      while (h && typeof h === 'object' && i < 80) {
        const x = h.memoizedState;
        xet(x);
        if (x && typeof x === 'object' && !Array.isArray(x))
          for (const t of Object.keys(x)) xet(x[t]);
        h = h.next; i++;
      }
      if (f.child) ngan.push(f.child);
      if (f.sibling) ngan.push(f.sibling);
    }
    return ra;
  }

  //  Danh sach ung vien, cai nhieu kha nang nhat dung truoc.
  function cacBoMangAffix(cu) {
    const co = timBoMangAffix(cu);
    if (co) return [co];
    if (!Array.isArray(cu) || cu.length) return [];
    const ra = [];
    for (const x of boMangTuNut().filter(b => !b.fields.length).concat(quetBoMangRong()))
      if (ra.indexOf(x) < 0) ra.push(x);
    return ra;
  }

  function timBoMangAffix(cu) {
    const goc = fiberGoc();
    if (!goc) return null;
    const ngan = [goc];
    let n = 0;
    while (ngan.length && n < 30000) {
      const f = ngan.pop();
      if (!f) continue;
      n++;
      let h = f.memoizedState, i = 0;
      while (h && typeof h === 'object' && i < 80) {
        const x = h.memoizedState;
        if (dungMangAffix(x, cu)) return x;
        if (x && typeof x === 'object' && !Array.isArray(x))
          for (const t of Object.keys(x))
            if (dungMangAffix(x[t], cu)) return x[t];
        h = h.next; i++;
      }
      if (f.child) ngan.push(f.child);
      if (f.sibling) ngan.push(f.sibling);
    }
    return null;
  }

  // Vi sao lan truoc khong day duoc — de ghi vao file do.
  let viSaoTruot = null;
  let soDayThang = 0;      // dem so dong day thang duoc trong lan dan nay

  // Danh muc chi duoc dung ra khi danh sach ADD AFFIX mo. Quet ca cay ma
  // van khong thay, va cung chua nho san trong may, thi mo no MOT LAN cho
  // moi trang, hot lay danh muc roi dong lai.
  let daThuMoKho = false;

  async function layKhoAffixCoMo() {
    if (layKhoAffix()) return khoAffix;
    if (daThuMoKho) return null;
    daThuMoKho = true;
    const nut = nutMoDs();
    if (!nut) return null;
    const khung = await moDropdown(nut);
    if (!khung) return null;
    await doi(250);
    const co = layKhoAffix();
    dongDs(nut);
    await doi(150);
    return co;
  }

  // Tim mot muc trong danh muc, gan san con so va dau sao. Khong co thi null.
  function timMucTrongKho(tenTim, so, sao) {
    const kho = layKhoAffix();
    if (!kho) { viSaoTruot = 'khong tim ra danh muc affix'; return null; }
    // Danh muc tron ca aspect/inherent — chi khop trong dam AFFIX.
    const chiAffix = kho.ds.filter(x => x && x.type === 'AFFIX');
    const kq = timKhopNhat(tenTim, chiAffix, x => tenThuan(x.description || x.name || ''));
    if (kq.diem < DIEM_CHAC) {
      viSaoTruot = 'danh muc khong co ten "' + tenTim + '" (giong nhat ' +
        Math.round(kq.diem * 100) + '%)';
      return null;
    }
    return Object.assign({}, kq.muc, { values: [so], isGreater: !!sao });
  }

  // BAY DA SUP MOT LAN: day TUNG DONG MOT. Tu lan thu hai tro di, so sach
  // cua useFieldArray chua kip cap nhat nen doi chieu do dai bi lech ->
  // tuong khong co bo mang -> quay ve ghi de ca mang -> NUOT MAT dong vua
  // them o lan truoc. Da gap that: mon 4 affix ma form chi hien 3.
  // => Gom het roi day MOT LAN.
  async function dayCaLoat(ds) {
    if (!ds.length) return false;
    const fm = timFormTrang();
    if (!fm) { viSaoTruot = 'khong voi toi duoc bo dieu khien form'; return false; }

    let cu;
    try { cu = fm.getValues('affixes'); } catch (e) { cu = null; }
    // undefined = mang chua duoc dang ky (mon moi tinh) -> coi nhu rong
    if (cu === undefined) cu = [];
    if (!Array.isArray(cu)) { viSaoTruot = 'khong doc duoc mang affixes'; return false; }

    const domTruoc = soDongManHinh();
    const dsBo = cacBoMangAffix(cu);

    // BAY DA SUP MOT LAN (23/09/2026, mon Galvanic Azurite):
    // mang cua form di tu 1 len 4 dung y nhu mong doi, NHUNG man hinh van
    // chi ve MOT dong. Ba dong kia khong co o nhap nao ca, nen moi con so
    // ext ghi vao chung deu roi vao cho khong ai nhin thay — ma ham nay lai
    // bao thanh cong, nen duong du phong khong he chay.
    // => Mang phinh ra CHUA DU. Phai thay MAN HINH ve them dung bay nhieu o.
    const moi = cu.concat(ds);
    const an = cach => {
      ghi('[D4Lister] đẩy thẳng ' + ds.length + ' dòng một phát bằng ' + cach);
      return true;
    };
    const dat = async (ten, lam) => {
      const t = dem();
      try { lam(); } catch (e) { nhip('đẩy thẳng · ' + ten + ' · ném lỗi', t); return false; }
      let sau;
      try { sau = fm.getValues('affixes'); } catch (e) { sau = null; }
      if (sau === undefined) sau = [];
      if (!Array.isArray(sau) || sau.length !== moi.length) {
        nhip('đẩy thẳng · ' + ten + ' · sổ sách không đổi', t);
        return false;
      }
      // 450ms la du rong: React ve lai sau mot lan doi trang thai thi xong
      // trong vong mot khung hinh. De 1200ms thi thu bon duong ma hut ca
      // bon la dung im gan 5 giay truoc khi duong du phong bat dau — chinh
      // la cu khung truoc dong dau tien.
      const ve = !!(await cho(
        () => (soDongManHinh() >= domTruoc + ds.length ? true : null), 450));
      nhip('đẩy thẳng · ' + ten + ' · ' + (ve ? 'ĂN' : 'màn hình không vẽ'), t);
      return ve;
    };
    // Tra lai nguyen trang. Khong tra thi duong go chu them lan thu hai,
    // thanh ra moi dong nhan doi.
    const hoanTac = bo => {
      try {
        if (bo && typeof bo.replace === 'function') bo.replace(cu);
        else fm.setValue('affixes', cu, { shouldDirty: true });
      } catch (e) {}
    };

    // Duong 1: replace() cua useFieldArray — DAT CA MANG mot lan roi ve lai
    // ngay. Muot hon append(): khong cong don tung dot, khong phu thuoc so
    // sach cu, va la MOT lan ve thay vi nhieu lan.
    // Duong 1b: append(). Co ban react-hook-form cu khong co replace().
    // Mang dang rong thi co the co vai ung vien (affixes, inherents,
    // priceGroups... deu rong) — thu tung cai bang chinh viec day that.
    for (const bo of dsBo) {
      if (typeof bo.replace === 'function' && await dat('replace()', () => bo.replace(moi)))
        return an('replace() của useFieldArray');
      hoanTac(bo);
      if (await dat('append()', () => {
        try { bo.append(ds, { shouldFocus: false }); } catch (e) { bo.append(ds); }
      })) return an('append() của useFieldArray');
      hoanTac(bo);
    }

    // Duong 2: reset() CA FORM.
    // Day la cho khac han setValue(): setValue len mot mang dong chi doi so
    // sach, useFieldArray giu ban rieng nen man hinh dung im. Con reset()
    // dung lai TOAN BO form, ke ca cac mang dong — tuc cham toi duoc
    // useFieldArray ma khong can cam duoc chinh no.
    // Chep lai moi o hien co roi chi thay mang affixes, de khong xoa mat
    // gia, o ngoc, do hiem... nguoi dung da dat.
    if (typeof fm.reset === 'function' && await dat('reset() cả form', () => {
      const tatCa = fm.getValues() || {};
      fm.reset(Object.assign({}, tatCa, { affixes: moi }),
        { keepDefaultValues: true, keepErrors: true, keepDirty: true });
    })) return an('reset() cả form');
    hoanTac(null);

    // Duong 3: ghi de mang. It khi ve lai duoc, nhung khong mat gi ma thu.
    if (await dat('setValue cả mảng', () => fm.setValue('affixes', moi,
        { shouldDirty: true, shouldTouch: true, shouldValidate: true })))
      return an('setValue cả mảng');
    hoanTac(null);

    viSaoTruot = 'đẩy ' + ds.length + ' dòng mà màn hình vẫn '
      + soDongManHinh() + ' ô nhập, trước khi đẩy là ' + domTruoc
      + ', số ứng viên bộ quản lý mảng: ' + dsBo.length;
    return false;
  }

  async function themCacAffixThieu(thieu) {
    loiThem = [];
    nhac('Đang thêm ' + thieu.length + ' dòng còn thiếu…');

    let tB = dem();
    await layKhoAffixCoMo();
    nhip('lấy danh mục affix', tB);

    // Thu duong THANG truoc cho ca loat. Duoc het thi khong bam gi ca.
    const conLai = [], themVao = [], loiKho = [];
    for (const m of thieu) {
      const muc = timMucTrongKho(m.coThat || m.ten, m.so, m.sao);
      if (muc) { themVao.push(muc); continue; }
      conLai.push(m);
      // viSaoTruot bi ghi de sau moi lan tra, nen phai nhat ngay tai cho.
      loiKho.push((m.coThat || m.ten) + ' — ' + viSaoTruot);
    }
    const kho0 = layKhoAffix();
    ghi('[D4Lister] tra danh mục trang: ' + themVao.length + '/' + thieu.length +
      ' dòng tìm được. Danh mục ' + (kho0 ? kho0.ds.length + ' mục, ' +
        kho0.ds.filter(x => x && x.type === 'AFFIX').length + ' cái là AFFIX, lấy từ ' + kho0.tu
        : 'CHƯA ĐỌC ĐƯỢC') +
      (loiKho.length ? '\n   không tìm được: ' + loiKho.join('\n   ') : ''));
    if (themVao.length) {
      if (await dayCaLoat(themVao)) soDayThang += themVao.length;
      else for (const m of thieu) if (conLai.indexOf(m) < 0) conLai.push(m);
    }
    if (!conLai.length) {
      if (chuDaDan) apDung(chuDaDan, true);
      return;
    }
    // Phai quay ve duong go chu = co cai gi do sai. Ghi lai ngay, kem ly do,
    // de khoi phai bat user ta lai bang loi.
    ghi('[D4Lister] đẩy thẳng được ' + (thieu.length - conLai.length) +
      '/' + thieu.length + ' dòng, còn lại đi đường gõ chữ. Vì:', viSaoTruot);
    ghiNhatKy('phai-go-chu', {
      viSao: viSaoTruot,
      soDongPhaiGoChu: conLai.length,
      tenCacDongDo: conLai.map(x => x.coThat || x.ten),
      soDongDayDuoc: thieu.length - conLai.length,
      coBoDieuKhienForm: !!timFormTrang(),
      coDanhMuc: !!layKhoAffix(),
      soMucTrongDanhMuc: khoAffix ? khoAffix.ds.length : 0,
      soMucLaAFFIX: khoAffix ? khoAffix.ds.filter(x => x && x.type === 'AFFIX').length : 0,
      layDanhMucTu: khoAffix ? khoAffix.tu : null,
      // CHI lay vai o. Muc danh muc that co kem rollTiers hang tram dong —
      // dump ca cuc thi nhat ky phinh len vai chuc nghin ky tu, dan khong noi.
      mauMotMucDanhMuc: (khoAffix && khoAffix.ds[0]) ? {
        id: khoAffix.ds[0].id, name: khoAffix.ds[0].name,
        type: khoAffix.ds[0].type, description: khoAffix.ds[0].description,
      } : null,
      soUngVienBoMangDong: cacBoMangAffix(
        timFormTrang() ? timFormTrang().getValues('affixes') : null).length,
      cacUngVienForm: ungVienForm,
      soFiberDaQuet: soFiberDaQuet,
      mangGanGiongNhat: khoGanNhat,
      cacMangUngVien: cacUngVien,
      banExt: BAN,
    });
    thieu = conLai;

    let soXong = 0;
    for (const m of thieu) {
      const tDong = dem();
      // Tim bang TEN CHUAN CUA TRANG (thu vien da xac nhan), khong phai ten
      // OCR doc ra. "Life On Kill" de tim hon "LifeonKill".
      const tenTim = m.coThat || m.ten;

      const cl = cheDo() === 'classic';
      const tenNut = cl ? '+ ADD AFFIX' : 'ADD STANDARD AFFIXES';

      const nut = nutMoDs();
      if (!nut) { loiThem.push([m.ten, 'không thấy ô ' + tenNut]); break; }

      // GIU DANH SACH MO SUOT ca luot. Ban truoc moi dong deu dong roi mo
      // lai — ton gan mot giay moi dong, va nhin cu nhap nhay nhu nguoi
      // dang mo tay tung cai.
      let khung = dangMo(nut) ? khungPopover(nut) : await moDropdown(nut);

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

      // Danh sach dang mo san co khi DA co dong minh can (chua loc gi) —
      // thu tim truoc, trung thi khoi go chu luon.
      let g = (khung && dangHien(khung)) ? dongGoiY(khung, tenTim) : null;
      let tk = '';
      if (!g) for (const k of dsTuKhoa(tenTim)) {
        tk = k;
        if (cl && !dangMo(nut)) { bamThat(o); o.focus(); }
        goChu(o, k);
        if (!dangHien(khung)) khung = await cho(() => khungPopover(nut), 1200);
        if (!khung) continue;
        // NGO cho den khi danh sach that su co dong khop, thay vi ngu mot
        // khoang co dinh. Trang loc xong trong 80ms thi di tiep ngay 80ms.
        g = await cho(() => dongGoiY(khung, tenTim), 900)
          || await doCuonTim(khung, tenTim);
        if (g) break;
      }
      if (!khung) {
        loiThem.push([m.ten, 'gõ vào ô ' + tenNut + ' rồi mà danh sách vẫn không xổ ra']);
        continue;
      }
      if (!g) {
        // Chụp NGAY lúc danh sách đang xổ mà không khớp dòng nào — đóng
        // rồi thì không còn gì để xem.
        chupBuoc('them-affix-hong-' + m.ten.replace(/[^A-Za-z0-9]+/g, '-'));
        loiThem.push([m.ten, moTaThatBai(o, khung, tk)]);
        continue;
      }

      // CLASSIC lam mo di nhung dong DA CO tren form (aria-disabled). Gap
      // dong mo la affix von da nam tren form roi, bam cung khong an gi —
      // coi nhu xong, luot dien lai o cuoi se tim ra no.
      if (g.getAttribute && g.getAttribute('aria-disabled') === 'true')
        continue;

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
      // Chụp danh sách gợi ý TRƯỚC khi bấm, không phải chỉ lúc hỏng.
      //
      // Ca "Marksman Skills" nhân đôi lọt lưới đúng vì chỗ này: bản trước
      // coi như đã thêm được nên không chụp gì, và hồ sơ trắng đúng cái
      // bước cần xem.
      chupBuoc('add-' + tenTim.replace(/[^A-Za-z0-9]+/g, '-') + '-truoc-bam', khung);

      const tenTruoc = timCacDong().map(d => d.ten);
      let xong = false, daThu = [];
      for (const [ten, lam] of cach) {
        lam();
        // ĐÒI ĐÚNG DÒNG MÌNH CẦN. Bản trước nhận cả "số dòng tăng lên" là
        // xong, kèm ghi chú "dù tên có khớp hay không" — và đó là chỗ sai.
        //
        // Bấm hụt thì trang đẻ ra một BẢN SAO của dòng vừa thêm trước đó.
        // Số dòng vẫn tăng, mã reo xong, còn dòng thật thì chưa hề có. Món
        // PREPARED ASSAILANT'S EAGLE'S EYE ra "Marksman Skills" HAI lần và
        // mất hẳn "All Skills" (25/09/2026) — không một lời báo.
        xong = await cho(() => daCoDong(tenTim), 1600);
        if (xong) break;
        daThu.push(ten);
      }
      if (!xong) {
        // Dọn bản sao thừa mà mấy cú bấm hụt để lại. Không dọn thì nó lên
        // sàn nguyên xi như một chỉ số có thật.
        const soXoa = await xoaDongThua(tenTruoc);
        loiThem.push([m.ten, 'thấy dòng rồi nhưng không chọn được. Đã thử: '
          + daThu.join(', ')
          + (soXoa ? ' · đã xoá ' + soXoa + ' dòng thừa trang tự đẻ ra' : '')]);
      }

      nhip('thêm dòng ' + (++soXong) + '/' + thieu.length + ' — '
        + (m.coThat || m.ten) + (xong ? '' : ' (KHÔNG ĐƯỢC)'), tDong);
      // KHONG dong danh sach o day — dong ke tiep dung lai duoc ngay.
      // Dong roi mo lai moi dong la cho ton thoi gian nhat ca luot.
    }
    const nutCuoi = nutMoDs();
    if (nutCuoi && dangMo(nutCuoi)) dongDs(nutCuoi);
    await doi(250);
    nhip('xong phần thêm dòng');
    if (chuDaDan) apDung(chuDaDan, true);   // dien lai, lan nay co dong moi
  }


  const thoat = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));

  function khungBao() {
    document.getElementById('d4l-bao')?.remove();
    const d = document.createElement('div');
    d.id = 'd4l-bao';
    d.style.cssText = 'position:fixed;right:12px;bottom:42px;z-index:999999;width:250px;' +
      'max-height:70vh;overflow:auto;overflow-wrap:break-word;' +
      'background:#14141a;color:#eee;border:1px solid #444;border-radius:8px;padding:9px 11px;' +
      'font:12.5px/1.45 system-ui,sans-serif;box-shadow:0 8px 28px rgba(0,0,0,.6)';
    document.body.appendChild(d);
    return d;
  }



  // --- BẢNG THIẾT LẬP ---------------------------------------------------
  //  Bấm vào chip góc dưới bên trái là mở ra. Lưu trong trình duyệt nên
  //  đổi xong là dùng ngay, không phải sửa file, không phải nạp lại.
  // Thiet lap. Gat la LUU LUON — khong co nut Luu, khong co dong mo ta duoi
  // moi cong tac: ten cong tac da du ro, them chu chi lam bang dai ra.
  // --- THIẾT LẬP --------------------------------------------------------
  //  Chia hai tab vì hai loại người đọc khác nhau.
  //
  //  "General" chỉ có những thứ NGƯỜI BÁN thật sự phải quyết: đăng tự động
  //  hay không, chờ mấy giây, giá có tự điền không. Ba câu hỏi, trả lời một
  //  lần rồi thôi.
  //
  //  Mọi thứ còn lại là CÁCH TIỆN ÍCH LÀM VIỆC. Tắt đi thì tiện ích hỏng
  //  chứ không phải "chạy kiểu khác" — nên nhét chung một bảng với bốn cái
  //  trên là mời người ta bấm nhầm.
  //
  //  Mỗi mục có chữ giải thích khi rê chuột, thay cho việc in hết ra màn
  //  hình. Bảng rộng 250px, in hết thì thành bức tường chữ.
  let tabThietLap = 'dung';

  const GIAI_THICH = {
    tuDang: 'Điền xong thì tự bấm Submit, sau khi đếm ngược hết giờ.\n'
          + 'Còn cảnh báo (số vượt khoảng, thiếu affix…) thì cảnh báo vẫn\n'
          + 'hiện trong lúc đếm — đọc thấy không ổn thì bấm Esc để dừng.\n'
          + 'Tắt đi thì tiện ích vẫn điền, chỉ là bạn tự bấm đăng.',
    demNguoc: 'Chờ ngần này giây trước khi bấm Submit, để bạn kịp đọc lại\n'
          + 'hoặc kịp bấm huỷ.',
    nhayVaoGia: 'Giá đã đặt sẵn trong game (F3) thì điền thẳng vào ô Price.\n'
          + 'Chưa đặt thì điền xong affix là đặt con trỏ vào ô Price, bạn\n'
          + 'chỉ còn gõ giá rồi Enter.',
    tuTaoItem: 'V3 không còn ảnh để trang tự dựng món, nên tiện ích phải tự\n'
          + 'dựng: chọn loại đồ, độ hiếm, rồi Aspect.\n'
          + 'TẮT = tiện ích không điền được gì cả.',
    tuChonBase: 'Tự chọn ô base rồi bấm Next, khỏi ngồi chọn hình.',
    tuThemAffix: 'Trang chỉ dựng sẵn vài dòng affix. Món có nhiều dòng hơn thì\n'
          + 'tiện ích tự bấm thêm dòng cho đủ.',
    tuDauSao: 'Tự bật dấu sao cho dòng Greater Affix, và tắt cho dòng thường.',
    ghiThangForm: 'Đọc KHOẢNG HỢP LỆ (min–max) từ bộ điều khiển form của trang.\n'
          + 'Nhờ nó mới biết một dòng có vượt khoảng hay không.\n'
          + 'Tắt đi thì mất phần kiểm tra đó.',
    doDOM: 'Ghi cấu trúc trang ra Console sau khi dựng món.\n'
          + 'Chỉ bật khi đang dò lỗi.',
    ghiFileDo: 'Tải hẳn một file .json kết quả dò về máy mỗi lần chạy.\n'
          + 'Chỉ bật khi cần gửi file đi.',
    aiChup: 'Mỗi món dán vào, chụp cấu trúc trang ở TỪNG bước — từ lúc nhận\n'
          + 'chữ cho tới lúc điền giá và tự bấm Submit — rồi lưu xuống máy.\n'
          + 'Mỗi lượt một thư mục riêng đặt tên theo giờ, trong thư mục\n'
          + 'Tải xuống\\d4l-hoso\\. Đưa Claude đọc cả thư mục là biết lượt đó\n'
          + 'đi tới đâu thì đứng.\n'
          + 'Ghi khá nhiều file, xong việc thì tắt đi.',
  };

  function moThietLap() {
    // NAM TRONG bang ket qua, khong de ra hop thu hai chong len nhau.
    const d = khungBao();

    const o = (khoa, nhan) =>
      '<label title="' + (GIAI_THICH[khoa] || '').replace(/"/g, '&quot;') + '"' +
      ' style="display:flex;gap:8px;align-items:flex-start;margin-top:7px;cursor:help">' +
      '<input type="checkbox" data-k="' + khoa + '"' + (CD[khoa] ? ' checked' : '') +
      ' style="margin-top:2px;cursor:pointer">' +
      '<span>' + nhan + '</span></label>';

    const nut = (id, chu) =>
      '<button id="' + id + '" style="background:#2a2a32;color:#bbb;border:1px solid #555;' +
      'border-radius:5px;padding:4px 9px;cursor:pointer;font:12px system-ui">' + chu + '</button>';

    const theTab = (ma, chu) =>
      '<div data-tab="' + ma + '" style="flex:1;text-align:center;padding:5px 0;cursor:pointer;' +
      'border-bottom:2px solid ' + (tabThietLap === ma ? '#d8b978' : 'transparent') + ';' +
      'color:' + (tabThietLap === ma ? '#d8b978' : '#888') + ';font-size:12px">' + chu + '</div>';

    let than;
    if (tabThietLap === 'dung') {
      than =
        o('tuDang', 'Tự động đăng') +
        '<div title="' + GIAI_THICH.demNguoc.replace(/"/g, '&quot;') + '"' +
        ' style="margin-top:9px;display:flex;align-items:center;gap:6px;cursor:help">' +
        '<span>Đăng sau:</span>' +
        '<input id="d4l-tl-giay" type="number" min="1" max="60" value="' + (CD.demNguoc | 0) + '"' +
        ' style="width:48px;background:#0d0d12;color:#eee;border:1px solid #555;border-radius:4px;' +
        'padding:2px 5px;font:13px system-ui">' +
        '<span>s</span></div>' +
        o('nhayVaoGia', 'Tự động nhập giá') +
        '<div style="margin-top:12px">' + nut('d4l-tl-goc', 'Về mặc định') + '</div>';
    } else {
      than =
        '<div style="margin-top:7px;color:#8a7f5a;font-size:11px;line-height:1.4">' +
        'Mấy mục này đổi cách tiện ích làm việc. Tắt đi phần lớn là hỏng, ' +
        'không phải chạy kiểu khác. Rê chuột lên từng mục để xem nó làm gì.' +
        '</div>' +
        o('tuTaoItem', 'Tự dựng món') +
        o('tuChonBase', 'Tự chọn base') +
        o('tuThemAffix', 'Tự thêm affix thiếu') +
        o('tuDauSao', 'Tự bật dấu sao') +
        o('ghiThangForm', 'Đọc khoảng hợp lệ từ form') +
        o('doDOM', 'Ghi cấu trúc ra Console') +
        o('ghiFileDo', 'Tải file dò về máy') +
        o('aiChup', 'AI fix bug') +
        '<div style="margin-top:11px;display:flex;flex-wrap:wrap;align-items:center;gap:6px">' +
        nut('d4l-tl-do', 'Dò lớp phủ') + nut('d4l-tl-nk', 'Chép nhật ký') +
        '</div>' +
        '<div style="margin-top:7px;color:#666;font-size:11px">Ctrl+Shift+D chạy lại</div>';
    }

    d.innerHTML =
      '<div style="display:flex;align-items:center">' +
      '<b style="color:#d8b978;flex:1">Thiết lập</b>' +
      '<span id="d4l-tl-dong" style="cursor:pointer;color:#888">&#10005;</span></div>' +
      '<div style="display:flex;margin-top:8px;border-bottom:1px solid #333">' +
      theTab('dung', 'General') + theTab('dev', 'Advanced') + '</div>' +
      than;

    d.querySelectorAll('[data-tab]').forEach(t => {
      t.onclick = () => { tabThietLap = t.dataset.tab; moThietLap(); };
    });
    d.querySelector('#d4l-tl-dong').onclick = () => d.remove();
    d.querySelectorAll('input[type=checkbox]').forEach(i => {
      i.onchange = () => { CD[i.dataset.k] = i.checked; luuCaiDat(); };
    });

    const oGiay = d.querySelector('#d4l-tl-giay');
    if (oGiay) oGiay.onchange = e => {
      const g = parseInt(e.target.value, 10);
      if (g >= 1 && g <= 60) { CD.demNguoc = g; luuCaiDat(); }
    };

    const nutGoc = d.querySelector('#d4l-tl-goc');
    if (nutGoc) nutGoc.onclick = () => {
      CD = Object.assign({}, MAC_DINH);
      luuCaiDat();
      moThietLap();
    };

    // Do lop phu: mo lan luot cac o chon o dau form roi ghi cai xo ra vao
    // Console. Ban luu Ctrl+S khong chup duoc may lop phu nay.
    const nutDo = d.querySelector('#d4l-tl-do');
    if (nutDo) nutDo.onclick = () => { d.remove(); doDOM('trước khi dò'); doLopPhu(); };

    // LUU NHAT KY RA FILE roi chep ĐƯỜNG DẪN.
    //
    // Trước đây nút này chép cả xấp chữ vào clipboard, người dùng phải dán
    // nguyên mấy chục dòng vào khung chat. Nay tải hẳn ra file trong thư
    // mục Tải xuống, clipboard chỉ giữ đường dẫn — gửi một dòng là xong.
    //
    // Chỉ chép TÊN FILE, không đoán thư mục. Lần đầu tôi ghép sẵn
    // "%USERPROFILE%\Downloads\…" — sai, máy người dùng đặt Chrome tải về
    // thẳng thư mục dự án. Trang web không có cách nào biết chỗ đó, nên
    // đừng bịa: đưa tên file là đủ để đi tìm.
    const nutNK = d.querySelector('#d4l-tl-nk');
    if (nutNK) nutNK.onclick = () => {
      const t = 'D4Lister ' + BAN + ' — nhật ký ' + nhatKy.length + ' dòng\n'
        + '='.repeat(60) + '\n' + nhatKy.join('\n');
      const g = new Date();
      const hai = n => String(n).padStart(2, '0');
      const ten = 'd4lister-' + g.getFullYear() + hai(g.getMonth() + 1) + hai(g.getDate())
        + '-' + hai(g.getHours()) + hai(g.getMinutes()) + hai(g.getSeconds()) + '.txt';
      const duong = ten;

      try {
        const u = URL.createObjectURL(new Blob([t], { type: 'text/plain;charset=utf-8' }));
        const a = document.createElement('a');
        a.href = u;
        a.download = ten;
        document.body.appendChild(a);
        a.click();
        a.remove();
        setTimeout(() => URL.revokeObjectURL(u), 4000);
      } catch (e) {
        nhac('Không lưu được file nhật ký — xem Console');
        return;
      }

      const xong = () => nhac('Đã lưu ' + nhatKy.length + ' dòng → ' + ten
        + '  (tên file đã chép, dán cho Claude)');
      try {
        navigator.clipboard.writeText(duong).then(xong, () => {
          const ta = document.createElement('textarea');
          ta.value = duong;
          ta.style.cssText = 'position:fixed;left:-9999px';
          document.body.appendChild(ta);
          ta.select();
          document.execCommand('copy');
          ta.remove();
          xong();
        });
      } catch (e) { nhac('Đã lưu ' + ten + ' nhưng không chép được đường dẫn'); }
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
    tuDang:           true,   // tự bấm SUBMIT sau khi đếm ngược
    demNguoc:         5,      // giây đếm ngược trước khi bấm đăng
    tuThemAffix:      true,   // tự thêm dòng affix trang không dựng ra
    tuDauSao:         true,   // tự bật/tắt dấu sao Greater Affix
    ghiThangForm:     true,   // ghi thẳng vào form của trang, khỏi gõ vào ô
    nhayVaoGia:       true,   // điền xong thì đặt con trỏ vào ô giá
    ghiFileDo:        false,  // tải file dò về máy (chỉ bật khi cần gửi cho Claude)
    tuChonBase:       true,   // tự chọn base rồi bấm Next, khỏi phải chọn hình
    tuTaoItem:        true,   // V3: tự dựng món từ đầu (không còn ảnh để trang quét)
    doDOM:            false,  // ghi cấu trúc trang ra Console sau khi dựng món
    aiChup:           false,  // chụp từng bước + nhật ký ra file, để Claude đọc
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

  // O nhap gia. Cung mot moc o ca hai che do.
  const oGia = () =>
    [...document.querySelectorAll('input[placeholder="Price"]')]
      .find(i => i.offsetParent !== null && !i.disabled) || null;

  // Dien xong thi dat con tro vao o gia luon — user chi con go so roi Enter.
  function nhayVaoOGia() {
    const o = oGia();
    if (!o) return false;
    try {
      o.focus({ preventScroll: false });
      o.select();
    } catch (e) { try { o.focus(); } catch (e2) {} }
    return document.activeElement === o;
  }

  // --- gia dat san tu trong game --------------------------------------
  //  D4Lister ghi them mot dong "#D4L-GIA:50b" vao cuoi file cua mon, luc
  //  bam F3 trong game. Doc dong do roi dien thang vao o Price.
  //
  //  O Price nhan chu tat nguyen dang — "50b", khong phai 50000000000.
  //  Nhung van doc lai xem trang giu duoc gi: trang doi luat luc nao khong
  //  ai bao, ma dang gia rong thi hong that. Khong giu duoc thi tra ve
  //  false, luc do chay lai duong cu — nhay con tro vao o gia cho nguoi
  //  dung tu go.
  function dienGiaTuChu(text) {
    const m = /^[ \t]*#D4L-GIA:(.*)$/m.exec(String(text || ''));
    if (!m) return false;
    const chu = m[1].trim();
    if (!chu) return false;
    const o = oGia();
    if (!o) { ghi('Co gia "' + chu + '" nhung khong thay o Price'); return false; }

    datGiaTri(o, chu);
    const con = String(o.value || '').trim();
    if (!con || !/\d/.test(con)) {
      datGiaTri(o, '');
      ghi('O Price khong nhan gia "' + chu + '" — moi tu go');
      chupBuoc('gia-khong-vao-duoc');
      return false;
    }
    // ĐÒI KHỚP TỪNG KÝ TỰ, không chỉ "có chữ số".
    //
    // Phép kiểm cũ chỉ hỏi ô có chữ số hay không. Trang cắt bớt giá — gõ
    // 1200b mà nó giữ 999b chẳng hạn — thì phép kiểm ấy vẫn báo THÀNH CÔNG,
    // và món lên sàn với giá khác hẳn giá mình đặt, không ai biết.
    if (con.toLowerCase() !== chu.toLowerCase()) {
      giaBiDoi = { gui: chu, nhan: con };
      ghi('CẢNH BÁO GIÁ: gửi "' + chu + '" mà ô Price giữ "' + con + '"');
      chupBuoc('gia-bi-trang-doi');
      return true;      // vẫn coi là đã điền, nhưng sẽ báo đỏ và chặn tự đăng
    }
    giaBiDoi = null;
    ghi('Da dien gia: ' + chu + ' -> o Price hien "' + con + '"');
    chupBuoc('gia-da-dien');
    return true;
  }

  // Noi cho nguoi dung thay gia da vao chua. Khong co dau hieu nay thi luc
  // gia KHONG duoc dien nhin y het luc duoc dien — vua roi mat mot vong
  // qua lai chi de biet no co chay hay khong.
  function baoGia(text, xong) {
    const el = document.getElementById('d4l-gia');
    if (!el) return;
    const m = /^[ \t]*#D4L-GIA:(.*)$/m.exec(String(text || ''));
    const chu = m ? m[1].trim() : '';
    if (!chu)
      el.innerHTML = '<span style="color:#888">giá: chưa đặt trong game</span>';
    else if (xong)
      el.innerHTML = '<span style="color:#7ec97e">giá <b>' + thoat(chu) + '</b> đã điền</span>';
    else
      el.innerHTML = '<span style="color:#e08a5a">có giá ' + thoat(chu) +
        ' nhưng KHÔNG điền được — tự gõ giúp</span>';
  }

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
    // Còn cảnh báo thì KHÔNG chặn nữa — người dùng gộp hai công tắc cũ
    // ("tự đăng khi sạch" + "đăng cả khi có cảnh báo") thành một. Đổi lại
    // cảnh báo được nhắc ngay trong lúc đếm ngược, và Esc dừng được.
    let con = Math.max(1, CD.demNguoc | 0);
    const ve = () => {
      el.innerHTML =
        (sach ? ''
              : '<div style="color:#e8c05a;font-size:12px">Còn cảnh báo ở trên — '
                + 'thấy không ổn thì bấm Esc để dừng.</div>') +
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
      chupBuoc('truoc-bam-submit');
      bamThat(nut);
      el.innerHTML = '<span style="color:#7ec97e;font-size:13px">Đã đăng. Bấm F5 để sang món kế.</span>';
      // Đợi trang kịp phản ứng rồi mới chụp — chụp ngay thì chỉ thấy đúng
      // cái form vừa nhìn thấy trước khi bấm, không biết đăng trúng hay hỏng.
      setTimeout(() => chupBuoc('sau-bam-submit'), 1500);
    }, 1000);
  }

  document.addEventListener('keydown', e => {
    // Enter KHI DANG O O GIA = bam Submit. Chi trong o gia thoi — Enter o
    // cho khac van la Enter binh thuong (o tim affix chang han).
    if (e.key === 'Enter' && !e.ctrlKey && !e.shiftKey && !e.altKey) {
      const og = oGia();
      if (og && document.activeElement === og) {
        const nut = nutDang();
        if (nut) {
          e.preventDefault();
          e.stopPropagation();
          huyDang(document.getElementById('d4l-dang'), 'Đã bấm đăng.');
          chupBuoc('truoc-bam-submit-bang-enter');
          bamThat(nut);
          setTimeout(() => chupBuoc('sau-bam-submit-bang-enter'), 1500);
          return;
        }
      }
    }
    // Ctrl+Enter = đăng ngay. Dùng khi bạn vừa gõ giá xong: gõ phím làm dừng
    // đếm ngược, nên cần một phím để nói "tôi xong rồi, đăng đi".
    if (e.ctrlKey && e.key === 'Enter') {
      const nut = nutDang();
      if (!nut) return;
      e.preventDefault();
      huyDang(document.getElementById('d4l-dang'), 'Đã bấm đăng.');
      chupBuoc('truoc-bam-submit-ctrl-enter');
      bamThat(nut);
      setTimeout(() => chupBuoc('sau-bam-submit-ctrl-enter'), 1500);
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
  // Bang ket qua. Nguyen tac: mot dong mot y, KHONG giai thich. Cai gi
  // user doc mot lan roi thuoc thi bo han — de lai chi lam roi mat.
  // Chi tiet dai (ly do that bai...) day sang Console.
  function bao(ok, ngoai, thieu, loi, doiSao, banTrenDia, nghiNgo, lech) {
    const d = khungBao();
    const ten = layTenItemTrenForm();

    // Mot hang duy nhat: ten mon | banh rang | dong
    let h = '<div style="display:flex;align-items:center;gap:6px">' +
      '<b style="color:#d8b978;flex:0 0 auto">D4Lister</b>' +
      '<span style="color:#9aa;font-size:12px;flex:1 1 auto;overflow:hidden;' +
      'text-overflow:ellipsis;white-space:nowrap">' + thoat(ten || '') + '</span>' +
      '<span id="d4l-cai" title="Thiết lập" style="cursor:pointer;color:#888;' +
      'flex:0 0 auto;font-size:14px">&#9881;</span>' +
      '<span id="d4l-dong" style="cursor:pointer;color:#888;flex:0 0 auto">&#10005;</span></div>';

    if (loi) h += '<div style="margin-top:6px;color:#e08a5a">' + loi + '</div>';

    // ok + ngoai DEU da duoc ghi vao o. Khac nhau o cho ngoai khung co ban.
    const daGhi = ok.concat(ngoai);
    if (daGhi.length) {
      // Cho biet no ghi bang DUONG NAO. Khong co dau hieu nay thi luc moi
      // thu chay tron tru trong y het luc no khong chay gi ca.
      const thang = daGhi.some(x => x.dong && x.dong.qua === 'form');
      h += '<div id="d4l-mo" style="margin-top:6px;color:#7ec97e;cursor:pointer">' +
        '<span id="d4l-mui">&#9656;</span> Đã điền ' + daGhi.length + ' dòng' +
        (thang ? '<span title="ghi thẳng vào form, không gõ chữ"' +
                 ' style="color:#7ec9c9"> &#9889; thẳng</span>' : '') +
        (soDayThang ? '<span style="color:#7ec9c9"> · +' + soDayThang +
                      ' thêm thẳng</span>' : '') + '</div>' +
        '<div id="d4l-ct" style="display:none;color:#bbb;font-size:12px;margin-left:12px">' +
        daGhi.map(x => thoat(x.dong.ten) + ' = <b>' + x.v + '</b>').join('<br>') + '</div>';
    }
    h += '<div id="d4l-gia" style="margin-top:4px;font-size:12px"></div>';
    if (ngoai.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Cao hơn khoảng của trang</div>';
      h += ngoai.map(x => '<div style="margin-left:12px">' + thoat(x.dong.ten) + ' = <b>' +
        x.v + '</b> <span style="color:#888">(' + x.dong.min + '–' + x.dong.max +
        ')</span></div>').join('');
    }
    if (nghiNgo && nghiNgo.length) {
      h += '<div style="margin-top:8px;color:#e8c05a">Không chắc — bạn xem giúp</div>';
      h += nghiNgo.map(x => '<div style="margin-left:12px">' + thoat(x.ten) + ' = <b>' +
        x.so + (x.phanTram ? '%' : '') + '</b> <span style="color:#888">~ ' +
        thoat(x.dong ? x.dong.ten : '?') + ' ' + Math.round(x.diem * 100) + '%</span></div>').join('');
    }
    if (thieu.length) {
      const coThat = thieu.filter(x => x.coThat);
      if (coThat.length) {
        h += '<div style="margin-top:8px;color:#e08a5a">Trang chưa có dòng này</div>';
        h += coThat.map(x => '<div style="margin-left:12px">' + thoat(x.coThat) + ' = <b>' +
          x.so + (x.phanTram ? '%' : '') + '</b></div>').join('');
        h += '<div style="margin-top:6px"><button id="d4l-them" style="background:#23402a;' +
          'color:#cfe8cf;border:1px solid #4a7a52;border-radius:5px;padding:4px 9px;' +
          'cursor:pointer;font:12px system-ui">Thêm giúp tôi</button></div>';
      }
    }
    // Viet vao roi doc lai thay o ghi so khac -> trang khong nhan.
    if (lech && lech.length) {
      h += '<div style="margin-top:8px;color:#e06a5a">Trang không nhận số này</div>';
      h += lech.map(x => '<div style="margin-left:12px">' + thoat(x.dong.ten) +
        ': <b>' + x.v + '</b> &#8594; <b>' + x.thuc + '</b></div>').join('');
    }
    if (doiSao && doiSao.length) {
      h += '<div style="margin-top:8px;color:#c9a227">' +
        doiSao.map(x => '&#10039; ' + (x.bat ? 'bật' : 'tắt') + ': ' +
          thoat(x.ten)).join('<br>') + '</div>';
    }
    if (loiThem.length) {
      // Ly do that bai la chu ky thuat dai — day sang Console, o day chi bao TEN.
      ghi('[D4Lister] thêm không được:', loiThem);
      h += '<div style="margin-top:8px;color:#e06a5a">Thêm không được: ' +
        loiThem.map(x => thoat(x[0])).join(', ') + '</div>';
    }
    if (canhBaoLoaiDo) {
      h += '<div style="margin-top:8px;color:#e06a5a">&#9888; ' +
        thoat(canhBaoLoaiDo) + '</div>';
    }
    if (khongBietSao) {
      h += '<div style="margin-top:8px;color:#e8c05a">&#10039; Dấu sao để nguyên — '
        + 'game không in khoảng [min - max] nên không biết dòng nào là Greater '
        + 'Affix. Bật Options &gt; Gameplay &gt; Advanced Tooltip Information '
        + 'rồi chụp lại, hoặc tự bấm dấu sao.</div>';
    }
    if (giaBiDoi) {
      h += '<div style="margin-top:8px;color:#e06a5a">&#9888; GIÁ BỊ ĐỔI: đặt <b>'
        + thoat(giaBiDoi.gui) + '</b> mà ô Price giữ <b>' + thoat(giaBiDoi.nhan)
        + '</b> — sửa lại rồi hãy đăng</div>';
    }

    // TỰ KIỂM LOẠI ĐỒ. Chữ của game nói món gì, trang dựng ra món gì — hai
    // cái phải khớp. Không khớp thì cả cái listing sai (khoảng hợp lệ của
    // affix khác hẳn, có dòng còn không tồn tại), mà trước nay chạy êm ru.
    let saiLoaiDo = false;
    try {
      const dongG = (chuDaDan || '').split(/\r?\n/).map(x => x.trim()).filter(Boolean)[1] || '';
      const Lg = tachDongLoai(dongG);
      const ltChu = loaiTrenForm();
      const Lt = tachDongLoai(ltChu);
      ghi('Loại đồ — game: "' + dongG + '"  ·  trang: "' + ltChu + '"');
      if (Lg.loai && Lt.loai
          && tenThuan(Lg.loai).toLowerCase() !== tenThuan(Lt.loai).toLowerCase()) {
        h += '<div style="margin-top:8px;color:#e06a5a">&#9888; SAI LOẠI ĐỒ: game là <b>'
          + thoat(Lg.loai) + '</b> mà trang dựng ra <b>' + thoat(Lt.loai)
          + '</b> — sửa lại trên form rồi hãy đăng</div>';
        ghi('CẢNH BÁO SAI LOẠI ĐỒ: game "' + Lg.loai + '" ≠ trang "' + Lt.loai + '"');
        saiLoaiDo = true;
      }
    } catch (e) { ghi('tự kiểm loại đồ hỏng: ' + e); }

    // Ban tren dia moi hon ban dang chay -> Chrome chua nap lai. Cai nay
    // GIU NGUYEN do dai: khong biet thi user chay ban cu ca ngay khong hay.
    //
    // CHI bao khi DIA MOI HON, khong phai khi "khac nhau". Hai le:
    //   1. So nay nam san trong file .txt cua mon do, duoc ghi luc CHUP mon.
    //      Dan lai mot mon chup tu truoc khi nang ban thi no mang so cu —
    //      dang chay 7.2 ma file ghi 7.1 la chuyen binh thuong, khong hong gi.
    //   2. Bao nham nhu vay thi lan sau bao that cung khong ai tin.
    if (banTrenDia && soSanhBan(banTrenDia, BAN) > 0) {
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
    d.innerHTML = h;
    d.querySelector('#d4l-dong').onclick = () => d.remove();
    d.querySelector('#d4l-cai').onclick = () => moThietLap();
    const mo = d.querySelector('#d4l-mo');
    if (mo) mo.onclick = () => {
      const ct = d.querySelector('#d4l-ct');
      const hien = ct.style.display === 'none';
      ct.style.display = hien ? 'block' : 'none';
      d.querySelector('#d4l-mui').innerHTML = hien ? '&#9662;' : '&#9656;';
    };
    const nt = d.querySelector('#d4l-them');
    if (nt) nt.onclick = () => themCacAffixThieu(thieu.filter(x => x.coThat));

    // Sạch = không dòng nào vượt khoảng, không thiếu affix, không lỗi, VÀ
    // loại đồ trên trang khớp với chữ của game. Sai loại đồ mà vẫn tự đăng
    // thì món lên sàn với khoảng affix của một loại đồ khác hẳn.
    const sach = !ngoai.length && !thieu.length && !loiThem.length && !loi
               && !(nghiNgo && nghiNgo.length) && !(lech && lech.length)
               && !saiLoaiDo && !giaBiDoi && daGhi.length > 0;

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
      dangThemAffix = true;
      // xong sẽ tự gọi lại apDung -> vẽ lại bảng
      themCacAffixThieu(themDuoc).finally(() => { dangThemAffix = false; });
      return;
    }
    // Gia da dat tu trong game (F3). Dien luon thi tren web khong con viec
    // gi can tay nguoi: go gia la thu DUY NHAT truoc day con pha tu dong.
    // Dat TRUOC xetTuDang de luc dem nguoc chay thi o gia da co so roi.
    // Dien bang datGiaTri nen khong sinh keydown — dem nguoc khong bi huy.
    //
    // chuDaDan chu khong phai text: cho nay nam trong ham VE BANG KET QUA,
    // khong phai apDung — ham nay khong co tham so nao ten text. Viet nham
    // thi moi lan dan la mot ReferenceError, va vi no nam sau phan da ve
    // xong nen bang ket qua van hien binh thuong, nhin khong ra.
    // MỘT công tắc lo cả hai việc: có giá sẵn thì điền thẳng, chưa có thì
    // lát nữa đặt con trỏ vào ô giá cho gõ tay.
    const daDatGia = CD.nhayVaoGia ? dienGiaTuChu(chuDaDan) : false;
    if (CD.nhayVaoGia) baoGia(chuDaDan, daDatGia);

    xetTuDang(d.querySelector('#d4l-dang'), sach);

    // Dat con tro vao o gia. Lam SAU CUNG, vi luc ve bang co the cuop mat
    // con tro. Doi mot nhip cho trang ve xong roi hang.
    // Co gia san roi thi KHONG nhay vao nua: hang con tro o do chi tao co
    // hoi go nham vao, ma go mot phim la dem nguoc dung.
    if (CD.nhayVaoGia && daGhi.length && !daDatGia)
      setTimeout(() => { if (!dongHoDang || CD.demNguoc > 1) nhayVaoOGia(); }, 60);

    // Chụp trạng thái sau khi điền xong bảng. Chưa phải bước cuối: còn cú
    // bấm Submit lúc đếm ngược hết giờ, chụp ở xetTuDang.
    chupBuoc('9-sau-khi-dien');
  }

  // ====================================================================
  //  TAO ITEM TU DAU   (V3 — khong con anh de trang tu quet)
  //
  //  V2: dan ANH -> bam SCAN -> TRANG tu dung ra mon (loai do, do hiem,
  //      ten) -> ext chi dien con so vao cac dong san co.
  //  V3: khong co anh nua, nen EXT phai tu dung ra mon.
  //
  //  Hop thoai ADD ITEM cua che do BETA, do tren ban luu 23/09/2026:
  //
  //    div[cmdk-root]
  //      input[placeholder="Add item…"]              <- go vao day de loc
  //      button[aria-label="Clear all"]
  //      div[role=listbox][aria-label="Suggestions"][cmdk-list]
  //        div[role=option][cmdk-item][data-value="unique:<uuid>"]
  //          img[alt="Galvanic Azurite"]
  //          span "Galvanic Azurite"
  //          span "Cast Shock Skill damage leaves enemies Magnetized..."
  //          span "Unique"
  //
  //    Khi o nhap CON TRONG thi cho do la luoi 29 loai do, moi cai mot nut
  //    button.group/item-base  ("Ring", "Two-Handed Mace", "Chest Armor"...)
  //    Ca 29 nut deu nam san trong DOM, khong ao hoa -> bam thang duoc.
  //
  //  HAI DUONG, tuy do hiem doc duoc o dong 2 cua chu D4Lister gui sang:
  //
  //    Unique / Mythic  ->  go TEN MON roi bam goi y.
  //                         Ten unique la ten co dinh, trang co trong danh
  //                         muc nen go ra ngay.
  //    Con lai          ->  bam thang nut loai do trong luoi.
  //                         Ten do rare kieu "HACK SERPENT" la ten sinh
  //                         ngau nhien, khong danh muc nao co ca — go vao
  //                         chi to khong ra gi.
  // ====================================================================
  const CHU_DO_HIEM = 'mythic unique|mythic|unique|legendary|set|rare|magic|common';

  //  "Ancestral Unique Ring"      -> {toTien:true,  doHiem:'unique',    loai:'Ring'}
  //  "Legendary Two-Handed Mace"  -> {toTien:false, doHiem:'legendary', loai:'Two-Handed Mace'}
  //  "Magic Axe"                  -> {toTien:false, doHiem:'magic',     loai:'Axe'}
  function tachDongLoai(d) {
    let t = ' ' + String(d || '').trim() + ' ';
    const toTien = /\bancestral\b/i.test(t);
    t = t.replace(/\b(ancestral|sacred)\b/ig, ' ');
    let doHiem = '';
    t = t.replace(new RegExp('\\b(' + CHU_DO_HIEM + ')\\b', 'i'), m => {
      doHiem = m.toLowerCase();
      return ' ';
    });
    return { toTien, doHiem, loai: t.replace(/\s+/g, ' ').trim() };
  }

  const laDoRieng = dh => dh === 'unique' || dh === 'mythic' || dh === 'mythic unique';

  const oThemItem = () =>
    [...document.querySelectorAll('[cmdk-root] input[type="text"]')]
      .find(i => dangHien(i) && /add item|item base/i.test(i.placeholder || ''));

  const luoiBase = () =>
    [...document.querySelectorAll('button[class*="group/item-base"]')].filter(dangHien);

  const goiYItem = () =>
    [...document.querySelectorAll('[cmdk-list] [role="option"][data-value]')]
      .filter(dangHien);

  // Bam xong nut loai do, trang KHONG dung mon ra ngay: no nhay sang buoc
  // chon Aspect va MAC DINH coi mon la Legendary. Muon do hiem khac thi bam
  // "Change rarity" (nut co mui ten lui) de quay lai buoc chon do hiem.
  const oTimAspect = () =>
    [...document.querySelectorAll('input[type="text"]')]
      .find(i => dangHien(i) && /search aspects/i.test(i.placeholder || ''));

  // Luoi DO HIEM dung chung kieu the voi luoi loai do. Phan biet: the do
  // hiem ghi "<DO HIEM> <LOAI DO>" nen chu co chua mot tu chi do hiem, con
  // the loai do chi ghi "Ring" / "Two-Handed Mace".
  const RE_DO_HIEM = /\b(common|magic|rare|legendary|unique|mythic|set)\b/i;
  const luoiDoHiem = () => {
    const tu = luoiBase().filter(b => RE_DO_HIEM.test((b.textContent || '').trim()));
    if (tu.length) return tu;
    // Phong khi luoi do hiem khong dung chung kieu the voi luoi loai do:
    // do rong ra moi nut dang hien co chu dang "<do hiem> <loai do>".
    return [...document.querySelectorAll('button')].filter(b => {
      if (!dangHien(b)) return false;
      const t = (b.textContent || '').replace(/\s+/g, ' ').trim();
      return t.length > 0 && t.length < 44 && RE_DO_HIEM.test(t) && /\s/.test(t);
    });
  };

  // ====================================================================
  //  CHON ASPECT  (do Legendary)
  //
  //  Trang bat chon Aspect thi moi dung ra mon. Chu TTS cua game KHONG noi
  //  ten Aspect — chi in mo ta:
  //     "Thorns damage dealt has a 80% [80 - 110]% chance to deal damage..."
  //
  //  Danh sach Aspect tren trang CO AO HOA: ve 12 the mot luc trong khi co
  //  hang tram cai. Cuon do vua cham vua mong manh.
  //
  //  Duong chac hon: danh muc cua trang la MOT MANG TRON (affix, aspect,
  //  unique chung cho) ma ext da biet cach moi ra tu bo nho React tu ban
  //  V2. Loc rieng type === 'ASPECT', khop MO TA ngoai tuyen de ra TEN,
  //  roi go ten do vao o tim — danh sach thu con mot the, bam la xong.
  //
  //  Mo ta trong danh muc dung "#" thay cho con so ("has a # [#-#]% chance"),
  //  con chu cua game thi co so that. Nen truoc khi so, bo het so va ngoac.
  // ====================================================================
  const thuanMoTa = s => String(s || '')
    .replace(/\[[^\]]*\]/g, ' ')
    // Gioi han class "(Barbarian Druid Only)" va phan so sanh voi do dang
    // mac "(+8)": chu cua game co, mo ta cua trang khong. De lai la lech
    // mat may tu, ma cau Aspect chi lech vai tu la truot.
    .replace(/\([^)]*\)/g, ' ')
    .replace(/[#{}\d.,%+]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  //  Khop MO TA — cau dai, khac han khop TEN affix von chi vai tu.
  //
  //  diemKhop dem theo TI LE tu khop duoc. Cau Aspect dai hai ba chuc tu,
  //  nen hai Aspect chi khac DUNG MOT TU — "increased Cold damage" so voi
  //  "increased Fire damage" — van duoc 24/25 = 96%, qua nguong 95% va
  //  duoc chon nhu the chac chan. Chon nham ma khong ai biet.
  //
  //  Nen o day doi khoang cach voi A QUAN phai bang it nhat MOT TU. Hai cau
  //  sat nhau trong vong mot tu thi khong doan bua, tra ve de nguoi dung tu
  //  chon. Phan khop affix da co phep kiem nhap nhang tu lau (kq.nhi >=
  //  DIEM_CHAC); phan Aspect thi chua, day la cho bo sung.
  function khopMoTa(cau, ds, layTen) {
    const soTu = tachTu(cau).length || 1;
    const cham = ds
      .map(m => ({ muc: m, d: diemKhop(cau, layTen(m)) }))
      .sort((a, b) => b.d - a.d);
    const tot = cham[0], nhi = cham[1];
    return {
      muc: tot ? tot.muc : null,
      diem: tot ? tot.d : 0,
      mucNhi: nhi ? nhi.muc : null,
      nhi: nhi ? nhi.d : 0,
      cachBiet: (tot ? tot.d : 0) - (nhi ? nhi.d : 0),
      canCach: 1 / soTu,          // đúng một từ
      top: cham.slice(0, 3),
    };
  }

  // BAY DA SUP MOT LAN: trang VE DANH SACH THEO HAI KIEU.
  //   o tim con trong -> luoi the, moi the la mot <button>
  //   da go chu vao   -> danh sach cmdk, moi the la div[role=option][cmdk-item],
  //                      va KHONG con <button> nao ca
  // Ban truoc chi tim <button>, nen cang loc dung ten thi cang khong thay gi.
  const theAspect = () => {
    const kh = document.querySelector('[data-slot="data-picker-results"]');
    if (!kh) return [];
    const ds = [...kh.querySelectorAll('button,[role="option"],[cmdk-item]')]
      .filter(dangHien);
    // giu the trong cung, khoi dem mot the thanh hai
    return ds.filter(e => !ds.some(x => x !== e && e.contains(x)));
  };

  const tenTheAspect = b => {
    const sp = b.querySelector('[class*="font-game-tooltip"]');
    if (sp && (sp.textContent || '').trim())
      return (sp.textContent || '').replace(/\s+/g, ' ').trim();
    // Du phong: chu cua the la "<Ten Aspect><mo ta>" dinh lien nhau, khong
    // co dau cach o giua — cat den het tu "Aspect" la ra ten.
    const t = (b.textContent || '').replace(/\s+/g, ' ').trim();
    const m = t.match(/^(.*?\bAspect\b)/i);
    return m ? m[1] : t.slice(0, 40);
  };

  const gonChu = t => String(t || '').replace(/\s+/g, ' ').trim().toLowerCase();

  async function chonAspect(cau) {
    const o = oTimAspect();
    if (!o) return { ok: false, viSao: 'không thấy ô Search aspects' };
    if (!cau) return { ok: false, viSao: 'D4Lister không gửi kèm mô tả Aspect' };

    const kho = layKhoAffix();
    if (!kho) return { ok: false, viSao: 'chưa đọc được danh mục của trang' };
    const ds = kho.ds.filter(x =>
      x && x.type === 'ASPECT' && typeof x.description === 'string' && x.name);
    if (!ds.length)
      return { ok: false, viSao: 'danh mục ' + kho.ds.length + ' mục nhưng không có ASPECT nào' };

    const tk = khopMoTa(thuanMoTa(cau), ds, x => thuanMoTa(x.description));
    ghi('Aspect — câu của game: ' + thuanMoTa(cau));
    ghi('Aspect — ba ứng viên sát nhất: ' +
      tk.top.map(x => '"' + x.muc.name + '" ' + Math.round(x.d * 100) + '%').join('  |  '));

    if (!tk.muc || tk.diem < DIEM_CHAC)
      return {
        ok: false,
        viSao: 'không khớp chắc Aspect nào (gần nhất "' +
          (tk.muc ? tk.muc.name : '—') + '" ' + Math.round(tk.diem * 100) + '%)',
      };
    // Hai Aspect sát nhau trong vòng một từ thì KHÔNG đoán. Đoán bừa ở đây
    // là đăng nhầm Aspect mà chẳng ai biết, tệ hơn hẳn việc dừng lại hỏi.
    if (tk.mucNhi && tk.cachBiet < tk.canCach)
      return {
        ok: false,
        viSao: 'hai Aspect sát nhau, không dám chọn: "' + tk.muc.name + '" ' +
          Math.round(tk.diem * 100) + '% và "' + tk.mucNhi.name + '" ' +
          Math.round(tk.nhi * 100) + '% — chọn tay giúp',
      };
    const ten = String(tk.muc.name).trim();

    goChu(o, ten);

    // BAY DA SUP MOT LAN: cho nay tung hoi "da co the nao chua". Cau tra loi
    // la CO ngay lap tuc — 12 the CU van con day trong luc trang chua loc
    // xong. Cham diem tren 12 the cu, khong thay "Needleflare Aspect", the
    // la bo cuoc dung luc the that sap hien ra.
    // => Phai cho den khi co the DUNG TEN, chu khong phai co the nao.
    const the = await cho(() => {
      const ds = theAspect();
      if (!ds.length) return null;
      // Chu cua the la "<Ten Aspect><mo ta>" dinh lien, nen so bang "bat dau bang"
      const dung = ds.find(b => gonChu(b.textContent).indexOf(gonChu(ten)) === 0);
      if (dung) return dung;
      const tk2 = timKhopNhat(ten, ds, tenTheAspect);
      return (tk2.muc && tk2.diem >= DIEM_CHAC) ? tk2.muc : null;
    }, 4000);

    if (!the)
      return {
        ok: false,
        viSao: 'gõ "' + ten + '" rồi mà danh sách không ra thẻ đúng tên (đang có: '
          + theAspect().map(tenTheAspect).slice(0, 4).join(', ') + ')',
      };
    bamThat(the);
    return { ok: true, ten };
  }

  const TEN_DO_HIEM = {
    'mythic unique': 'Mythic Unique', mythic: 'Mythic', unique: 'Unique',
    legendary: 'Legendary', set: 'Set', rare: 'Rare', magic: 'Magic',
    common: 'Common',
  };

  //  Ten cua mot the goi y. Uu tien alt cua anh: no la ten TRON, khong dinh
  //  doan mo ta dai phia sau, va khong bi trang to sang doan vua go.
  function tenGoiY(o) {
    const im = o.querySelector('img[alt]');
    if (im && (im.alt || '').trim()) return im.alt.trim();
    const sp = o.querySelector('span');
    return sp ? chuThuan(sp) : '';
  }

  //  Rê chuột vào một thẻ gợi ý rồi đọc LOẠI ĐỒ trong tooltip trang xổ ra.
  //
  //  Vì sao phải làm vậy: đã đọc DOM thật, hai thẻ cùng tên giống nhau từng
  //  byte, trong thẻ không có chữ nào về loại đồ. Thứ duy nhất còn lại là
  //  cái tooltip — thẻ có sẵn data-slot="tooltip-trigger".
  //
  //  Trả về dòng kiểu "Ancestral Unique Focus", hoặc "" nếu không đọc được.
  async function doLoaiQuaTooltip(o) {
    try {
      const diem = o.querySelector('[data-slot="tooltip-trigger"]') || o;
      // Radix mở tooltip bằng onPointerMove, KHÔNG phải pointerover — lần
      // trước chỉ bắn pointerover/mouseenter nên tooltip chưa từng mở (ảnh
      // chụp cho thấy data-state vẫn "closed"). Bắn cả pointermove, và
      // dùng PointerEvent có pointerType "mouse" cho giống thật.
      const banPointer = t => {
        try {
          diem.dispatchEvent(new PointerEvent(t, {
            bubbles: true, cancelable: true, pointerType: 'mouse', isPrimary: true,
          }));
        } catch (e) {
          diem.dispatchEvent(new MouseEvent(t, { bubbles: true, cancelable: true }));
        }
      };
      for (const t of ['pointerenter', 'pointerover', 'pointermove']) banPointer(t);
      for (const t of ['mouseover', 'mouseenter', 'mousemove'])
        diem.dispatchEvent(new MouseEvent(t, { bubbles: true, cancelable: true }));
      // Radix chờ mặc định 700ms rồi mới mở; đợi rộng tay hơn thế.
      const noi = await cho(() => {
        const c = [...document.querySelectorAll(
          '[data-slot="tooltip-content"],[role="tooltip"],[data-radix-popper-content-wrapper]')]
          .filter(dangHien);
        return c.length ? c[c.length - 1] : null;
      }, 1800);
      let ra = '';
      if (noi) {
        for (const d of ((noi.innerText || noi.textContent || '') + '')
             .split(/\r?\n/).map(x => x.trim()).filter(Boolean)) {
          if (d.length > 44) continue;
          if (RE_DO_HIEM.test(d) && /[A-Za-z]/.test(d.replace(RE_DO_HIEM, ''))) {
            ra = d;
            break;
          }
        }
      }
      for (const t of ['pointerout', 'pointerleave', 'mouseout', 'mouseleave'])
        diem.dispatchEvent(new MouseEvent(t, { bubbles: true, cancelable: true }));
      return ra;
    } catch (e) {
      ghi('dò tooltip hỏng: ' + e);
      return '';
    }
  }

  //  Mã riêng của một thẻ gợi ý. Hai món trùng tên chỉ khác nhau đúng chỗ
  //  này, nên nó là thứ duy nhất dùng được để nhớ "thẻ nào đã thử rồi".
  const maThe = o => (o && o.getAttribute && o.getAttribute('data-value')) || '';

  // ====================================================================
  //  NHỚ MÃ MÓN ĐÃ DỰNG ĐÚNG
  //
  //  "Infernal Homunculus" ra hai thẻ giống nhau từng byte, một Focus một
  //  Charm, nhìn thẻ không tài nào biết cái nào là cái nào — phải dựng thử
  //  rồi đọc loại đồ trang dựng ra. Mỗi lần dán lại tốn một lượt Reset.
  //
  //  Nhưng dựng đúng MỘT LẦN là biết mã nào đúng. Nhớ lại thì lần sau vào
  //  thẳng, khỏi dựng thử. Nhớ theo cặp TÊN MÓN + LOẠI ĐỒ, vì cùng một tên
  //  vẫn có thể có nhiều loại.
  //
  //  Nhớ nhầm cũng không sao: lượt sau vẫn kiểm loại đồ như thường, sai thì
  //  Reset rồi thử thẻ khác, và ghi đè lại mã đúng.
  // ====================================================================
  const KHOA_MA_MON = 'd4lister-ma-mon-1';

  const khoaMon = (tenMon, loai) =>
    tenThuan(String(tenMon || '')).toLowerCase() + '|'
    + tenThuan(String(loai || '')).toLowerCase();

  function docMaMon(khoa) {
    try {
      const o = JSON.parse(localStorage.getItem(KHOA_MA_MON) || '{}');
      return (o && typeof o[khoa] === 'string') ? o[khoa] : '';
    } catch (e) { return ''; }
  }

  function luuMaMon(khoa, ma) {
    if (!khoa || !ma) return;
    try {
      const o = JSON.parse(localStorage.getItem(KHOA_MA_MON) || '{}');
      if (o[khoa] === ma) return;
      o[khoa] = ma;
      localStorage.setItem(KHOA_MA_MON, JSON.stringify(o));
      ghi('nhớ mã món: ' + khoa + ' -> ' + ma);
    } catch (e) { /* đầy bộ nhớ thì thôi, lần sau dựng thử lại */ }
  }

  //  Quay lại bước chọn món.
  //
  //  Hai đường, thử đường NHẸ trước:
  //
  //  1. Bấm chính TÊN MÓN trên dòng "Item". Dòng đó là ba cái nút:
  //         <button>Focus</button> · <button>Unique</button> ·
  //         <button>Infernal Homunculus</button>
  //     Bấm nút tên món thì trang mở lại ô chọn món, KHÔNG xoá những thứ
  //     đã đặt (sức mạnh, giá…).
  //  2. Không được thì bấm Reset — xoá trắng, dựng lại từ đầu.
  //
  //  Cả hai đều tìm theo CHỮ trên nút, không bám class: class của trang này
  //  do Tailwind sinh ra, đổi xoành xoạch.
  async function datLaiForm(tenMon) {
    if (await bamNutTheoChu(tenMon, 'mở lại ô chọn món')) return true;
    if (await bamNutTheoChu('Reset', 'bấm Reset')) return true;
    ghi('không quay lại được bước chọn món');
    return false;
  }

  async function bamNutTheoChu(chu, viec) {
    const t = tenThuan(String(chu || '')).toLowerCase();
    if (!t) return false;
    const nut = [...document.querySelectorAll('button')].find(b =>
      dangHien(b) && tenThuan((b.textContent || '').trim()).toLowerCase() === t);
    if (!nut) return false;
    bamThat(nut);
    const lai = await cho(() => (oThemItem() ? true : null), 3000);
    if (!lai) {
      ghi(viec + ': bấm rồi mà ô Add item không hiện lại');
      return false;
    }
    ghi(viec + ': xong');
    await doi(250);
    return true;
  }

  //  Quên mã đã nhớ khi nó hoá ra sai. Không quên thì lần nào cũng thử lại
  //  cái sai ấy trước, tốn một lượt quay lui vô ích.
  function quenMaMon(khoa) {
    try {
      const o = JSON.parse(localStorage.getItem(KHOA_MA_MON) || '{}');
      if (!(khoa in o)) return;
      delete o[khoa];
      localStorage.setItem(KHOA_MA_MON, JSON.stringify(o));
      ghi('quên mã món đã nhớ (hoá ra sai): ' + khoa);
    } catch (e) {}
  }

  //  Đổi thẳng LOẠI ĐỒ trên form.
  //
  //  Dùng khi danh mục của trang không có mục nào đúng loại — đã gặp thật:
  //  "Moloch's Beating Flame" trong game là Amulet, mà trang chỉ có hai mục
  //  và cả hai đều ghi Charm. Chọn kiểu gì cũng không ra Amulet.
  //
  //  Dòng "Item" trên form là ba cái nút bấm được: <loại đồ> · <độ hiếm> ·
  //  <tên món>. Bấm nút loại đồ thì trang mở lại lưới chọn base.
  async function suaLoaiDoTrenForm(loaiCan) {
    const ltNay = tachDongLoai(loaiTrenForm()).loai;
    if (!ltNay || !loaiCan) return false;
    const t = tenThuan(ltNay).toLowerCase();
    const nut = [...document.querySelectorAll('button')].find(b =>
      dangHien(b) && tenThuan((b.textContent || '').trim()).toLowerCase() === t);
    if (!nut) {
      ghi('sửa loại đồ: không thấy nút "' + ltNay + '" trên dòng Item');
      return false;
    }
    bamThat(nut);
    const luoi = await cho(() => (luoiBase().length ? luoiBase() : null), 3000);
    if (!luoi) {
      ghi('sửa loại đồ: bấm rồi mà lưới chọn base không hiện ra');
      return false;
    }
    const tk = timKhopNhat(loaiCan, luoi, b => (b.textContent || '').trim());
    if (!tk.muc || tk.diem < DIEM_NGO) {
      ghi('sửa loại đồ: lưới không có ô nào tên "' + loaiCan + '"');
      return false;
    }
    bamThat(tk.muc);
    await doi(700);
    const xong = hopLoai(loaiTrenForm(), loaiCan);
    ghi('sửa loại đồ sang "' + loaiCan + '": ' + (xong ? 'được' : 'không ăn'));
    return xong;
  }

  //  Dòng tooltip có đúng loại đồ đang cần không.
  function hopLoai(dongTooltip, loaiCan) {
    if (!dongTooltip || !loaiCan) return false;
    const a = tenThuan(tachDongLoai(dongTooltip).loai || '').toLowerCase();
    const b = tenThuan(loaiCan).toLowerCase();
    return !!a && a === b;
  }

  //  TAT CA chu cua mot the goi y — ten, loai do, data-value. Dung de biet
  //  the do la loai gi, vi tenGoiY chi lay moi cai ten.
  const chuGoiY = o => ((o.getAttribute('data-value') || '') + ' '
      + (o.textContent || '')).replace(/\s+/g, ' ').trim();

  //  Muc trong danh muc cua trang ung voi mot the goi y.
  //
  //  The goi y chi ghi TEN va MO TA, khong ghi loai do. Do that tu nhat ky
  //  nguoi dung: "Infernal Homunculus" ra HAI the giong nhau tung chu, khac
  //  moi cai ma:
  //      unique:9ecbda01-fdf8-4df4-8edf-8febdf0d0e3b
  //      unique:dd399910-787d-41bf-a0dc-2a2529d84021
  //  Mot cai la Focus, mot cai la Charm — nhin the thi chiu. Phai lay cai
  //  ma do tra nguoc vao danh muc (.attributes, 1450 muc) moi ra loai do.
  function mucDanhMucCuaThe(o) {
    const m = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i
      .exec(o.getAttribute('data-value') || '');
    if (!m) return null;
    const kho = layKhoAffix();
    if (!kho || !Array.isArray(kho.ds)) return null;
    return kho.ds.find(x => x && typeof x.id === 'string'
      && x.id.toLowerCase() === m[1].toLowerCase()) || null;
  }

  //  Tat ca chu co the doi chieu duoc cua mot the: chu tren the + CA MUC
  //  danh muc doi ra chuoi.
  //
  //  Do ca muc danh muc chu khong soi mot truong cu the: khong biet trang
  //  dat ten truong do la gi (itemType? slot? baseType?), ma do het thi
  //  khong can biet.
  function chuDoiChieu(o) {
    let c = chuGoiY(o);
    const muc = mucDanhMucCuaThe(o);
    if (muc) {
      try { c += ' ' + JSON.stringify(muc); } catch (e) {}
    }
    return c.toLowerCase();
  }

  //  Giu lai nhung goi y DUNG LOAI DO. Khong con cai nao thi tra lai danh
  //  sach cu — trang viet ten loai khac di thi thoi, con hon la khong chon
  //  duoc gi.
  function locGoiYTheoLoai(ds, loai) {
    const t = String(loai || '').trim().toLowerCase();
    if (!t) return ds;
    const tu = t.split(/\s+/).filter(Boolean);
    const hop = ds.filter(o => {
      const c = chuDoiChieu(o);
      return tu.every(w => c.includes(w));
    });
    return hop.length ? hop : ds;
  }

  const nutTheoNhan = nhan =>
    [...document.querySelectorAll('button[aria-label]')]
      .find(b => dangHien(b) && b.getAttribute('aria-label') === nhan);

  //  Dat suc manh item. Trang chi co vai nac chu khong phai o nhap tu do.
  //  Do ancestral thi luon 900 — chinh trang cung ghi "Ancestral items
  //  always have 900 Item Power".
  function datSucManh(soSM, toTien) {
    if (toTien) {
      const n = nutTheoNhan('900 Ancestral');
      if (n) { bamThat(n); return '900 Ancestral'; }
    }
    if (!isFinite(soSM) || soSM <= 0) return '';
    // Doc THANG cac nac dang co tren trang, dung danh sach cung. Trang bay
    // nac khac nhau tuy loai do — do thuc te: vu khi 10/100/200/.../850/900,
    // trang suc 10/120/330/540/750/800/850/900.
    const nac = [...document.querySelectorAll('button[aria-label]')]
      .filter(b => dangHien(b) && /^\d+$/.test(b.getAttribute('aria-label')))
      .map(b => ({ b, v: parseInt(b.getAttribute('aria-label'), 10) }))
      .sort((x, y) => y.v - x.v);
    for (const n of nac)
      if (soSM >= n.v) { bamThat(n.b); return String(n.v); }
    return '';
  }

  let dangTaoItem = false, daThuTaoItem = false;

  async function taoItem(tenMon, dongLoai, cauAspect) {
    const L = tachDongLoai(dongLoai);
    const o = oThemItem();

    if (laDoRieng(L.doHiem)) {
      // CHỌN MÓN UNIQUE — dựng thử rồi KIỂM, sai thì chọn lại.
      //
      // Vì sao phải làm vòng vo vậy: đã đọc DOM thật (hồ sơ 25/09), hai thẻ
      // "Infernal Homunculus" giống nhau TỪNG BYTE — cùng class, cùng alt,
      // cùng mô tả, cùng nhãn "Unique" — chỉ khác cái mã và mã số ảnh.
      // Trong thẻ không có một chữ nào về loại đồ, nên nhìn thẻ mà đoán là
      // việc bất khả.
      //
      // Đã thử dò bằng tooltip (thẻ có data-slot="tooltip-trigger"): sự
      // kiện chuột giả KHÔNG đánh thức được Radix, ảnh chụp cho thấy
      // data-state vẫn "closed". Giữ phép dò đó làm đường ưu tiên phòng khi
      // trang đổi, nhưng không trông vào nó nữa.
      //
      // Đường chắc ăn: bấm một thẻ, chờ trang dựng món, ĐỌC loại đồ trang
      // vừa dựng ra (ô xem trước ghi rõ "Ancestral Unique Charm"). Sai thì
      // bấm Reset rồi chọn thẻ khác. Nhiều nhất hai lượt.
      if (!o) return { ok: false, viSao: 'không thấy ô Add item…' };

      const daBo = new Set();        // mã những thẻ đã thử mà sai loại
      let khongCoDungLoai = false;   // trang không có món này ở loại đang cần
      let ketQua = null;
      const khoaNho = khoaMon(tenMon, L.loai);
      const maNho = docMaMon(khoaNho);
      if (maNho) ghi('đã nhớ mã món này: ' + maNho);

      for (let lan = 1; lan <= 2; lan++) {
        const oNhap = oThemItem();
        if (!oNhap) {
          ghi('lượt ' + lan + ': không thấy ô Add item nữa');
          break;
        }
        chupBuoc(lan + 'a-truoc-go-ten-mon');
        goChu(oNhap, tenMon);
        const ds = await cho(() => {
          const g = goiYItem();
          return g.length ? g : null;
        }, 3000);
        if (!ds) {
          if (lan === 1)
            return { ok: false, viSao: 'gõ "' + tenMon + '" mà không ra gợi ý nào' };
          break;
        }
        chupBuoc(lan + 'b-danh-sach-goi-y');

        if (lan === 1) {
          ghi('Gợi ý cho "' + tenMon + '" (' + ds.length + '):');
          ds.forEach((o2, i) => {
            ghi('   [' + i + '] ' + chuGoiY(o2));
            try {
              ghi('        thẻ: ' + (o2.outerHTML || '').replace(/\s+/g, ' ').slice(0, 400));
            } catch (e) {}
          });

          // Đường ưu tiên: hỏi tooltip. Hiện không ăn, nhưng rẻ và nếu
          // trang đổi cách dựng thì nó đỡ phải dựng thử hai lượt.
          const loaiTT = [];
          for (let i = 0; i < ds.length; i++) {
            const lt = await doLoaiQuaTooltip(ds[i]);
            loaiTT.push(lt);
            if (lt) ghi('   [' + i + '] tooltip nói loại đồ: ' + lt);
          }
          const iDung = loaiTT.findIndex(lt => hopLoai(lt, L.loai));
          if (iDung >= 0) {
            ghi('Tooltip tách được — chọn thẳng mục đúng loại "' + L.loai + '"');
            ds.splice(0, ds.length, ds[iDung]);
          } else if (loaiTT.length && loaiTT.every(Boolean)) {
            // Đọc được loại đồ của HẾT các mục, mà không mục nào đúng loại:
            // trang không có món này ở loại đó. Dựng thử lượt nữa cũng chỉ ra
            // đúng cái sai ấy — đừng tốn công.
            khongCoDungLoai = true;
            ghi('Tooltip đọc được hết ' + loaiTT.length + ' mục, KHÔNG mục nào là "'
              + L.loai + '" (trang chỉ có: ' + loaiTT.join(', ') + ')');
          }
        }

        // Bỏ những thẻ lượt trước đã thử mà ra sai loại.
        const conLai = ds.filter(x => !daBo.has(maThe(x)));
        if (!conLai.length) {
          ghi('hết thẻ để thử');
          break;
        }
        // Mã đã nhớ mà còn trong danh sách thì dùng thẳng, khỏi dựng thử.
        const theNho = maNho ? conLai.find(x => maThe(x) === maNho) : null;
        if (theNho) {
          ghi('lượt ' + lan + ': dùng mã đã nhớ, bỏ qua bước dò');
          chupBuoc(lan + 'c-truoc-bam-goi-y');
          bamThat(theNho);
          ketQua = {
            ok: true, cach: 'gõ tên (mã đã nhớ)', ten: tenGoiY(theNho),
            doHiem: L.doHiem, loai: L.loai, ma: maThe(theNho),
          };
          const ltNho = await cho(() => loaiTrenForm() || null, 4000);
          chupBuoc(lan + 'd-sau-bam-goi-y');
          ghi('lượt ' + lan + ': trang dựng ra "' + (ltNho || '(chưa đọc được)') + '"');
          if (!L.loai || !ltNho || hopLoai(ltNho, L.loai)) break;
          // Mã nhớ sai (trang đổi danh mục chẳng hạn) — bỏ nó đi, dựng thử lại.
          ghi('mã đã nhớ ra sai loại — bỏ');
          quenMaMon(khoaNho);
          daBo.add(maThe(theNho));
          // Tooltip đã nói trước là trang KHÔNG có món này ở loại đang cần
          // thì dựng thử lượt nữa cũng ra đúng cái sai ấy. Giữ nguyên rồi
          // để phần sửa loại đồ trên form lo — đỡ một lượt quay lui.
          if (khongCoDungLoai) {
            ghi('trang không có món này ở loại "' + L.loai
              + '" — giữ nguyên, để phần sửa loại đồ lo');
            break;
          }
          ketQua = null;
          if (lan === 2) break;
          chupBuoc('r-truoc-reset');
          if (!(await datLaiForm(tenMon))) break;
          chupBuoc('r-sau-reset');
          continue;
        }

        const dsLoc = locGoiYTheoLoai(conLai, L.loai);
        const tk = timKhopNhat(tenMon, dsLoc, tenGoiY);
        if (!tk.muc || tk.diem < DIEM_NGO) {
          if (lan === 1)
            return {
              ok: false,
              viSao: 'không gợi ý nào giống "' + tenMon + '" (gần nhất: '
                + (tk.muc ? tenGoiY(tk.muc) : '—') + ')',
            };
          break;
        }

        ghi('lượt ' + lan + ': chọn ' + maThe(tk.muc));
        chupBuoc(lan + 'c-truoc-bam-goi-y');
        bamThat(tk.muc);
        ketQua = {
          ok: true, cach: 'gõ tên', ten: tenGoiY(tk.muc),
          doHiem: L.doHiem, loai: L.loai, ma: maThe(tk.muc),
        };

        // Chờ trang dựng xong rồi ĐỌC loại đồ nó vừa dựng ra.
        const ltThat = await cho(() => loaiTrenForm() || null, 4000);
        chupBuoc(lan + 'd-sau-bam-goi-y');
        ghi('lượt ' + lan + ': trang dựng ra "' + (ltThat || '(chưa đọc được)') + '"');

        if (!L.loai || !ltThat || hopLoai(ltThat, L.loai)) break;   // đúng, hoặc không kiểm được
        if (khongCoDungLoai) {
          ghi('trang không có món này ở loại "' + L.loai + '" — thôi không thử lượt nữa');
          break;
        }
        if (conLai.length < 2 && lan === 1) {
          ghi('chỉ có một thẻ, không có gì để đổi sang');
          break;
        }

        daBo.add(maThe(tk.muc));
        if (lan === 2) break;

        ghi('SAI LOẠI: trang dựng "' + tachDongLoai(ltThat).loai + '" mà game nói "'
          + L.loai + '" — bấm Reset rồi thử thẻ còn lại');
        chupBuoc('r-truoc-reset');
        if (!(await datLaiForm(tenMon))) {
          ghi('không đặt lại được form — đành giữ nguyên');
          break;
        }
        chupBuoc('r-sau-reset');
      }

      if (ketQua) {
        let ltCuoi = loaiTrenForm();
        // Không mục nào đúng loại -> đổi thẳng loại đồ trên form.
        if (L.loai && ltCuoi && !hopLoai(ltCuoi, L.loai)) {
          chupBuoc('s-truoc-sua-loai-do');
          if (await suaLoaiDoTrenForm(L.loai)) ltCuoi = loaiTrenForm();
          chupBuoc('s-sau-sua-loai-do');
        }
        // Dựng đúng rồi thì NHỚ LẠI mã, lần sau khỏi dựng thử lượt nào.
        if (L.loai && ltCuoi && hopLoai(ltCuoi, L.loai) && ketQua.ma && !khongCoDungLoai)
          luuMaMon(khoaNho, ketQua.ma);
        if (L.loai && ltCuoi && !hopLoai(ltCuoi, L.loai)) {
          canhBaoLoaiDo = 'trang dựng ra "' + tachDongLoai(ltCuoi).loai
            + '" mà game nói "' + L.loai + '" — đổi lại trên form giúp';
          ghi('CẢNH BÁO: ' + canhBaoLoaiDo);
        }
        return ketQua;
      }
      return { ok: false, viSao: 'không chọn được món "' + tenMon + '"' };
    }

    chupBuoc('2a-luoi-chon-base');
    const luoi = luoiBase();
    if (!luoi.length) {
      // O nhap con chu cu thi luoi bi an mat -> xoa di cho luoi hien lai
      if (o && o.value) {
        goChu(o, '');
        const lai = await cho(() => (luoiBase().length ? luoiBase() : null), 1500);
        if (lai) return taoItem(tenMon, dongLoai, soSM);
      }
      return { ok: false, viSao: 'chưa thấy lưới loại đồ' };
    }
    const tk = timKhopNhat(L.loai, luoi, b => (b.textContent || '').trim());
    if (!tk.muc || tk.diem < DIEM_NGO)
      return { ok: false, viSao: 'lưới không có loại đồ nào tên "' + L.loai + '"' };
    const tenLoai = (tk.muc.textContent || '').trim();
    ghi('Lưới base: chọn "' + tenLoai + '" cho loại đồ "' + L.loai + '"'
      + ' (điểm ' + Math.round(tk.diem * 100) + '%, á quân ' + Math.round(tk.nhi * 100) + '%)');
    chupBuoc('2b-truoc-bam-base');
    bamThat(tk.muc);
    await doi(500);
    chupBuoc('2c-sau-bam-base');

    // BUOC 2: LUOI DO HIEM.
    // Bam loai do xong, trang KHONG dung mon ra ngay. No thay lua luoi bang
    // nam the do hiem, moi the ghi "<DO HIEM> <LOAI DO>":
    //     COMMON Two-Handed Mace   MAGIC ...   RARE ...
    //     LEGENDARY ...            UNIQUE ...
    // Cung mot kieu the nhu luoi loai do, phan biet bang cho chu the CO
    // chua tu chi do hiem.
    const nhan = TEN_DO_HIEM[L.doHiem] || L.doHiem;
    const buoc = await cho(() => {
      if (luoiDoHiem().length) return 'dohiem';
      if (nutMoDs()) return 'xong';
      if (oTimAspect()) return 'aspect';
      return null;
    }, 5000);

    if (buoc === 'dohiem') {
      const luoi2 = luoiDoHiem();
      const tk2 = timKhopNhat(nhan + ' ' + tenLoai, luoi2,
        b => (b.textContent || '').replace(/\s+/g, ' ').trim());
      if (!tk2.muc || tk2.diem < DIEM_NGO)
        return {
          ok: false,
          viSao: 'lưới độ hiếm không có thẻ "' + nhan + ' ' + tenLoai + '" (có: '
            + luoi2.map(b => (b.textContent || '').trim()).join(', ') + ')',
        };
      bamThat(tk2.muc);
    }

    const buoc2 = (buoc === 'dohiem')
      ? await cho(() => {
          if (nutMoDs()) return 'xong';
          if (oTimAspect()) return 'aspect';
          return null;
        }, 5000)
      : buoc;

    if (buoc2 === 'xong')
      return { ok: true, cach: 'bấm lưới', ten: nhan + ' ' + tenLoai, doHiem: L.doHiem };

    // BUOC 3 (chi do Legendary): trang bat chon Aspect thi moi dung ra mon.
    if (buoc2 === 'aspect') {
      // Chụp CẢ danh sách Aspect. Món DOOM CUISSES kẹt đúng ở đây mà hồ sơ
      // trắng trơn — ảnh gần nhất chụp trước lúc danh sách kịp hiện ra.
      chupBuoc('a-truoc-chon-aspect');
      const kqA = await chonAspect(cauAspect);
      chupBuoc('a-sau-chon-aspect');
      if (!kqA.ok)
        return {
          ok: false, choAspect: true, ten: tenLoai,
          viSao: 'chưa tự chọn được Aspect (' + kqA.viSao +
            ') — chọn giúp một cái, ext điền tiếp ngay',
        };
      const xong2 = await cho(() => (nutMoDs() ? true : null), 6000);
      if (!xong2)
        return {
          ok: false, choAspect: true, ten: tenLoai,
          viSao: 'đã chọn Aspect "' + kqA.ten + '" nhưng form món chưa dựng ra',
        };
      return {
        ok: true, cach: 'bấm lưới + Aspect',
        ten: nhan + ' ' + tenLoai + ' · ' + kqA.ten, doHiem: L.doHiem,
      };
    }

    return { ok: false, viSao: 'bấm "' + nhan + ' ' + tenLoai + '" rồi mà trang không hiện gì tiếp' };
  }

  // ====================================================================
  //  DO DOM  -  ghi cau truc that ra Console
  //
  //  Ban luu Ctrl+S chi chup duoc trang thai DUNG LUC LUU. Cac lop phu mo
  //  ra khi bam (chon do hiem, chon ten mon) khong co trong do. Doan nay
  //  ghi lai cai DANG CO tren trang that, de khoi phai doan.
  //
  //  Khong tu bam gi ca — chi doc. Muon xem lop phu thi bam nut "Dò DOM"
  //  trong bang thiet lap, no moi mo ra rieng.
  // ====================================================================
  function doDOM(nhan) {
    const g = (t, ds) => {
      if (!ds.length) return;
      console.log('%c' + t, 'font-weight:bold;color:#0a8');
      console.table(ds);
    };
    console.group('%cD4Lister · dò DOM · ' + nhan, 'font-weight:bold');

    g('nút có aria-label', [...document.querySelectorAll('button[aria-label]')]
      .filter(dangHien)
      .map(b => ({ nhan: b.getAttribute('aria-label'), chu: (b.textContent || '').trim().slice(0, 40), trangThai: b.getAttribute('data-state') || '', danhDau: b.getAttribute('aria-checked') || '' })));

    g('nút KHÔNG có aria-label', [...document.querySelectorAll('button:not([aria-label])')]
      .filter(dangHien)
      .map(b => ({ chu: (b.textContent || '').trim().slice(0, 46), vaiTro: b.getAttribute('role') || '', trangThai: b.getAttribute('data-state') || '', moRong: b.getAttribute('aria-expanded') || '' }))
      .filter(x => x.chu));

    g('ô nhập', [...document.querySelectorAll('input,textarea')]
      .filter(dangHien)
      .map(i => ({ loai: i.type || i.tagName, goiY: i.placeholder || '', nhan: i.getAttribute('aria-label') || '', giaTri: String(i.value).slice(0, 30) })));

    g('phần tử có vai trò', [...document.querySelectorAll('[role]')]
      .filter(dangHien)
      .filter(e => !/^(button|presentation|none)$/i.test(e.getAttribute('role')))
      .map(e => ({ vaiTro: e.getAttribute('role'), nhan: e.getAttribute('aria-label') || '', giaTri: e.getAttribute('data-value') || '', chu: (e.textContent || '').trim().slice(0, 46) })));

    console.groupEnd();
  }

  //  Mo lan luot ba o chon o dau form (loai do / do hiem / ten mon) roi ghi
  //  lai cai xo ra. Day la thu DUY NHAT ban luu Ctrl+S khong chup duoc.
  async function doLopPhu() {
    const dau = [...document.querySelectorAll('button')].filter(b =>
      dangHien(b) && !b.getAttribute('aria-label') && (b.textContent || '').trim()
      && b.closest('[cmdk-root]') === null);
    console.group('%cD4Lister · dò lớp phủ', 'font-weight:bold;color:#c60');
    for (const b of dau.slice(0, 12)) {
      const chu = (b.textContent || '').trim().slice(0, 30);
      const truoc = document.querySelectorAll('[role="option"],[role="radio"],[cmdk-list]').length;
      bamThat(b);
      await doi(320);
      const sau = [...document.querySelectorAll('[role="option"],[role="radio"]')].filter(dangHien);
      if (sau.length > truoc) {
        console.log('%cbấm "' + chu + '" → xổ ra:', 'color:#0a8;font-weight:bold');
        console.table(sau.map(e => ({
          vaiTro: e.getAttribute('role'),
          chu: (e.textContent || '').trim().slice(0, 50),
          giaTri: e.getAttribute('data-value') || '',
          danhDau: e.getAttribute('aria-checked') || e.getAttribute('aria-selected') || '',
        })));
        document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
        await doi(200);
      }
    }
    console.groupEnd();
    nhac('Đã dò xong — mở Console (F12) rồi gửi tôi phần D4Lister · dò lớp phủ');
  }

  // --- bat su kien dan --------------------------------------------------
  document.addEventListener('paste', e => {
    // Don ky tu vo hinh truoc da. BOM (U+FEFF) tung dinh lien vao TEN MON o
    // dong dau, va game thi chen khoang trang khong ngat (U+00A0) vao ten.
    // Ca hai deu khong nhin thay duoc nhung du lam hong phep doi chieu ten.
    const t = ((e.clipboardData || window.clipboardData)?.getData('text/plain') || '')
      .replace(/[﻿​-‍⁠]/g, '')
      .replace(/ /g, ' ');
    if (!t.trim()) return;
    batGio();
    nhip('nhận chữ dán');
    chuDaDan = t;
    loiThem = [];          // lan dan moi -> xoa loi cu
    canhBaoLoaiDo = '';
    giaBiDoi = null;
    khongBietSao = false;
    daTuThem = false;
    // Món mới -> thư mục mới. Tên món là dòng đầu của chữ dán sang.
    moThuMucLuot(t.split(/\r?\n/).map(l => l.trim()).filter(Boolean)[0] || '');
    chupBuoc('0-vua-dan-chu');
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
  // BAY: danh sach ASPECT cung mang data-slot="data-picker-results". Dung
  // nham vao do la ext bam bua mot Aspect nao do len mon. Nhan ra bang o
  // "Search aspects" ben canh, va bang luoi loai do neu dang o buoc do.
  const khungBase = () => {
    if (typeof oTimAspect === 'function' && oTimAspect()) return null;
    if (typeof luoiBase === 'function' && luoiBase().length) return null;
    return document.querySelector('[data-slot="data-picker-results"]');
  };

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

  function choFormDungXong(text) {
    if (dongHo) clearInterval(dongHo);
    const batDau = Date.now();
    let truoc = -1, mocYen = 0;
    // Ba dong dau cua chu D4Lister gui sang:
    //   [0] TEN MON          "GALVANIC AZURITE"
    //   [1] do hiem + loai   "Ancestral Unique Ring"
    //   [2] suc manh         "900 Item Power"   (co the khong co)
    const dong = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
    const tenChu   = dong[0] || '';
    const dongLoai = dong[1] || '';
    const mSM = text.match(/^\s*([\d,]+)\s+Item Power\b/mi);
    const soSM = mSM ? parseFloat(mSM[1].replace(/,/g, '')) : 0;
    // Mo ta Aspect / suc manh rieng, de dung mon Legendary
    const mAs = text.match(/^#D4L-ASPECT:(.*)$/m);
    const cauAspect = mAs ? mAs[1].trim() : '';
    dangChonBase = false;
    soLanChonBase = 0;
    dangTaoItem = false;
    daThuTaoItem = false;
    soDayThang = 0;
    nhac('Đã nhận chữ. Đang đợi form…');
    dongHo = setInterval(() => {
      // V3 KHONG CON ANH, nen khong co ai dung ra mon ca -> ext phai tu lam.
      // Chi lam khi tren trang CHUA co dong affix nao va dang thay hop thoai
      // ADD ITEM. Dan de lai mon cu thi khong dung nham mon moi.
      if (dangTaoItem) return;
      if (CD.tuTaoItem && !daThuTaoItem && !timCacDong().length
          && (oThemItem() || luoiBase().length)) {
        daThuTaoItem = true;
        dangTaoItem = true;
        taoItem(tenChu, dongLoai, cauAspect).then(kq => {
          if (kq.ok) {
            nhac('Đã dựng món (' + kq.cach + '): ' + kq.ten);
            // Doi trang ve xong form roi moi dat suc manh
            setTimeout(() => {
              const nac = datSucManh(soSM, tachDongLoai(dongLoai).toTien);
              if (nac) nhac('Sức mạnh: ' + nac);
              if (CD.doDOM) doDOM('ngay sau khi dựng món');
              dangTaoItem = false;
            }, 700);
            return;
          }
          // Do Legendary: trang bat chon Aspect truoc, ma ten Aspect thi
          // chu cua game khong noi ro. Dung lai cho ban chon — chon xong
          // vong cho nay tu nhan ra form da dung va dien tiep, khong phai
          // dan lai.
          if (kq.choAspect) nhac(kq.viSao);
          else {
            loiThem.push('Không dựng được món: ' + kq.viSao);
            nhac('Không dựng được món: ' + kq.viSao);
          }
          dangTaoItem = false;
        });
        return;
      }
      // Dang o buoc chon base thi chon giup roi bam Next, dung bat user ngoi
      // chon cai hinh. Thu toi da hai lan cho khoi bam mai.
      if (CD.tuChonBase && !dangChonBase && soLanChonBase < 2 && khungBase()) {
        dangChonBase = true;
        chonBase(tenChu).then(() => { dangChonBase = false; });
        return;
      }
      if (dangChonBase) return;
      // Dem theo MAN HINH chu khong theo so sach cua form. Hai le do:
      //   1. so sach doi ngay khi ext ghi, nen dem theo no la tu ru minh
      //   2. V3 co the tao ra mon KHONG CO dong affix nao (do rare bam tu
      //      luoi loai do) — cho "n > 0" thi doi mai khong bao gio toi.
      //      Mon da dung xong nhan ra bang o "ADD STANDARD AFFIXES".
      const n = soDongManHinh();
      const coForm = n > 0 || !!nutMoDs();
      if (coForm && n === truoc) {
        if (Date.now() - mocYen >= YEN_TOI_DA) {
          clearInterval(dongHo); dongHo = null;
          nhip('form món dựng xong, bắt đầu điền');
          apDung(text); return;
        }
      } else {
        mocYen = Date.now();
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
  // ====================================================================
  //  DO DUONG GHI THANG (dang tim hieu — chua dung vao viec gi)
  //
  //  Doc ma nguon cua trang thay: no dung react-hook-form, va co san ham
  //  ocrResultToEquipmentCreateFormState() bien KET QUA OCR thanh ca cai
  //  form. Ket qua OCR may chu tra ve co dang:
  //     { status:"success", rawText, normalizedLines: string[], ... }
  //  normalizedLines chinh la thu D4Lister dang co san.
  //
  //  Neu voi toi duoc bo dieu khien form (getValues/setValue) thi ghi ca
  //  mon do vao MOT PHAT, khoi go tung chu vao o tim affix nua.
  //  Ctrl+Shift+K = do xem co voi toi duoc khong, in ra Console.
  // ====================================================================
  const laBoForm = o => !!o && typeof o === 'object' &&
    typeof o.getValues === 'function' && typeof o.setValue === 'function';

  // BAY DA SUP MOT LAN, va la cai bay nang nhat: trang la mot ung dung mot
  // trang, trong cay React co THE CON NHIEU BO DIEU KHIEN FORM cua nhung
  // man hinh truoc do chua bi don. Vo phai cai cu thi:
  //   - ghi vao khong thay gi doi tren man hinh
  //   - them dong lai them vao form cua mon KHAC
  //   - doc lai van ra dung so vua ghi -> bang bao thanh cong, khong ai biet
  // Da gap that: man hinh la thanh kiem 3 dong, ma form lai la mon nhan cu
  // (Willpower 112, Cooldown Reduction 10).
  // => Khong nhan bua bat cu bo dieu khien nao. Phai DOI CHIEU: so dong va
  //    ten tung dong phai khop voi cai dang hien tren man hinh.
  // Ghi lai MOI bo dieu khien da gap va vi sao bi tu choi — de khong phai
  // doan nua khi no bao "khong voi toi duoc form".
  let ungVienForm = [];
  function ghiUngVien2(v, dsDom, viSao) {
    if (ungVienForm.length > 6) return;
    ungVienForm.push({
      viSao: viSao,
      soDongTrongForm: Array.isArray(v) ? v.length : null,
      tenTrongForm: Array.isArray(v)
        ? v.slice(0, 8).map(a => tenThuan((a && (a.description || a.name)) || '')) : null,
      soDongTrenManHinh: dsDom ? dsDom.length : null,
      tenTrenManHinh: dsDom ? dsDom.slice(0, 8).map(d => d.ten) : null,
    });
  }

  function dungFormNay(bo) {
    if (!laBoForm(bo)) return false;
    let v;
    try { v = bo.getValues('affixes'); } catch (e) { ghiUngVien2(null, null, 'getValues nem loi'); return false; }
    if (v === undefined) {
      // BAY DA SUP MOT LAN: mon VUA DUNG XONG chua co dong affix nao, nen
      // react-hook-form chua dang ky mang do — getValues('affixes') tra ve
      // UNDEFINED chu khong phai mang rong. Ban truoc loai thang, thanh ra
      // khong form nao duoc nhan, va ext lot xuong form CU (form cu co mang
      // vi da dung roi) -> ghi vao cho khong ai nhin thay.
      // Nhan ra form dang song bang cac o KHAC cua chinh no.
      let tong;
      try { tong = bo.getValues(); } catch (e) { return false; }
      if (!tong || typeof tong !== 'object' || Array.isArray(tong)) return false;
      const k = Object.keys(tong);
      const co = t => k.indexOf(t) >= 0;
      if (co('affixes') || co('sockets') || co('itemPower') || co('rarity')
          || co('aspect') || co('uniquePower')) {
        // Va phai dung song: man hinh cung phai chua co dong affix nao.
        const domNay = cheDo() === 'classic' ? dongClassic() : dongBeta();
        if (!domNay.length) return true;
      }
      ghiUngVien2(null, null, 'affixes undefined, cac o cua form: ' + k.slice(0, 12).join(','));
      return false;
    }
    if (!Array.isArray(v)) { ghiUngVien2(null, null, 'affixes khong phai mang'); return false; }
    const dsDom = cheDo() === 'classic' ? dongClassic() : dongBeta();
    if (!dsDom.length) {
      // BAY DA SUP MOT LAN — va no lam hong ca luot dan cua V3.
      //
      // Ban truoc: man hinh chua co dong nao thi GAT DAU voi moi form. Hoi
      // V2 khong sao, vi trang tu quet anh roi dung san dong, man hinh
      // khong bao gio rong.
      // V3 thi ext tu dung mon, va moi lan dung mon moi la trang thay MOT
      // FORM MOI — form cu bi thao khoi man hinh nhung VAN CON VET trong
      // cay React. Dan lan thu hai tro di la vo phai cai cu: no con giu
      // cac muc cua lan truoc, nen ext tuong "form da co 2 dong" roi chi
      // di them 2 dong con lai; ma ghi vao form chet thi man hinh dung im.
      //
      // Form DANG SONG phai khop voi man hinh: man hinh 0 o affix thi mang
      // affixes cung phai rong.
      if (v.length) {
        ghiUngVien2(v, dsDom,
          'man hinh 0 o affix ma form co ' + v.length + ' muc -> form cu, da chet');
        return false;
      }
      return true;
    }
    // BAY DA SUP MOT LAN: phep doi chieu duoi day chi doi "moi dong dang
    // hien deu co trong form", nen mot form DA CHET van lot neu no tinh co
    // chua ten cua dong dang hien — ma nhung ten pho bien (Cooldown
    // Reduction, Critical Strike Damage Multiplier) thi mon nao chang co.
    // Nhat ky 23/09/2026: form chet giu 4 muc, man hinh 1 dong, ten trung
    // mot cai -> lot. Roi ext ghi vao do va ngoi cho 2 x 450ms vo ich.
    // => Doi them: SO DONG phai bang nhau.
    if (v.length !== dsDom.length) {
      ghiUngVien2(v, dsDom,
        'form ' + v.length + ' muc nhung man hinh ' + dsDom.length + ' dong');
      return false;
    }

    // So THEO TEN, khong theo thu tu: trang co the xep khac, va form co the
    // giu them muc khong ve ra man hinh. Chi doi mot dieu — MOI DONG DANG
    // HIEN deu phai co mot muc tuong ung trong form.
    const daDung = {};
    for (const d of dsDom) {
      let thay = false;
      for (let i = 0; i < v.length; i++) {
        if (daDung[i]) continue;
        const ten = tenThuan((v[i] && (v[i].description || v[i].name)) || '');
        if (ten && diemKhop(ten, d.ten) >= DIEM_CHAC) { daDung[i] = true; thay = true; break; }
      }
      if (!thay) {
        ghiUngVien2(v, dsDom, 'dong "' + d.ten + '" tren man hinh khong co trong form');
        return false;
      }
    }
    return true;
  }

  // Di nguoc len tu MOT the cu the, tim doi tuong co getValues/setValue.
  function boFormTu(neo) {
    const k = Object.keys(neo).find(x => x.indexOf('__reactFiber$') === 0 ||
                                         x.indexOf('__reactInternalInstance$') === 0);
    if (!k) return null;
    for (let f = neo[k], i = 0; f && i < 100; f = f.return, i++) {
      const p = f.memoizedProps;
      if (p && dungFormNay(p.value)) return p.value;
      if (dungFormNay(p)) return p;
      if (dungFormNay(f.stateNode)) return f.stateNode;

      // BAY DA SUP MOT LAN: ban truoc chi soi memoizedProps va stateNode,
      // KHONG soi chuoi hook. Ma useForm() tra ve mot doi tuong nam trong
      // HOOK STATE cua chinh thanh phan goi no — dung cho khong nhin toi.
      // Ket qua: chi vo duoc cai form nam trong props cua mot Provider cu
      // (form cua mon dung truoc do, chua bi don), roi ghi vao do.
      // Nhat ky 23/09/2026 bat duoc: form giu [Willpower, Maximum Life,
      // Critical Strike Damage Multiplier, Cooldown Reduction] — dung bon
      // chi so cua mon Legendary lan truoc — trong khi man hinh la chiec
      // nhan Unique.
      let h = f.memoizedState, j = 0;
      while (h && typeof h === 'object' && j < 80) {
        const x = h.memoizedState;
        if (dungFormNay(x)) return x;
        if (x && typeof x === 'object' && !Array.isArray(x))
          for (const t of Object.keys(x))
            if (dungFormNay(x[t])) return x[t];
        h = h.next; j++;
      }
    }
    return null;
  }

  //  Het duong neo thi QUET CA CAY. Cham hon nhung chac an: cai form dang
  //  song thi bao gio cung co o day, con form cu se bi dungFormNay() loai
  //  vi so dong cua no khong khop man hinh.
  function quetCaCayTimForm() {
    const goc = fiberGoc();
    if (!goc) return null;
    const ngan = [goc];
    let n = 0;
    while (ngan.length && n < 30000) {
      const f = ngan.pop();
      if (!f) continue;
      n++;
      const p = f.memoizedProps;
      if (p && dungFormNay(p.value)) return p.value;
      if (dungFormNay(p)) return p;
      let h = f.memoizedState, j = 0;
      while (h && typeof h === 'object' && j < 80) {
        const x = h.memoizedState;
        if (dungFormNay(x)) return x;
        if (x && typeof x === 'object' && !Array.isArray(x))
          for (const t of Object.keys(x))
            if (dungFormNay(x[t])) return x[t];
        h = h.next; j++;
      }
      if (f.child) ngan.push(f.child);
      if (f.sibling) ngan.push(f.sibling);
    }
    return null;
  }

  // ====================================================================
  //  TU DO — va TU GHI FILE khi khong do duoc
  //
  //  Moi lan dan, tien ich tu di tim bo dieu khien form va danh muc affix.
  //  Tim duoc thi dung luon, khong noi gi. KHONG tim duoc thi ghi mot file
  //  nho vao thu muc Tai xuong de con biet duong ma sua — user khong phai
  //  bam phim nao, khong phai chep gi tu Console.
  //  Moi phien chi ghi MOT lan cho moi loai, khong lam phien.
  // ====================================================================
  const daGhiNhatKy = {};

  function ghiNhatKy(loai, du) {
    if (daGhiNhatKy[loai]) return;
    daGhiNhatKy[loai] = true;

    // Mac dinh CHI ghi ra Console. Tai han mot file ve may moi lan chay la
    // phien, va phan lon truong hop no chi xac nhan lai cai da biet.
    // Can file that thi bat cong tac "Ghi file dò" trong thiet lap.
    ghi('[D4Lister] dò — ' + loai + ':', du);
    if (!CD.ghiFileDo) return;
    try {
      const chu = JSON.stringify(du, (k, v) => {
        if (v instanceof Node) return '[DOM ' + (v.nodeName || '?') + ']';
        if (typeof v === 'function') return '[hàm]';
        return v;
      }, 1);
      const b = new Blob([chu], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(b);
      a.download = 'd4lister-do-' + loai + '.json';
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(a.href), 5000);
      ghi('[D4Lister] đã ghi file dò: ' + a.download);
    } catch (e) {
      ghi('[D4Lister] không ghi được file dò:', e);
    }
  }

  // Goi sau moi lan dien xong. Im lang khi moi thu on.
  // BAY DA SUP MOT LAN — va lan nay la bay do CHINH TOI dat ra: ghi file do
  // ngay khi khong voi toi duoc form. Nhung khong voi toi duoc form KHONG
  // PHAI la hong: tien ich tu quay ve duong o nhap cu, van dien dung va du,
  // chi mat khoang hop le va phai go chu khi them dong. Lan dan DAU TIEN
  // (luc form chua dung xong) la no ghi ngay mot file, ma moi phien chi ghi
  // mot lan nen file do nam lai, trong y nhu bao hong trong khi moi thu van
  // chay dung. => Chi ghi khi THUC SU hong: khong doc noi mot dong nao.
  function tuDo() {
    const fm = timFormTrang();
    if (!fm) {
      const soDong = timCacDong().length;
      if (soDong === 0)
        ghiNhatKy('khong-doc-duoc-dong-nao', {
          viSao: 'khong voi toi duoc form, ma duong o nhap cung khong ra dong nao',
          duongDan: location.href,
          banExt: BAN,
          soOAffixBeta: document.querySelectorAll('input[aria-label="Affix value"]').length,
          soNutXoaClassic: document.querySelectorAll('button[title="Remove attribute"]').length,
          soOSo: document.querySelectorAll('input[inputmode="decimal"]').length,
        });
      return;
    }
    // DOI CHIEU HAI BEN: so sach trong form va cai dang hien tren man hinh.
    // Lech nhau la dau hieu ghi vao form ma o hien thi khong doi theo.
    try {
      const v0 = fm.getValues();
      const dsForm = Array.isArray(v0.affixes) ? v0.affixes : [];
      const dsDom = cheDo() === 'classic' ? dongClassic() : dongBeta();
      const lech = dsForm.length !== dsDom.length || dsForm.some((a, i) => {
        const d = dsDom[i];
        if (!d) return true;
        const x = parseFloat(String(d.lay()).replace(/,/g, ''));
        const y = Array.isArray(a.values) ? a.values[0] : null;
        return isFinite(x) && y !== null && Math.abs(x - y) > 0.001;
      });
      if (lech)
        ghiNhatKy('lech-form-va-man-hinh', {
          viSao: 'so sach trong form khac cai dang hien tren man hinh',
          soDongTrongForm: dsForm.length,
          soDongTrenManHinh: dsDom.length,
          trongForm: dsForm.map(a => ({
            ten: tenThuan(a.description || ''), so: (a.values || [])[0],
            sao: !!a.isGreater, min: a.minValue, max: a.maxValue })),
          trenManHinh: dsDom.map(d => ({ ten: d.ten, so: d.lay(), sao: d.laySao() })),
          docDuocTuAnh: chuDaDoc,
          banExt: BAN,
        });
    } catch (e) {}

    // Thieu danh muc cung KHONG phai hong — chi la khau them affix phai go
    // chu. Luc do da co file do rieng ("phai-go-chu") kem ly do cu the roi,
    // ghi them mot file nua chi lam nhieu.
    if (!layKhoAffix() && !daThuMoKho)
      layKhoAffixCoMo();
  }

  // Mot muc trong danh muc affix trong the nao: co ma, co cau mo ta kieu
  // "+# Willpower", va co khoang hop le.
  // BAY DA SUP MOT LAN: phep nhan dang cu chi doi co id + cau mo ta chua "#".
  // ASPECT cung thoa het (vd "Your Maximum Ferocity stacks are increased by
  // # [4-6]."), nen no vo phai danh muc 364 aspect roi tuong da xong — khong
  // bao gio di tim danh muc affix that nua. Phai doi DUNG type "AFFIX".
  const laMucAffix = o => !!o && typeof o === 'object' && !Array.isArray(o) &&
    typeof o.id === 'string' && typeof o.description === 'string' &&
    o.description.indexOf('#') >= 0 && o.type === 'AFFIX';

  // BAY DA SUP LAN HAI: ban truoc doi CA muc dau LAN muc cuoi deu la AFFIX.
  // Danh muc that la mot BO TRON — affix, inherent, aspect, unique nam
  // chung mot mang — nen muc cuoi khong phai AFFIX, va cai mang 1450 muc
  // can tim bi vut di ngay truoc mat. File do bat duoc: no ghi ro
  // "mangGanGiongNhat: 1450 muc, mau la type AFFIX".
  // Gio LAY MAU VAI CHO: phan lon phai la muc co ma + cau mo ta, va phai co
  // it nhat mot muc AFFIX trong do. Loc rieng AFFIX ra luc di khop ten.
  const laKhoAffix = a => {
    if (!Array.isArray(a) || a.length < 40) return false;
    const n = a.length;
    const moc = [0, 1, n >> 2, n >> 1, n - (n >> 2), n - 2, n - 1];
    let hop = 0, coAffix = 0;
    for (const i of moc) {
      const o = a[i];
      if (!o || typeof o !== 'object' || typeof o.id !== 'string' ||
          typeof o.description !== 'string') continue;
      hop++;
      if (o.type === 'AFFIX') coAffix++;
    }
    return hop >= 5 && coAffix >= 1;
  };

  // Ghi lai MOI mang ung vien gap tren duong quet, de lan sau khong phai
  // doan nua: ten khoa, so muc, va loai cua muc dau.
  let cacUngVien = [];

  // Lung tim MANG chua toan bo affix. Co no thi them affix chi con la day
  // them mot muc vao mang affixes — khong bam chuot phat nao.
  //
  // BAI HOC LAN TRUOC: chi lung NGUOC LEN tu o nhap thi khong ra, vi cai
  // giu danh muc co the la mot nhanh KHAC han, khong phai to tien cua o
  // nhap. Lan nay quet CA CAY tu goc xuong, va soi ca chuoi hook chu khong
  // chi props — gia tri cua useState/useQuery nam trong hook.
  function ghiUngVien(ten, m) {
    if (!Array.isArray(m) || m.length < 20 || cacUngVien.length > 40) return;
    const d = m[0];
    if (!d || typeof d !== 'object' || typeof d.id !== 'string') return;
    if (cacUngVien.some(x => x.ten === ten && x.soMuc === m.length)) return;
    cacUngVien.push({ ten: ten, soMuc: m.length, loai: d.type || '?',
                      tenMau: d.name || null, moTaMau: d.description || null });
  }

  function fiberGoc() {
    const ds = [document.body].concat([...document.body.children]);
    for (const el of ds) {
      const k = Object.keys(el).find(x => x.indexOf('__reactContainer$') === 0);
      if (k) return el[k];
    }
    const b = document.querySelector('input, button');
    if (!b) return null;
    const k2 = Object.keys(b).find(x => x.indexOf('__reactFiber$') === 0);
    if (!k2) return null;
    let f = b[k2];
    while (f.return) f = f.return;
    return f;
  }

  // Xet mot doi tuong: chinh no la kho? hay mot khoa trong no la kho?
  // Tien the ghi lai cai GAN GIONG NHAT de con biet duong ma sua.
  function xetNguon(o, hop) {
    if (!o || typeof o !== 'object') return;
    if (laKhoAffix(o)) { hop.thay = o; hop.tu = 'chính nó'; return; }
    if (Array.isArray(o)) {
      ghiUngVien('(mảng trần)', o);
      if (o.length > hop.gan.soMuc && o.length >= 5 && laMucAffix(o[0]))
        hop.gan = { soMuc: o.length, mau: o[0] };
      return;
    }
    let dem = 0;
    for (const ten of Object.keys(o)) {
      if (++dem > 60) break;
      const x = o[ten];
      if (Array.isArray(x)) ghiUngVien(ten, x);
      if (laKhoAffix(x)) { hop.thay = x; hop.tu = '.' + ten; return; }
      if (Array.isArray(x) && x.length > hop.gan.soMuc && x.length >= 5 && laMucAffix(x[0]))
        hop.gan = { soMuc: x.length, mau: x[0] };
      if (x && typeof x === 'object' && !Array.isArray(x)) {
        let dem2 = 0;
        for (const ten2 of Object.keys(x)) {
          if (++dem2 > 60) break;
          const y = x[ten2];
          if (Array.isArray(y)) ghiUngVien(ten + '.' + ten2, y);
          if (laKhoAffix(y)) { hop.thay = y; hop.tu = '.' + ten + '.' + ten2; return; }
          if (Array.isArray(y) && y.length > hop.gan.soMuc && y.length >= 5 && laMucAffix(y[0]))
            hop.gan = { soMuc: y.length, mau: y[0] };
        }
      }
    }
  }

  function timKhoAffix() {
    const goc = fiberGoc();
    if (!goc) return null;
    cacUngVien = [];
    const hop = { thay: null, tu: '', gan: { soMuc: 0, mau: null }, soFiber: 0 };
    const ngan = [goc];
    while (ngan.length && hop.soFiber < 30000) {
      const f = ngan.pop();
      if (!f) continue;
      hop.soFiber++;
      xetNguon(f.memoizedProps, hop);
      if (hop.thay) break;
      let h = f.memoizedState, i = 0;
      while (h && typeof h === 'object' && i < 80) {
        xetNguon(h.memoizedState, hop);
        if (hop.thay) break;
        h = h.next; i++;
      }
      if (hop.thay) break;
      if (f.child) ngan.push(f.child);
      if (f.sibling) ngan.push(f.sibling);
    }
    khoGanNhat = hop.gan;
    soFiberDaQuet = hop.soFiber;
    return hop.thay ? { ds: hop.thay, tu: hop.tu } : null;
  }

  let khoGanNhat = { soMuc: 0, mau: null }, soFiberDaQuet = 0;


  // BAY: querySelector voi nhieu mau ngan cach bang dau phay tra ve the
  // DUNG DAU TRONG TAI LIEU, khong phai mau dau tien. De chung mot cau thi
  // no vo phai the <form> bao ngoai — the do khong mang moc React nen tim
  // hoai khong ra. Phai thu TUNG MAU MOT, va thu ca cac the cung mau.
  let lucBaoHutForm = 0;

  function timFormTrang() {
    ungVienForm = [];
    // NEO TOT NHAT: chinh nut "ADD STANDARD AFFIXES". No nam trong khoi
    // affix cua form DANG SONG, va co mat ngay ca khi chua co dong nao —
    // dung cai ext can cho mon vua dung xong.
    const nutKhoi = nutMoDs();
    if (nutKhoi) {
      const bo0 = boFormTu(nutKhoi);
      if (bo0) return bo0;
    }
    const mau = ['input[aria-label="Affix value"]',
                 'input[inputmode="decimal"]',
                 'button[title="Remove attribute"]',
                 'button[aria-label^="Remove "]',
                 // MON VUA DUNG XONG CHUA CO DONG AFFIX NAO, nen bon neo
                 // tren deu khong ton tai, va phep kiem dungFormNay() cung
                 // bi vo hieu (khong co dong nao de doi chieu) -> neo "form"
                 // chung chung de vo phai form khac, ghi vao khong hien ra
                 // gi, roi phai lui ve duong go chu tung dong mot.
                 // Ba neo duoi day CHAC CHAN thuoc dung cai form dang mo:
                 'input[placeholder="Price"]',
                 'input[aria-label="Effect value"]',
                 'button[aria-label$="socket"]',
                 'button[aria-label$="sockets"]',
                 'form'];
    for (const m of mau)
      for (const neo of document.querySelectorAll(m)) {
        const bo = boFormTu(neo);
        if (bo) return bo;
      }
    // Het duong neo: quet ca cay. Ton hon nhung chi chay khi da bi ket.
    const boQuet = quetCaCayTimForm();
    if (boQuet) return boQuet;

    // Van khong ra thi ghi lai LY DO cua tung ung vien — nhung dung ghi
    // lien tuc, ham nay duoc goi rat nhieu lan trong mot luot dan.
    if (Date.now() - lucBaoHutForm > 3000) {
      lucBaoHutForm = Date.now();
      ghi('[D4Lister] KHÔNG với tới form. Ứng viên đã xét: '
        + (ungVienForm.length ? JSON.stringify(ungVienForm) : '(không có ứng viên nào)'));
    }
    return null;
  }

  document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.shiftKey && (e.key === 'K' || e.key === 'k')) {
      e.preventDefault();
      const fm = timFormTrang();
      if (!fm) {
        ghi('[D4Lister] KHÔNG với tới được form của trang.');
        nhac('Không với tới form của trang — xem Console.');
        return;
      }
      const v = fm.getValues();
      ghi('[D4Lister] VỚI TỚI ĐƯỢC form. Các ô trong form:', Object.keys(v));
      ghi('[D4Lister] Toàn bộ giá trị:', v);

      // San DANH MUC AFFIX. Co no thi them affix cung khoi bam chuot: chi
      // viec day mot muc moi vao mang affixes la xong.
      const kho = timKhoAffix();
      if (kho) {
        ghi('[D4Lister] THẤY danh mục affix: ' + kho.ds.length +
          ' mục, lấy từ ' + kho.tu);
        ghi('[D4Lister] Ba mục đầu:', kho.ds.slice(0, 3));
        ghi('[D4Lister] Dán khối này cho Claude:',
          JSON.stringify(kho.ds.slice(0, 3), null, 1).slice(0, 4000));
      } else {
        ghi('[D4Lister] KHÔNG thấy danh mục affix. ' +
          'Thử mở danh sách + ADD AFFIX ra rồi bấm lại Ctrl+Shift+K.');
      }
      nhac('Với tới được form — mở Console (F12) xem.');
      return;
    }
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
  ghi('[D4Lister] da nap - ban ' + BAN);

  let chip = null;
  function dungChip() {
    const c = document.createElement('div');
    c.id = 'd4l-chip';
    c.textContent = 'D4Lister ' + BAN;
    c.title = 'D4Lister — bấm để mở thiết lập.';
    c.onmouseenter = () => c.style.opacity = '1';
    c.onmouseleave = () => c.style.opacity = '.55';
    c.onclick = moThietLap;
    c.style.cssText = 'position:fixed;right:12px;bottom:12px;z-index:999998;' +
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
