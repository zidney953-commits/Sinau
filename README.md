# Sinau

**Sinau** (bahasa Jawa: *belajar*) adalah aplikasi belajar pemrograman dari dasar (**Python** & **Java**)
untuk UAS Praktikum Mobile Programming — UIN Maulana Malik Ibrahim Malang.

🌐 **Coba versi web:** https://zidney953-commits.github.io/Sinau/
📱 **Download APK Android:** lihat [Download APK](#download-apk) di bawah.

Materi disusun bertahap per **Tugas → Pembahasan**: baca materi singkat, kerjakan 3 soal, kumpulkan XP,
jaga streak harian, dan bersaing di papan peringkat. Admin mengelola materi dan memantau kemampuan belajar user.

**Kelompok 4** — Powered by **KELOMPOK-4**

| Nama | NIM |
|---|---|
| Mochammad Zidney Mas'ariellah | 240605110011 |
| Muhammad Abdillah Kais Al Akmal | 240605110180 |
| Naufal Mubarok | 240605110041 |

---

## Download APK

Pilih versi, klik **Download APK**, lalu buka file-nya di HP Android → **Instal**
(izinkan *Instal dari sumber tidak dikenal* jika diminta). Versi baru bisa dipasang langsung di atas versi lama,
progres belajar tetap aman karena tersimpan di server.

<!-- APK-LIST:START -->
**👉 [Download Sinau versi terbaru (1.3.11,26)](https://github.com/zidney953-commits/Sinau/raw/main/apk%20sinau/Versi%201.3.11%2C26/Sinau_v1.3.11%2C26%20%28universal%20-%20semua%20HP%29.apk)** — APK universal, jalan di semua HP Android.

| Versi | Tanggal & jam update | Ukuran | Download |
|---|---|---|---|
| **1.3.11,26** 🆕 **Terbaru** | 18 Nov 2026, 23.00 WIB | 52.8 MB | [⬇️ Download APK](https://github.com/zidney953-commits/Sinau/raw/main/apk%20sinau/Versi%201.3.11%2C26/Sinau_v1.3.11%2C26%20%28universal%20-%20semua%20HP%29.apk) |
| **1.2.11,26** | 18 Nov 2026, 16.38 WIB | 51.8 MB | [⬇️ Download APK](https://github.com/zidney953-commits/Sinau/raw/main/apk%20sinau/Versi%201.2.11%2C26/Sinau_v1.2.11%2C26%20%28universal%20-%20semua%20HP%29.apk) |
| **1.1.11,26** | 18 Nov 2026, 07.43 WIB | 51.6 MB | [⬇️ Download APK](https://github.com/zidney953-commits/Sinau/raw/main/apk%20sinau/Versi%201.1.11%2C26/Sinau_v1.1.11%2C26%20%28universal%20-%20semua%20HP%29.apk) |
| **1.0.11,26** | 17 Nov 2026, 22.46 WIB | 51.6 MB | [⬇️ Download APK](https://github.com/zidney953-commits/Sinau/raw/main/apk%20sinau/Versi%201.0.11%2C26/Sinau-universal%20%28semua%20HP%2C%20besar%29.apk) |

_Tabel ini diperbarui otomatis setiap commit (lihat `scripts/update_readme_apk.py`)._
<!-- APK-LIST:END -->

Arti nomor versi, contoh **1.3.11,26**: `1` = aplikasi ke-2 KELOMPOK-4 · `3` = update ke-3 · `11,26` = November 2026.

---

## Fitur

**User**
- Masuk, daftar (angkatan otomatis), lupa kata sandi dengan **kode OTP via email**
- Pilih bahasa → Tugas 1–4 → pembahasan berurutan (terkunci sampai lulus)
- Materi (penjelasan, poin penting, contoh kode, tips) + soal **pilihan ganda** & **susun kode**
- XP, target harian 30 XP, **Kebun Sinau**, peringkat per bahasa
- **Streak**: hari menyala jika target harian 100%, kembali ke 0 setelah 3 hari tidak menyala,
  **8 level warna** (merah tua → ungu menyala) + halaman **kalender streak** per bulan & tahun
- **Berita TI hari ini** (berita teknologi terbaru, berganti setiap hari) & postingan promosi APK
- Informasi dari admin, kirim masukan (saran / error / soal salah)
- Profil: ubah nama, **foto profil dari kamera atau galeri**, **Tentang Aplikasi**

**Admin**
- Dasbor: pendaftar baru per bulan & kemampuan belajar per tugas
- Kelola materi: **CRUD** tugas, pembahasan, soal (terbit / draf)
- Anggota: cari, filter angkatan, aktif / nonaktif
- Masukan pengguna: filter & ubah status
- Informasi: tambah & hapus pengumuman

Tampilan responsif: **HP** (menu bawah), **tablet** (rail), **laptop** (sidebar).
Tema **Terang / Gelap / ikut sistem perangkat** (diatur di Profil, user & admin).

---

## Teknologi

| Bagian | Dipakai |
|---|---|
| Aplikasi | Flutter (Android, iOS, Web) |
| State management | **GetX** — `GetxController`, `.obs`, `Obx`, `Bindings`, navigasi `Get.toNamed` |
| REST API | Supabase (`/auth/v1`, `/rest/v1`, `/storage/v1`, `/functions/v1`) lewat package **`http`** |
| Database | PostgreSQL (Supabase) + Row Level Security |
| Edge Function | `tech-news` (Deno) — mengambil RSS berita teknologi Antara & CNN Indonesia |
| Lainnya | `image_picker`, `shared_preferences`, `google_fonts`, `url_launcher` |

Alur data: **Flutter UI → GetX Controller → Repo + Api (`http`, async) → Supabase REST → PostgreSQL**

---

## Pemenuhan ketentuan UAS

| Ketentuan | Implementasi |
|---|---|
| User Interface | Row, Column, Card, TextField, ListView, layout responsif |
| Navigation (≥ 3 halaman) | 15+ halaman, `GetPage` + `Get.toNamed` / `Get.to` / `Get.back` |
| REST API | `lib/core/api.dart` — GET / POST / PATCH / DELETE ke Supabase |
| CRUD | Tugas, pembahasan, soal, informasi, masukan, profil, progres |
| Model & JSON | `lib/data/models.dart` — `fromJson()` & `toJson()` |
| GetX | `lib/controllers/` — 8 controller, data `.obs`, layar memakai `Obx` |
| Asynchronous | `Future` / `async` / `await`, loading, pesan gagal + **Coba lagi** |
| Form & validasi | Masuk, daftar, lupa sandi, editor materi & soal, informasi, masukan |
| Fitur tambahan | Kamera/galeri, OTP email, search & filter, gamifikasi, peringkat, tema gelap, berita TI |

---

## Struktur

```
lib/
  main.dart                     GetMaterialApp, route + Binding (/user, /admin)
  core/
    config.dart                 URL Supabase + publishable key
    api.dart                    klien REST (Auth, PostgREST, Storage)
    theme.dart                  palet warna terang & gelap, font
  data/
    models.dart                 Profile, Language, Unit, Lesson, Question, LessonProgress, Post, FeedbackItem, NewsItem
    repo.dart                   semua query ke tabel Supabase + berita TI
    streak.dart                 aturan streak & 8 level warna
  controllers/
    auth_controller.dart        login, daftar, sesi, logout
    app_controllers.dart        LoadController + Learn, News, Promo, Streak, Rank, Info, Dashboard, Content, Members, Feedback, Nav
    theme_controller.dart       tema Terang / Gelap / Sistem
  widgets/                      komponen bersama (ObxLoad, AppShell responsif, kartu, avatar)
  screens/
    auth/                       splash, masuk, daftar, lupa sandi (OTP)
    user/                       belajar (berita TI, promosi), materi & soal, streak, peringkat
    admin/                      dasbor, kelola materi, editor pembahasan & soal, anggota, masukan
    common/                     profil, tentang aplikasi, informasi, kirim masukan
assets/icon/                    ikon aplikasi, logo Python & Java
assets/Gambar/                  gambar postingan promosi
apk sinau/Versi */              APK universal tiap versi (untuk download)
scripts/update_readme_apk.py    memperbarui tabel Download APK di README
supabase/migrations/            skema database, RLS, trigger, data materi
supabase/functions/tech-news/   Edge Function berita TI
supabase/templates/             template email kode OTP
```

---

## Endpoint REST API

| Fitur | Method & endpoint |
|---|---|
| Masuk / daftar / keluar | `POST /auth/v1/token` · `POST /auth/v1/signup` · `POST /auth/v1/logout` |
| Lupa sandi (OTP) | `POST /auth/v1/recover` · `POST /auth/v1/verify` · `PUT /auth/v1/user` |
| Materi | `GET /rest/v1/units?select=*,lessons(*)` · `GET /rest/v1/questions` |
| Kelola materi (admin) | `POST / PATCH / DELETE /rest/v1/units`, `/lessons`, `/questions` |
| Progres & XP | `POST /rest/v1/lesson_progress?on_conflict=user_id,lesson_id` |
| Peringkat | `GET /rest/v1/leaderboard` |
| Profil & anggota | `GET / PATCH /rest/v1/profiles` |
| Informasi | `GET / POST / DELETE /rest/v1/posts` |
| Masukan | `GET / POST / PATCH /rest/v1/feedback` |
| Foto profil | `POST /storage/v1/object/avatars/{uid}/avatar.jpg` |
| Berita TI | `GET /functions/v1/tech-news` |

---

## Menjalankan

```bash
flutter pub get
flutter run -d chrome   # browser
flutter run             # HP / emulator Android
```

## Build

```bash
# APK Android, kecil per jenis prosesor (±16–20 MB)
flutter build apk --release --split-per-abi

# Web
flutter build web --release
```

iOS hanya bisa di-build di **Mac + Xcode** — lihat [PANDUAN_INSTAL.md](PANDUAN_INSTAL.md).

### Menambah APK versi baru

1. Naikkan versi di `pubspec.yaml` dan `lib/core/config.dart`, lalu `flutter build apk --release`.
2. Salin `build/app/outputs/flutter-apk/app-release.apk` ke folder baru `apk sinau/Versi X.Y.MM,YY/`
   dengan nama yang mengandung kata **universal**, mis. `Sinau_v1.4.12,26 (universal - semua HP).apk`.
3. `git add .` → `git commit` → `git push`. Tabel **Download APK** di README terisi sendiri saat commit
   (hook `.githooks/pre-commit`), lengkap dengan tanggal & jam update versinya.

Satu kali per komputer, aktifkan hook-nya: `git config core.hooksPath .githooks`

## Akun

Akun dibuat lewat halaman **Daftar** di aplikasi. Role **admin** hanya bisa diberikan dari database
(tabel `profiles`), tidak bisa dari aplikasi.
