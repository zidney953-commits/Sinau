# Plugin Figma — Prototipe Sinau

Membuat prototipe Figma lengkap (user + admin) dari screenshot aplikasi Flutter Sinau,
lengkap dengan klik antar-halaman. Keluar (logout) kembali ke halaman Masuk.

## Cara menjalankan (Figma Desktop)

1. Buka file Figma **Sinau** di aplikasi **Figma Desktop** (plugin development tidak bisa di browser).
2. Menu **Plugins → Development → Import plugin from manifest…**
3. Pilih file `manifest.json` di folder ini.
4. Menu **Plugins → Development → Sinau Prototype Builder** → plugin berjalan ±10 detik.
5. Muncul halaman baru **"Prototype Sinau"** berisi 27 layar.
6. Tekan **Present** (ikon ▶ kanan atas), lalu pilih alur **"Alur User"** atau **"Alur Admin"**.

## Isi prototipe

- **Alur User (14 layar + dialog):** Masuk, Daftar, Lupa sandi, Belajar, Beranda bahasa,
  Daftar pembahasan, Materi, Soal, Informasi, Peringkat, Profil (atas & bawah), Foto profil,
  Kirim masukan, Konfirmasi keluar → **kembali ke Masuk**.
- **Alur Admin (11 layar + dialog):** Masuk, Dasbor (2 bagian), Kelola materi, Ubah pembahasan,
  Editor soal, Anggota, Masukan, Informasi, Tambah informasi, Profil, Konfirmasi keluar →
  **kembali ke Masuk**.
- Menu bawah (Belajar/Informasi/Peringkat/Profil dan Dasbor/Materi/Anggota/Masukan/Informasi)
  bisa diklik di setiap layar.

## Mengubah gambar

Ganti file di folder `images/` (ukuran 375×812), lalu jalankan `python build.py` untuk membuat ulang `code.js`.
