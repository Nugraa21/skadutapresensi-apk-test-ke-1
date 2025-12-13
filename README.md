# Skaduta Presensi - Aplikasi Mobile (Flutter)

Aplikasi presensi digital sekolah berbasis Flutter untuk siswa, guru, dan admin. Terintegrasi penuh dengan backend PHP.

## Fitur Utama
- Login otomatis (token-based, tetap login setelah tutup app)
- Absen masuk/pulang dengan validasi GPS (radius 200m dari sekolah)
- Izin, pulang cepat, penugasan khusus (upload dokumen + selfie)
- Riwayat presensi pribadi
- Admin: Approve/Tolak presensi, kelola user, rekap bulanan
- Superadmin: CRUD user & admin
- UI modern dengan gradient, card, dan animasi halus
- Offline-first ready (token disimpan lokal)

## Screenshot
*(Tambahkan screenshot app kamu di sini nanti)*

## Teknologi
- Flutter 3.19+
- Dart
- Packages: http, shared_preferences, geolocator, image_picker, camera, flutter_map, latlong2, encrypt, intl, url_launcher

## Instalasi
1. Clone repository:
   ```bash
   git clone https://github.com/username/skaduta-presensi-flutter.git
   ```
2. Masuk folder:
   ```bash
   cd skaduta-presensi-flutter
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Edit URL backend di `lib/api/api_service.dart`:
   ```dart
   static const String baseUrl = "https://ngrok-url-kamu.ngrok-free.app/backendapk/";
   ```
5. Jalankan:
   ```bash
   flutter run
   ```

## Setup Backend
Pastikan backend PHP sudah aktif dan ngrok berjalan. Lihat repo backend:  
[Backend aplikasi](https://github.com/Nugraa21/API-menggunakan-php-untuk-http-get.git)

## Fitur User
- Absen Masuk/Pulang (otomatis disetujui)
- Izin & Pulang Cepat (perlu approval)
- Penugasan (dengan dokumen)
- Lihat riwayat presensi

## Fitur Admin/Superadmin
- Approve/Tolak presensi
- Kelola user (tambah, edit, hapus)
- Rekap presensi bulanan
- Lihat detail per user

## Keamanan
- API Key header (`X-App-Key`)
- Token login (30 hari)
- Enkripsi data sensitif
- Bypass ngrok warning page

## Lisensi
Project ini untuk penggunaan internal SMK Negeri 2 Yogyakarta.

