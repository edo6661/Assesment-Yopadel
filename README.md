# Absensi Lapangan (Yopadel)

Aplikasi mobile berbasis Flutter untuk sistem absensi pekerja lapangan. Aplikasi ini mengintegrasikan deteksi wajah (Face Recognition), pencatatan titik koordinat (GPS/Geolocation), dan perekaman waktu secara _real-time_, yang datanya langsung terhubung ke Google Spreadsheet.

## Fitur Utama

- **Face Detection:** Memastikan kehadiran pengguna dengan mendeteksi wajah menggunakan Google ML Kit sebelum absensi diproses.
- **Validasi Lokasi (GPS):** Mengambil data _latitude_ dan _longitude_ akurat dari perangkat pekerja saat absen.
- **Real-time Timestamp:** Mencatat waktu absensi secara presisi.
- **Integrasi Google Sheets:** Data absensi langsung dikirim dan direkap secara otomatis ke Google Spreadsheet melalui Google Apps Script (REST API).

## Database (Google Spreadsheet)

Data absensi yang dikirim dari aplikasi akan terekam secara otomatis pada _spreadsheet_ berikut:
**[Rekap Data Absensi Pekerja](https://docs.google.com/spreadsheets/d/1JvAppMnwDseC_sPHklEKrMkONQHf3cVZj1c1I_UJBJA/edit?usp=sharing)**

_(Pastikan Apps Script URL di dalam aplikasi sudah sesuai dengan deployment yang terhubung ke sheet ini)._

## Teknologi yang Digunakan

- **Frontend:** Flutter & Dart
- **Face Detection:** `google_mlkit_face_detection`
- **Geolocation:** `geolocator`
- **Backend / Database:** Google Apps Script & Google Spreadsheet

## Cara Menjalankan Project (Local Development)

1. Clone repository ini:
   ```bash
   git clone [https://github.com/edo6661/Assesment-Yopadel](https://github.com/edo6661/Assesment-Yopadel)
   ```
