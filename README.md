# StudyLink AI — Study Group Finder

Aplikasi mobile Flutter untuk menemukan, membuat, dan bergabung dengan study group. Dilengkapi fitur **Edge AI OCR Scanner** untuk memindai catatan kuliah dan mendapatkan rekomendasi grup yang relevan secara otomatis.

---

## ✨ Fitur Utama

### 🔐 Autentikasi & Akun
- Login / Register dengan email dan password via **Firebase Authentication**
- Profil pengguna tersimpan di **Firestore** (`users/{uid}`)
- Session management & logout

### 🏠 Home
- Greeting personal berdasarkan nama pengguna dari Firebase
- Daftar grup yang direkomendasikan (horizontal scroll)
- Daftar grup "Happening Nearby" berdasarkan GPS
- Tombol FAB untuk membuat grup baru

### 🔍 Discovery
- Pencarian grup berdasarkan nama, deskripsi, atau tag
- Filter horizontal chip: **All Groups, CS 101, Mathematics, Physics, Engineering, Biology**
- Tombol **Join / Leave** group yang tersinkron ke Firestore secara real-time

### 📷 OCR Scanner (Edge AI)
- Pindai catatan kuliah menggunakan kamera atau galeri
- **On-device AI** via Google ML Kit Text Recognition — tanpa koneksi internet
- Ekstraksi **keyword akademik** otomatis
- **Rekomendasi grup** berdasarkan topik yang terdeteksi
- Animasi scanning overlay dengan corner brackets & scan line
> ⚠️ Fitur OCR hanya tersedia di **Android & iOS** (tidak didukung di Web)

### 🤖 AI Recommendations
- Kartu rekomendasi grup dengan **match percentage**
- AI Insight card menjelaskan alasan kecocokan
- Navigasi langsung dari Scan Results → AI Recommendations

### 🔔 Alerts
- Notifikasi tersimpan di Firestore (`users/{uid}/notifications`)
- Tombol **"Mark all as read"** dengan Firestore batch update
- Empty state saat tidak ada notifikasi

### 👤 Profile
- Data profil dinamis dari Firestore (nama, universitas, jurusan)
- **My Joined Groups** — daftar grup yang benar-benar diikuti (bukan dummy)
- Empty state jika belum bergabung grup manapun
- **Study Preferences** (Session Alerts, Profile Visibility, AI Matchmaking) tersinkron ke Firestore
- Logout dengan konfirmasi

### ⚙️ Settings
- Edit profil (nama, universitas, jurusan)
- Toggle notifikasi & AI matchmaking (tersimpan ke Firestore)
- About & Help section
- Logout dengan dialog konfirmasi

### 🗺️ Lokasi & Map
- **GPS**: Ambil koordinat lokasi dari device
- **Map Picker**: Pilih lokasi di peta interaktif (flutter_map + CARTO)
- **Map View**: Lihat lokasi grup di peta

### 🤝 AI Study Assistant
- Chat bot berbasis AI untuk membantu belajar
- Tersedia dari menu Profile

---

## 🛠️ Tech Stack

### Frontend
| Technology | Versi | Kegunaan |
|-----------|-------|---------|
| Flutter | 3.11+ | Framework multi-platform |
| Material Design 3 | — | UI components |
| Google Fonts (Inter) | ^6.2.1 | Tipografi |

### Backend & Data
| Technology | Kegunaan |
|-----------|---------|
| Firebase Authentication | Login/Register |
| Cloud Firestore | Database utama (users, groups, notifications) |
| Firebase Cloud Messaging | Push notifications |
| Firebase Storage | File upload (optional) |

### State Management
| Package | Versi | Kegunaan |
|--------|-------|---------|
| provider | ^6.1.2 | AuthProvider, UserProvider |

### AI & Machine Learning
| Package | Versi | Kegunaan |
|--------|-------|---------|
| google_mlkit_text_recognition | ^0.15.1 | On-device OCR (Android/iOS) |

