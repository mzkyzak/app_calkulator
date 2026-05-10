# 🚀 Aplikasi kalkulator mzkyzak

Aplikasi kalkulator yang dibangun menggunakan **Flutter**. Tidak hanya sekadar alat hitung, aplikasi ini menggabungkan komputasi saintifik dengan UI/UX kelas atas: *Glassmorphism*, efek animasi (JJ), Liquid RGB Border, dan sistem penyimpanan riwayat permanen.

Didesain eksklusif oleh **mzkyzak**.

---

## ✨ Fitur Utama (Key Features)

* 📐 **Scientific & Basic Calculation:** Mendukung operasi matematika dasar hingga fungsi saintifik kompleks (Sin, Cos, Tan, Log, Ln, Akar, Pangkat, Pi, dan Euler). Menggunakan `math_expressions` untuk komputasi akurat.
* 🧠 **Smart Memory Functions (MC, MR, M+, M-):** Fitur penyimpanan memori dengan indikator "M = ..." yang muncul otomatis di layar saat ada angka yang disimpan.
* 💾 **Permanent History Drawer:** Riwayat perhitungan disimpan ke penyimpanan lokal menggunakan `shared_preferences`. Data tidak akan hilang meskipun aplikasi ditutup paksa.
* 🪩 **JJ Mode (Jedag Jedug Animation):** Mode interaktif yang memberikan efek *bass pulse* (layar berdetak) dan *haptic shake* (getaran hebat) saat tombol `=` ditekan. Mode ini bisa dimatikan/dinyalakan melalui tombol khusus.
* 🌈 **Liquid RGB Border:** Border animasi neon berputar yang dinamis mengelilingi area *keypad*.
* ✨ **Extreme Glassmorphism UI:** Desain tembus pandang futuristik dengan efek pantulan cahaya (*inner glow*), *blur*, dan bayangan realistis.
* 🌌 **Live Cyber Background:** Latar belakang dinamis dengan proyektil *Hyper Orbs* yang bergerak secara diagonal tanpa henti.
* 🎵 **DJ Kicau Mania (Loop):** Fitur pemutar musik latar belakang (Background Music) yang berjalan secara *loop* paksa tanpa henti selama kamu menghitung. Bisa di-toggle on/off melalui ikon musik di header.
* 🌓 **Smart Theme Toggle:** Pergantian mulus antara Mode Gelap (Dark) dan Terang (Light) yang mengubah seluruh palet warna dan intensitas *glow*.
* 📱 **100% Responsive Layout:** Dibangun murni menggunakan sistem *Flex/Expanded*, dijamin anti-kepotong di ukuran layar HP apa pun.

---

## 🛠️ Teknologi & Dependencies (Tech Stack)

Aplikasi ini menggunakan Flutter SDK dengan tambahan *package* eksternal berikut:
* [flutter_animate](https://pub.dev/packages/flutter_animate) - Untuk animasi visual yang *fluid* (shimmer, shake, pulse, fade, slide).
* [math_expressions](https://pub.dev/packages/math_expressions) - Untuk mem-*parsing* dan mengevaluasi rumus matematika yang diketik secara langsung (*Live Preview*).
* [shared_preferences](https://pub.dev/packages/shared_preferences) - Untuk menyimpan data riwayat (History) secara permanen di memori HP.

---

## ⚙️ Cara Instalasi & Menjalankan (Getting Started)

### Prasyarat
Pastikan komputer lo sudah ter-install **Flutter SDK** dan MSVC v143 (atau v142) - C++ x64/x86 build tools.Windows 10 SDK atau Windows 11 SDK.C++ CMake tools for Windows Di visual studio installer.

### Langkah-langkah:
1. **Clone repositori ini** atau ekstrak *source code* ke komputermu.
2. Buka terminal di dalam folder proyek, lalu jalankan perintah untuk mengunduh semua dependencies:
   ```cmd
   flutter pub get

    ```
    ```cmd
    flutter run
