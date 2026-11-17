// Sinau — pembuat prototipe Figma (user + admin).
// Jalankan di Figma Desktop: Plugins → Development → Import plugin from manifest… → pilih manifest.json → Run.
// Gambar layar diambil dari aplikasi Flutter Sinau (localhost:8794) dan disisipkan di bawah (IMAGES).

const IMAGES = __IMAGES__;

const W = 375, H = 812, GAP = 140;
const INK = { r: 23 / 255, g: 26 / 255, b: 43 / 255 };
const PRIMARY = { r: 67 / 255, g: 56 / 255, b: 202 / 255 };
const ERR = { r: 194 / 255, g: 55 / 255, b: 43 / 255 };
const BG = { r: 1, g: 254 / 255, b: 250 / 255 };
const INK2 = { r: 74 / 255, g: 78 / 255, b: 102 / 255 };

async function run() {
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });

  const page = figma.createPage();
  page.name = 'Prototype Sinau';
  await figma.setCurrentPageAsync(page);
  page.backgrounds = [{ type: 'SOLID', color: { r: 0.93, g: 0.93, b: 0.95 } }];

  const frames = {};
  function text(str, x, y, size, style, color, parent, width) {
    const t = figma.createText();
    t.fontName = { family: 'Inter', style };
    t.fontSize = size;
    t.characters = str;
    t.fills = [{ type: 'SOLID', color }];
    if (width) { t.textAutoResize = 'HEIGHT'; t.resize(width, t.height); }
    t.x = x; t.y = y;
    (parent || page).appendChild(t);
    return t;
  }
  function screen(key, label, col, row, storeKey) {
    const f = figma.createFrame();
    f.name = label;
    f.resize(W, H);
    f.x = 200 + col * (W + GAP);
    f.y = 260 + row * (H + 260);
    f.cornerRadius = 0;
    f.clipsContent = true;
    const img = figma.createImage(figma.base64Decode(IMAGES[key]));
    f.fills = [{ type: 'IMAGE', imageHash: img.hash, scaleMode: 'FILL' }];
    page.appendChild(f);
    text(label, f.x, f.y - 48, 22, 'Semi Bold', INK);
    frames[storeKey || key] = f;
    return f;
  }

  // Judul baris
  text('ALUR USER', 200, 120, 40, 'Bold', PRIMARY);
  text('Mulai dari "U · Masuk" → Masuk → belajar → profil → Keluar kembali ke Masuk', 200, 176, 20, 'Regular', INK2);
  text('ALUR ADMIN', 200, 120 + H + 260, 40, 'Bold', INK);
  text('Mulai dari "A · Masuk" → Masuk → dasbor & kelola → profil → Keluar kembali ke Masuk', 200, 176 + H + 260, 20, 'Regular', INK2);

  // ---------- Layar USER (baris 0) ----------
  const U = [
    ['u01_login', 'U · Masuk'], ['u02_daftar', 'U · Daftar'], ['u03_lupa', 'U · Lupa sandi'],
    ['u10_belajar', 'U · Belajar (pilih bahasa)'], ['u11_beranda', 'U · Beranda bahasa'], ['u12_tugas', 'U · Daftar pembahasan'],
    ['u13_materi', 'U · Materi'], ['u14_soal', 'U · Soal'], ['u20_informasi', 'U · Informasi'], ['u30_peringkat', 'U · Peringkat'],
    ['u40_profil', 'U · Profil'], ['u41_profil_bawah', 'U · Profil (bawah)'], ['u42_foto', 'U · Foto profil'], ['u43_masukan', 'U · Kirim masukan'],
  ];
  U.forEach(([k, l], i) => screen(k, l, i, 0));
  // ---------- Layar ADMIN (baris 1) ----------
  const A = [
    ['u01_login', 'A · Masuk', 'a00_login'], ['a10_dasbor', 'A · Dasbor'], ['a11_dasbor_unit', 'A · Dasbor (kemampuan)'],
    ['a20_materi', 'A · Kelola materi'], ['a21_editor', 'A · Ubah pembahasan'], ['a22_soal', 'A · Editor soal'],
    ['a30_anggota', 'A · Anggota'], ['a40_masukan', 'A · Masukan'], ['a50_informasi', 'A · Informasi'], ['a51_tambah', 'A · Tambah informasi'],
    ['a60_profil', 'A · Profil'],
  ];
  // A · Masuk memakai gambar yang sama dengan U · Masuk, tetapi disimpan dengan kunci a00_login
  A.forEach(([k, l, storeKey], i) => screen(k, l, i, 1, storeKey));

  // ---------- Dialog Keluar (dibuat langsung di Figma) ----------
  function logoutDialog(baseKey, label, col, row, storeKey) {
    const f = screen(baseKey, label, col, row, storeKey);
    const scrim = figma.createRectangle();
    scrim.resize(W, H); scrim.fills = [{ type: 'SOLID', color: INK, opacity: 0.5 }]; scrim.name = 'Latar gelap';
    f.appendChild(scrim);
    const card = figma.createFrame();
    card.name = 'Dialog konfirmasi';
    card.resize(327, 200); card.x = 24; card.y = 296; card.cornerRadius = 24;
    card.fills = [{ type: 'SOLID', color: BG }];
    card.effects = [{ type: 'DROP_SHADOW', color: { r: 0, g: 0, b: 0, a: 0.25 }, offset: { x: 0, y: 8 }, radius: 24, spread: 0, visible: true, blendMode: 'NORMAL' }];
    f.appendChild(card);
    text('Keluar dari Sinau?', 24, 24, 20, 'Bold', INK, card);
    text('Kamu perlu masuk lagi untuk melanjutkan belajar. Progres tetap tersimpan.', 24, 62, 14, 'Regular', INK2, card, 279);
    const batal = text('Batal', 168, 150, 15, 'Semi Bold', PRIMARY, card);
    const keluar = text('Keluar', 242, 150, 15, 'Bold', ERR, card);
    return { f, batal: [24 + 152, 296 + 138, 64, 44], keluar: [24 + 228, 296 + 138, 76, 44] };
  }
  const dU = logoutDialog('u41_profil_bawah', 'U · Konfirmasi keluar', U.length, 0, 'dlg_u');
  const dA = logoutDialog('a60_profil', 'A · Konfirmasi keluar', A.length, 1, 'dlg_a');

  // ---------- Hotspot & navigasi ----------
  let hs = 0;
  async function link(fromKey, rect, toKey, name) {
    const from = typeof fromKey === 'string' ? frames[fromKey] : fromKey;
    const to = typeof toKey === 'string' ? frames[toKey] : toKey;
    const h = figma.createFrame();
    h.name = 'hotspot → ' + (name || to.name);
    h.fills = [];
    h.resize(rect[2], rect[3]);
    h.x = rect[0]; h.y = rect[1];
    from.appendChild(h);
    await h.setReactionsAsync([{
      trigger: { type: 'ON_CLICK' },
      actions: [{ type: 'NODE', destinationId: to.id, navigation: 'NAVIGATE', transition: { type: 'DISSOLVE', easing: { type: 'EASE_OUT' }, duration: 0.2 }, preserveScrollPosition: false, resetVideoPosition: false }],
    }]);
    hs++;
  }
  const navU = async (k) => {
    await link(k, [0, 748, 94, 64], 'u10_belajar', 'Belajar');
    await link(k, [94, 748, 94, 64], 'u20_informasi', 'Informasi');
    await link(k, [188, 748, 93, 64], 'u30_peringkat', 'Peringkat');
    await link(k, [281, 748, 94, 64], 'u40_profil', 'Profil');
  };
  const fabU = async (k) => link(k, [158, 676, 200, 56], 'u43_masukan', 'Kirim masukan');
  const navA = async (k) => {
    await link(k, [0, 748, 75, 64], 'a10_dasbor', 'Dasbor');
    await link(k, [75, 748, 75, 64], 'a20_materi', 'Materi');
    await link(k, [150, 748, 75, 64], 'a30_anggota', 'Anggota');
    await link(k, [225, 748, 75, 64], 'a40_masukan', 'Masukan');
    await link(k, [300, 748, 75, 64], 'a50_informasi', 'Informasi');
  };
  const shieldA = async (k) => link(k, [306, 20, 46, 46], 'a60_profil', 'Profil admin');

  // USER
  await link('u01_login', [24, 485, 327, 52], 'u10_belajar', 'Masuk');
  await link('u01_login', [226, 552, 60, 28], 'u02_daftar', 'Daftar');
  await link('u01_login', [226, 440, 122, 28], 'u03_lupa', 'Lupa kata sandi');
  await link('u02_daftar', [322, 16, 46, 46], 'u01_login', 'Tutup');
  await link('u02_daftar', [24, 558, 327, 52], 'u10_belajar', 'Buat akun');
  await link('u03_lupa', [322, 16, 46, 46], 'u01_login', 'Tutup');
  await link('u10_belajar', [20, 156, 335, 170], 'u11_beranda', 'Python');
  await link('u10_belajar', [20, 340, 335, 170], 'u11_beranda', 'Java');
  await navU('u10_belajar'); await fabU('u10_belajar');
  await link('u11_beranda', [14, 14, 46, 46], 'u10_belajar', 'Kembali');
  await link('u11_beranda', [249, 214, 90, 42], 'u13_materi', 'Mulai');
  await link('u11_beranda', [256, 314, 92, 28], 'u10_belajar', 'Ganti bahasa');
  await link('u11_beranda', [20, 378, 335, 112], 'u12_tugas', 'Tugas 1');
  await link('u12_tugas', [10, 18, 46, 46], 'u11_beranda', 'Kembali');
  await link('u12_tugas', [21, 236, 333, 82], 'u13_materi', 'Apa itu program?');
  await link('u13_materi', [8, 8, 48, 48], 'u12_tugas', 'Tutup');
  await link('u13_materi', [20, 740, 335, 52], 'u14_soal', 'Kerjakan tugas');
  await link('u14_soal', [8, 8, 48, 48], 'u12_tugas', 'Tutup');
  await link('u14_soal', [20, 740, 335, 52], 'u11_beranda', 'Lanjut');
  await navU('u20_informasi'); await fabU('u20_informasi');
  await navU('u30_peringkat'); await fabU('u30_peringkat');
  await navU('u40_profil'); await fabU('u40_profil');
  await link('u40_profil', [203, 143, 36, 36], 'u42_foto', 'Ubah foto');
  await link('u40_profil', [20, 498, 335, 150], 'u41_profil_bawah', 'Gulir ke bawah');
  await navU('u41_profil_bawah'); await fabU('u41_profil_bawah');
  await link('u41_profil_bawah', [0, 0, 375, 76], 'u40_profil', 'Gulir ke atas');
  await link('u41_profil_bawah', [20, 566, 335, 52], dU.f, 'Keluar');
  await link('u42_foto', [0, 0, 375, 545], 'u40_profil', 'Tutup');
  await link('u43_masukan', [0, 0, 375, 370], 'u40_profil', 'Tutup');
  await link('u43_masukan', [20, 740, 335, 52], 'u40_profil', 'Kirim');
  await link(dU.f, dU.batal, 'u41_profil_bawah', 'Batal');
  await link(dU.f, dU.keluar, 'u01_login', 'Keluar → Masuk');

  // ADMIN
  await link('a00_login', [24, 485, 327, 52], 'a10_dasbor', 'Masuk');
  await navA('a10_dasbor'); await shieldA('a10_dasbor');
  await link('a10_dasbor', [20, 518, 335, 228], 'a11_dasbor_unit', 'Kemampuan belajar');
  await navA('a11_dasbor_unit'); await shieldA('a11_dasbor_unit');
  await link('a11_dasbor_unit', [20, 80, 335, 170], 'a10_dasbor', 'Gulir ke atas');
  await navA('a20_materi'); await shieldA('a20_materi');
  await link('a20_materi', [20, 288, 205, 50], 'a21_editor', 'Apa itu program?');
  await link('a21_editor', [10, 18, 46, 46], 'a20_materi', 'Kembali');
  await link('a21_editor', [20, 560, 335, 180], 'a22_soal', 'Gulir ke soal');
  await link('a22_soal', [10, 18, 46, 46], 'a20_materi', 'Kembali');
  await navA('a30_anggota'); await shieldA('a30_anggota');
  await navA('a40_masukan'); await shieldA('a40_masukan');
  await navA('a50_informasi');
  await link('a50_informasi', [226, 18, 130, 44], 'a51_tambah', 'Tambah');
  await link('a51_tambah', [0, 0, 375, 300], 'a50_informasi', 'Tutup');
  await link('a51_tambah', [20, 740, 335, 52], 'a50_informasi', 'Kirim');
  await link('a60_profil', [10, 18, 46, 46], 'a10_dasbor', 'Kembali');
  await link('a60_profil', [20, 538, 335, 52], dA.f, 'Keluar');
  await link(dA.f, dA.batal, 'a60_profil', 'Batal');
  await link(dA.f, dA.keluar, 'a00_login', 'Keluar → Masuk');

  page.flowStartingPoints = [
    { nodeId: frames.u01_login.id, name: 'Alur User' },
    { nodeId: frames.a00_login.id, name: 'Alur Admin' },
  ];
  figma.viewport.scrollAndZoomIntoView(page.children);
  figma.closePlugin(`Prototipe Sinau selesai: ${Object.keys(frames).length} layar, ${hs} hotspot. Buka mode Present untuk mencoba.`);
}

run().catch(e => figma.closePlugin('Gagal: ' + (e && e.message ? e.message : e)));
