# Study Group Finder

Platform aplikasi mobile dan web untuk menemukan dan membuat study groups. Pengguna dapat membuat grup belajar, mencari grup yang sesuai, bergabung dengan grup, serta menerima notifikasi undangan dan pengingat meetup.

## ✨ Fitur Utama

### Autentikasi & Akun
- Login/Register dengan email dan password
- Autentikasi via Firebase Authentication
- Logout dan session management

### Study Groups
- **Buat Group**: Buat grup belajar dengan detail:
  - Nama mata kuliah, Deskripsi
  - Universitas, Jurusan, Mata Kuliah (kategori)
  - Lokasi meetup, Jadwal (tanggal & jam)
  - GPS coordinates (dari device atau map picker)
  
- **Cari & Filter**: Temukan grup dengan filter universitas, jurusan, mata kuliah, atau pencarian teks
- **Bergabung**: Join grup dengan satu klik (group creator tidak perlu approve)
- **Edit/Hapus**: Hanya creator yang bisa mengedit atau menghapus grup
- **View Anggota**: Lihat jumlah member dalam setiap grup

### Lokasi & Map
- **GPS Perangkat**: Ambil koordinat lokasi langsung dari device
- **Map Picker**: Pilih lokasi di peta interaktif dengan flutter_map (CARTO CDN)
- **Map View**: Lihat lokasi grup di peta dengan marker GPS
- **Tile Provider**: CARTO basemaps untuk performa optimal

### Notifikasi
- **Notifikasi Undangan**: Kirim notifikasi undangan ke grup
- **Pengingat Meetup**: Jadwalkan notifikasi 1 menit sebelum meetup
- **Local Notifications**: Support iOS, Android dengan foreground presentation
- **Test Feature**: Button untuk test notifikasi langsung dari app

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.11+**: Framework multi-platform development
- **Material Design 3**: Modern UI components

### Backend & Data
- **Firebase**:
  - Authentication (Email/Password)
  - Firestore Database (study groups, members)
  - Cloud Messaging (push notifications)

### Key Packages
- `flutter_map: ^8.3.0` — Interactive maps
- `flutter_local_notifications: ^21.0.0` — Local notifications
- `firebase_core: ^4.7.0`, `cloud_firestore: ^6.3.0`, `firebase_auth: ^6.4.0`
- `geolocator: ^14.0.2` — GPS geolocation
- `flutter_timezone: ^5.0.2` — Timezone support
- `shared_preferences: ^2.3.3` — Local preferences storage

### Platforms
- **iOS** (12.0+), **Android** (5.0+), **Web** (Chrome, Firefox, Safari)

## 📋 Prerequisites

- **Flutter SDK**: 3.11.4 atau lebih baru ([Install](https://flutter.dev/docs/get-started/install))
- **Firebase Project**: [Create di Firebase Console](https://console.firebase.google.com)
  - Enable: Authentication, Firestore Database, Cloud Messaging
- **Xcode** (untuk iOS): `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- **Android Studio** (untuk Android development)

## 🚀 Setup & Installation

### 1. Clone & Install
```bash
git clone <repository-url>
cd study_group_finder
flutter pub get
```

### 2. iOS Setup
```bash
cd ios
pod install
cd ..
```
- Download `GoogleService-Info.plist` dari Firebase Console
- Letakkan di `ios/Runner/`
- Buka `ios/Runner.xcworkspace` di Xcode

### 3. Android Setup
- Download `google-services.json` dari Firebase Console
- Letakkan di `android/app/google-services.json`

### 4. Web Setup
- Config sudah ada di `lib/firebase_options.dart`

### 5. Configure Firestore Rules

Buka Firebase Console → Firestore Database → Rules, terapkan:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /study_groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.creatorId == request.auth.uid;
      allow update: if request.auth != null
        && (
          resource.data.creatorId == request.auth.uid
          || request.resource.data.diff(resource.data).affectedKeys().hasOnly(['memberIds'])
        );
      allow delete: if request.auth != null
        && resource.data.creatorId == request.auth.uid;
    }
  }
}
```

Kemudian **Publish** rules.

### 6. iOS Permissions

Edit `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Study Group Finder needs your location to store meetup GPS coordinates.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Study Group Finder needs your location to store meetup GPS coordinates.</string>
```

## ▶️ Running the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome

# Build for production
flutter build ios --release
flutter build apk --release
flutter build web --release
```

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point, Firebase init
├── firebase_options.dart        # Firebase config
├── models/study_group.dart      # Study group data model
├── screens/
│   ├── login.dart              # Authentication
│   ├── home.dart               # Home & group list
│   ├── group_form.dart         # Create/Edit group
│   ├── group_map_screen.dart   # Map display
│   └── pick_location.dart      # Map picker
└── services/
    ├── notification_service.dart    # Local notifications
    └── geolocation_service*.dart    # GPS service (mobile/web)
```

## ⚙️ Konfigurasi Penting

### Map Tiles
- **Provider**: CARTO Basemaps CDN (`basemaps.cartocdn.com`)
- **Reason**: Lebih stabil dibanding OSM publik
- **Attribution**: OpenStreetMap contributors + CARTO

### Notifikasi
- iOS: Alert + Badge + Sound enabled untuk foreground
- Android: High priority dengan sound
- Reminder dijadwalkan 1 menit sebelum meetup

### Geolocation
- iOS/Android: Via `geolocator` package
- Web: Via browser Geolocation API

## 🐛 Troubleshooting

### Notifikasi tidak muncul?
- **iOS**: Settings → Notifications → Study Group Finder → Allow Notifications ON
- **Android**: Settings → Apps → Study Group Finder → Notifications ON
- Rebuild app: `flutter run`

### Join group gagal (permission-denied)?
- Pastikan Firestore Rules sudah dipublish (lihat Setup step #5)
- Rules harus mengizinkan update ke field `memberIds`

### Geolocasi tidak bekerja?
- **iOS**: Settings → Privacy → Location → Study Group Finder → "While Using"
- **Android**: Grant permission di app settings

### Map tidak load tiles?
- Cek koneksi internet
- Verifikasi CARTO CDN accessible (test di browser)

## 📝 Known Limitations

- **Photo Upload**: Dimatikan (memerlukan Firebase Storage billing)
- **Background Location**: GPS tidak track di background (privacy)
- **Web Notifications**: Terbatas support (browser dependent)

## 📞 Contact & Support

- **Email**: [your-email@example.com]
- **GitHub Issues**: [Link to issues]

---

**Last Updated**: April 29, 2026  
**Flutter**: 3.11.4+