### Key Packages
```yaml
flutter_map: ^8.3.0              # Peta interaktif
flutter_local_notifications: ^21.0.0  # Local notifications
geolocator: ^14.0.2             # GPS geolocation
image_picker: ^1.1.2            # Kamera & galeri
cached_network_image: ^3.4.1    # Cache gambar
shared_preferences: ^2.3.3      # Penyimpanan lokal
```

### Platform Support
- **Android** 5.0+ (API 21+)
- **iOS** 12.0+
- **Web** — Chrome, Firefox, Safari *(OCR tidak tersedia di Web)*

---

## 📋 Prerequisites

- **Flutter SDK** 3.11.4+ → [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Firebase Project** → [Firebase Console](https://console.firebase.google.com)
  - Enable: **Authentication**, **Firestore Database**, **Cloud Messaging**
- **Xcode** (untuk build iOS)
- **Android Studio** (untuk build Android)

---

## 🚀 Setup & Installation

### 1. Clone & Install Dependencies
```bash
git clone <repository-url>
cd study_group_finder
flutter pub get
```

### 2. iOS Setup
```bash
cd ios && pod install && cd ..
```
- Download `GoogleService-Info.plist` dari Firebase Console
- Letakkan di `ios/Runner/`

### 3. Android Setup
- Download `google-services.json` dari Firebase Console
- Letakkan di `android/app/`

### 4. Web Setup
- Konfigurasi sudah ada di `lib/firebase_options.dart`

### 5. Firestore Security Rules

Buka Firebase Console → Firestore → Rules, terapkan rules berikut lalu **Publish**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users — hanya bisa baca/edit dokumen sendiri
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      // Notifications subcollection
      match /notifications/{notifId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }

    // Study Groups
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

### 6. iOS Permissions (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>StudyLink AI perlu lokasi untuk menyimpan koordinat tempat belajar.</string>
<key>NSCameraUsageDescription</key>
<string>StudyLink AI perlu kamera untuk memindai catatan kuliah.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>StudyLink AI perlu akses galeri untuk memilih foto catatan.</string>
```

---

## ▶️ Menjalankan Aplikasi

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (OCR tidak tersedia)
flutter run -d chrome

# Build production
flutter build apk --release
flutter build ios --release
flutter build web --release
```

> **Note**: Jika `flutter` tidak ditemukan, gunakan path lengkap:
> ```bash
> /path/to/flutter/bin/flutter run
> ```

---

## 📁 Struktur Project

```
lib/
├── main.dart                        # Entry point, Firebase init, MultiProvider
├── firebase_options.dart            # Firebase config
│
├── core/
│   └── theme/
│       ├── app_colors.dart          # Design tokens (warna)
│       ├── app_text_styles.dart     # Typography system (Inter)
│       └── app_theme.dart           # Material 3 theme
│
├── models/
│   ├── app_user.dart               # User model + UserPreferences
│   ├── study_group.dart            # Study group model
│   └── scan_result.dart            # OCR scan result model
│
├── providers/
│   ├── auth_provider.dart          # Firebase Auth state
│   └── user_provider.dart          # User profile + joined groups state
│
├── services/
│   ├── user_service.dart           # Firestore CRUD untuk user
│   ├── group_service.dart          # Join/leave group (atomic)
│   ├── ocr_service.dart            # ML Kit OCR (Android/iOS)
│   ├── keyword_extractor.dart      # Ekstraksi keyword akademik
│   ├── recommendation_service.dart # Algoritma rekomendasi grup
│   ├── notification_service.dart   # Local notifications
│   └── geolocation_service.dart    # GPS service
│
├── screens/
│   ├── splash_screen.dart          # Splash dengan animasi
│   ├── login.dart                  # Login screen
│   ├── register.dart               # Register screen
│   ├── main_shell.dart             # 5-tab navigation shell
│   ├── home.dart                   # Home screen
│   ├── discovery_screen.dart       # Discovery + filter chips
│   ├── scanner_screen.dart         # OCR Scanner (4 states)
│   ├── scan_results_screen.dart    # Hasil scan + keyword chips
│   ├── ai_recommendations_screen.dart  # Rekomendasi grup AI
│   ├── alerts_screen.dart          # Notifikasi dari Firestore
│   ├── profile_screen.dart         # Profil + joined groups dinamis
│   ├── settings_screen.dart        # Settings + edit profil
│   ├── group_form.dart             # Buat/edit grup
│   ├── group_map_screen.dart       # Peta lokasi grup
│   ├── pick_location.dart          # Map picker
│   └── assistant_screen.dart       # AI Study Assistant chat
│
└── widgets/
    ├── app_header.dart             # Header dengan logo + settings icon
    ├── empty_state.dart            # Reusable empty state
    ├── study_group_card.dart       # Kartu grup (horizontal)
    ├── group_list_card.dart        # Kartu grup (vertikal, Discovery)
    ├── ai_recommendation_card.dart # Kartu rekomendasi AI
    ├── ai_tag_chip.dart            # Chip tag AI/keyword
    ├── nearby_group_tile.dart      # Tile grup terdekat
    ├── notification_card.dart      # Kartu notifikasi
    ├── scanning_overlay.dart       # Overlay animasi scanner
    └── section_header.dart         # Header section dengan aksi
```

---

## 🗄️ Firestore Schema

```
users/{uid}
├── name: string
├── email: string
├── university: string?
├── major: string?
├── photoUrl: string?
├── joinedGroups: string[]        ← list group ID yang diikuti
├── preferences: {
│     sessionAlerts: bool,
│     profileVisibility: bool,
│     aiMatchmaking: bool
│   }
├── createdAt: timestamp
└── notifications/ (subcollection)
    └── {notifId}
        ├── title: string
        ├── subtitle: string
        ├── type: string           ← "study_session" | "member_joined" | "ai_generated" | "file_upload"
        ├── isUnread: bool
        ├── actionLabel: string?
        └── createdAt: timestamp

study_groups/{groupId}
├── subjectName: string
├── description: string
├── location: string
├── scheduledAt: timestamp
├── creatorId: string             ← uid pembuat
├── memberIds: string[]           ← list uid anggota
├── tags: string[]
├── course: string?
├── university: string?
├── major: string?
├── latitude: number?
├── longitude: number?
└── imageUrl: string?
```

---

## 🔄 Alur Data

```
Register → createUserDocument (Firestore users/{uid})
Login    → ensureUserDocument → UserProvider.listenToUser()
                                       ↓ real-time stream
                          Profile, Preferences, Joined Groups

Discovery (Join Group) → GroupService.joinGroup()
                              ↓ atomic update
                  group.memberIds ← [uid]    +    user.joinedGroups ← [groupId]

Scanner → ML Kit OCR → KeywordExtractor → RecommendationService
                                                    ↓
                                          AI Recommendations Screen
```

---

## 🐛 Troubleshooting

### OCR tidak berfungsi?
- Fitur OCR hanya tersedia di **Android & iOS**
- Di Web akan muncul pesan: *"OCR scanning requires a mobile device"*

### Join group gagal (permission-denied)?
- Pastikan Firestore Rules sudah di-publish (lihat step #5)
- Rules harus mengizinkan update ke field `memberIds`

### My Joined Groups kosong padahal sudah join?
- Pastikan dokumen `users/{uid}` ada di Firestore
- Pengguna lama (sebelum update) perlu login ulang agar dokumen dibuat otomatis

### Notifikasi tidak muncul?
- **iOS**: Settings → Notifications → StudyLink AI → Allow Notifications ON
- **Android**: Settings → Apps → StudyLink AI → Notifications ON

### Peta tidak load?
- Cek koneksi internet (CARTO CDN)

### `flutter: command not found`?
- Gunakan path lengkap: `/path/to/flutter/bin/flutter run`
- Atau tambahkan Flutter ke PATH di `~/.zshrc`

---

## 📝 Known Limitations

- **OCR**: Hanya Android & iOS — tidak tersedia di Web (Google ML Kit limitation)
- **Background Location**: GPS tidak di-track di background (kebijakan privasi)
- **Web Notifications**: Terbatas dukungan browser
- **Photo Upload**: Memerlukan Firebase Storage billing

---

**Last Updated**: May 13, 2026
**Flutter**: 3.11.4+
**Version**: 1.0.0
