# Sinau

**Sinau** (bahasa Jawa: *belajar*) adalah aplikasi belajar pemrograman dari dasar (**Python** & **Java**)
untuk UAS Praktikum Mobile Programming — UIN Maulana Malik Ibrahim Malang.

Materi disusun bertahap per **Tugas → Pembahasan**: baca materi singkat, kerjakan 3 soal, kumpulkan XP,
jaga streak harian, dan bersaing di papan peringkat. Admin mengelola materi dan memantau kemampuan belajar user.

**Kelompok 4**

| Nama | NIM |
|---|---|
| Mochammad Zidney Mas'ariellah | 240605110011 |
| Muhammad Abdillah Kais Al Akmal | 240605110180 |
| Naufal Mubarok | 240605110041 |

---

## Fitur

**User**
- Masuk, daftar (angkatan otomatis), lupa kata sandi dengan **kode OTP via email**
- Pilih bahasa → Tugas 1–4 → pembahasan berurutan (terkunci sampai lulus)
- Materi (penjelasan, poin penting, contoh kode, tips) + soal **pilihan ganda** & **susun kode**
- XP, streak harian, target harian 30 XP, **Kebun Sinau**, peringkat per bahasa
- Informasi dari admin, kirim masukan (saran / error / soal salah)
- Profil: ubah nama, **foto profil dari kamera atau galeri**

**Admin**
- Dasbor: pendaftar baru per bulan & kemampuan belajar per tugas
- Kelola materi: **CRUD** tugas, pembahasan, soal (terbit / draf)
- Anggota: cari, filter angkatan, aktif / nonaktif
- Masukan pengguna: filter & ubah status
- Informasi: tambah & hapus pengumuman

Tampilan responsif: **HP** (menu bawah), **tablet** (rail), **laptop** (sidebar).

---

## Teknologi

| Bagian | Dipakai |
|---|---|
| Aplikasi | Flutter (Android, iOS, Web) |
| State management | **GetX** — `GetxController`, `.obs`, `Obx`, `Bindings`, navigasi `Get.toNamed` |
| REST API | Supabase (`/auth/v1`, `/rest/v1`, `/storage/v1`) lewat package **`http`** |
| Database | PostgreSQL (Supabase) + Row Level Security |
| Lainnya | `image_picker`, `shared_preferences`, `google_fonts` |

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
| Fitur tambahan | Kamera/galeri, OTP email, search & filter, gamifikasi, peringkat |

---

## Struktur

```
lib/
  main.dart                     GetMaterialApp, route + Binding (/user, /admin)
  core/
    config.dart                 URL Supabase + publishable key
    api.dart                    klien REST (Auth, PostgREST, Storage)
    theme.dart                  warna & font
  data/
    models.dart                 Profile, Language, Unit, Lesson, Question, LessonProgress, Post, FeedbackItem
    repo.dart                   semua query ke tabel Supabase
  controllers/
    auth_controller.dart        login, daftar, sesi, logout
    app_controllers.dart        LoadController + Learn, Rank, Info, Dashboard, Content, Members, Feedback, Nav
  widgets/                      komponen bersama (ObxLoad, AppShell responsif, kartu, avatar)
  screens/
    auth/                       splash, masuk, daftar, lupa sandi (OTP)
    user/                       belajar, materi & soal, peringkat
    admin/                      dasbor, kelola materi, editor pembahasan & soal, anggota, masukan
    common/                     profil, informasi, kirim masukan
supabase/migrations/            skema database, RLS, trigger, data materi
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
APK siap pasang tersedia di halaman **Releases** repository ini.

## Akun

Akun dibuat lewat halaman **Daftar** di aplikasi. Role **admin** hanya bisa diberikan dari database
(tabel `profiles`), tidak bisa dari aplikasi.
