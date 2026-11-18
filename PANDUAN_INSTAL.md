# Panduan instal Sinau di HP

Aplikasi Sinau langsung terhubung ke Supabase (internet), jadi **tidak butuh localhost / laptop menyala**.

## Android (APK)

**Paling mudah:** buka bagian **[Download APK di README](README.md#download-apk)** dari HP, lalu download APK *universal* versi terbaru (jalan di semua HP).

Versi lebih kecil per jenis HP ada di folder `UAS/APK Sinau/` (laptop). Pilih **satu** sesuai HP:

| File | Ukuran | Untuk |
|---|---|---|
| `Sinau-arm64 (HP Android modern).apk` | ±18 MB | **Hampir semua HP** keluaran 2017 ke atas — coba ini dulu |
| `Sinau-armv7 (HP Android lama).apk` | ±16 MB | HP lama / murah yang menolak file arm64 ("aplikasi tidak kompatibel") |
| `Sinau-x86_64 (emulator laptop).apk` | ±20 MB | Emulator Android di laptop |
| `Sinau-universal (semua HP, besar).apk` | ±52 MB | Cadangan: jalan di semua perangkat |

Cek jenis HP (opsional): pasang aplikasi **CPU-Z** / **Droid Hardware Info** → lihat bagian *Instruction Set*: `arm64-v8a` → pakai arm64, `armeabi-v7a` → pakai armv7.

1. Kirim file APK yang dipilih ke HP Android (WhatsApp ke diri sendiri, Google Drive, atau kabel USB).
2. Buka file tersebut di HP → **Instal**.
3. Kalau muncul peringatan **"Instal dari sumber tidak dikenal"**, izinkan untuk aplikasi yang dipakai membuka file (mis. File Manager / Chrome / WhatsApp).
4. Buka aplikasi **Sinau** → masuk dengan akun yang sudah terdaftar.

Membuat ulang APK (setelah kode berubah):

```bash
flutter build apk --release --split-per-abi
```

Hasilnya di `build/app/outputs/flutter-apk/` (`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`).
Aplikasi ini tidak diunggah ke Play Store; APK dibagikan langsung.

## iPhone / iPad (iOS)

Aplikasi iOS **hanya bisa di-build di Mac** dengan **Xcode** (aturan Apple; tidak bisa dari Windows).
Folder `ios/` sudah disiapkan (nama "Sinau", ikon, izin kamera & galeri).

Di Mac:

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Di Xcode: pilih **Runner → Signing & Capabilities → Team** (Apple ID), sambungkan iPhone, lalu klik **Run ▶**.
Untuk dibagikan ke banyak orang lewat **TestFlight / App Store** dibutuhkan akun **Apple Developer** (berbayar).

## Web (semua perangkat lewat browser)

```bash
flutter build web --release
```

Upload folder `build/web` ke hosting (Firebase Hosting, Netlify, Vercel, GitHub Pages) agar bisa dibuka dari HP apa pun lewat link.
