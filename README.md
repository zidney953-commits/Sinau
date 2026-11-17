# Sinau

Aplikasi belajar pemrograman (Python & Java) untuk UAS Praktikum Mobile Programming.
Flutter + GetX + Supabase REST API (package `http`, tanpa SDK Supabase).

## Menjalankan

```bash
flutter pub get
flutter run            # HP/emulator Android
flutter run -d chrome  # browser
```

## Struktur

```
lib/
  core/config.dart        URL Supabase + publishable key
  core/api.dart           klien REST: /auth/v1, /rest/v1, /storage/v1
  core/theme.dart         palet warna & font (sama dengan prototipe)
  data/models.dart        Profile, Language, Unit, Lesson, Question, LessonProgress
  data/repo.dart          semua query ke tabel Supabase
  controllers/            AuthController (GetX): login, daftar, sesi, logout
  screens/auth/           splash, masuk, daftar
  screens/user/           Belajar (bahasa → tugas → pembahasan), materi + tugas, peringkat
  screens/admin/          Dasbor, Kelola materi (terbit/draf), Anggota (aktif/nonaktif)
  screens/common/         Profil (ganti foto: kamera/galeri/hapus, ubah nama, keluar)
```

## Akun

Akun dibuat lewat halaman Daftar di aplikasi, atau di Supabase → Authentication → Add user.
Email berikut otomatis mendapat nama & role saat akunnya dibuat:

| Email | Nama | Role |
|---|---|---|
| abdillahkais1@gmail.com | Kais | admin |
| zidney.masariellah@gmail.com | Zidney | admin |
| mubaro22097856@gmail.com | Nouval | user |

## Endpoint yang dipakai

| Fitur | Endpoint |
|---|---|
| Masuk | `POST /auth/v1/token?grant_type=password` |
| Daftar | `POST /auth/v1/signup` |
| Keluar | `POST /auth/v1/logout` |
| Materi | `GET /rest/v1/units?select=*,lessons(*)` · `GET /rest/v1/questions` |
| Simpan progres | `POST /rest/v1/lesson_progress?on_conflict=user_id,lesson_id` |
| Peringkat | `GET /rest/v1/leaderboard` |
| Profil | `GET/PATCH /rest/v1/profiles` |
| Foto profil | `POST /storage/v1/object/avatars/{uid}/avatar.jpg` |
| Admin | `PATCH /rest/v1/lessons` (terbit/draf) · `PATCH /rest/v1/profiles` (aktif/nonaktif) |
