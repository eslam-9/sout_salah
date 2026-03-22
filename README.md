<div align="center">

# 🕌 صوت صلاه — Sout Salah

**A comprehensive Islamic mobile app for Quran recitations, mosque recordings, and daily worship.**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.7+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen?logo=android)](https://android.com)

</div>

---

## 📖 About

**Sout Salah (صوت صلاه)** is a Flutter application built to help Muslims engage deeply with their daily worship. It provides a rich library of mosque prayer audio recordings organized by Ramadan days,  offline download support, and background audio playback with notification controls. The app is built around a clean architecture with Riverpod for state management and Supabase as the backend.

---

## ✨ Features

| Feature | Description |
|---|---|
|  **Mosque Recordings** | Browse recordings from mosques, organized by Ramadan day and prayer time |
| 🎧 **Audio Playback** | High-quality audio streaming with play, pause, seek, and progress tracking |
| 🔔 **Background Audio** | Lock screen & notification controls powered by `just_audio_background` |
| 💾 **Offline Downloads** | Download recordings to the device for offline listening, with real-time progress |
| ❤️ **Favorites** | Save and manage favorite recitations, available even when offline |
| 📁 **Local Audio Picker** | Browse and play custom audio files from the device storage |
| 👤 **Auth + Guest Mode** | Supabase authentication with full guest-mode support — no account required |
| 🚀 **Animated Splash** | Lottie-powered animated splash screen displayed on every launch |
| 🌙 **Ramadan Mode** | Day-by-day Ramadan recordings linked to the configured Ramadan start date |
| 📹 **Daily Video** | Mosque admins can upload daily Islamic videos (up to 4K) directly to Cloudflare R2 |
| ☁️ **R2 Cloud Storage** | Admin upload of recordings and videos directly to Cloudflare R2 with progress tracking |
| 🔔 **Push Notifications** | Real-time notifications for new recordings, publishers, and schedule updates via FCM |

---

## 🛠️ Tech Stack

### Core
| Package | Purpose |
|---|---|
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) `^2.6.1` | State management |
| [supabase_flutter](https://pub.dev/packages/supabase_flutter) `^2.12.0` | Auth, database (PostgreSQL) |
| [get_it](https://pub.dev/packages/get_it) `^9.2.0` | Dependency injection / service locator |
| [dartz](https://pub.dev/packages/dartz) `^0.10.1` | Functional programming (Either, Option) |
| [equatable](https://pub.dev/packages/equatable) `^2.0.8` | Value equality for entities |

### Audio
| Package | Purpose |
|---|---|
| [just_audio](https://pub.dev/packages/just_audio) `^0.9.42` | Advanced audio playback engine |
| [just_audio_background](https://pub.dev/packages/just_audio_background) `^0.0.1-beta.17` | Background playback + notification controls |
| [audio_session](https://pub.dev/packages/audio_session) `^0.1.21` | System audio session management |
| [on_audio_query](https://pub.dev/packages/on_audio_query) `^2.9.0` | Query local audio files from device |

### Networking & Storage
| Package | Purpose |
|---|---|
| [dio](https://pub.dev/packages/dio) `^5.9.1` | HTTP client for API calls and file downloads |
| [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.2.2` | Lightweight local key-value persistence |
| [path_provider](https://pub.dev/packages/path_provider) `^2.1.2` | Access device file system directories |
| [crypto](https://pub.dev/packages/crypto) `^3.0.3` | HMAC-SHA256 signing for R2 uploads |

### UI & Media
| Package | Purpose |
|---|---|
| [lottie](https://pub.dev/packages/lottie) `^3.1.0` | JSON-based vector animations (splash screen) |
| [google_fonts](https://pub.dev/packages/google_fonts) `^8.0.1` | Custom typography |
| [lucide_icons](https://pub.dev/packages/lucide_icons) `^0.257.0` | Modern, consistent icon set |
| [permission_handler](https://pub.dev/packages/permission_handler) `^12.0.1` | Runtime permissions for storage/audio |
| [video_player](https://pub.dev/packages/video_player) `^2.11.1` | Hardware-accelerated video playback |
| [chewie](https://pub.dev/packages/chewie) `^1.8.5` | Specialized UI controls for video playback |

### Firebase & Notifications
| Package | Purpose |
|---|---|
| [firebase_messaging](https://pub.dev/packages/firebase_messaging) `^16.1.2` | Cloud-based push notifications (FCM) |
| [firebase_core](https://pub.dev/packages/firebase_core) `^4.5.0` | Core Firebase project configuration |

---

## 🏗️ Architecture

Sout Salah follows **Clean Architecture**, separating responsibilities into three distinct layers:

```
Presentation  ──>  Domain  ──>  Data
  (UI, State)      (Entities,   (Repositories,
                   Use Cases)    Remote Sources)
```

- **`core/`** — App-wide shared infrastructure: services, routing, theming, DI, utilities.
- **`features/`** — Self-contained feature modules, each with `data/`, `domain/`, and `presentation/` layers.

---

## 📁 Project Structure

```text
lib/
├── main.dart                          # App entry point, Supabase & DI init
│
├── core/
│   ├── config/
│   │   └── app_config.dart            # Compile-time env variables (--dart-define-from-file)
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants (e.g. Ramadan start date)
│   ├── di/
│   │   ├── injection_container.dart   # GetIt service locator setup
│   │   └── providers.dart             # Riverpod providers for core services
│   ├── error/
│   │   ├── exceptions.dart            # Custom app exceptions
│   │   └── failures.dart              # Failure types for Either return values
│   ├── models/
│   │   ├── downloaded_recording.dart  # Model for locally downloaded recordings
│   │   └── favorite_recording.dart   # Model for favorited recordings
│   ├── presentation/
│   │   └── pages/
│   │       ├── splash_screen.dart     # Animated Lottie splash screen
│   │       └── error_page.dart        # Generic error display page
│   ├── routes/
│   │   ├── app_router.dart            # Route generation logic
│   │   ├── app_routes.dart            # Route name constants
│   │   ├── route_args.dart            # Typed route argument classes
│   │   └── route_transitions.dart     # Custom page transition animations
│   ├── services/
│   │   ├── audio_player_service.dart  # JustAudio wrapper: play/pause/seek/streams
│   │   ├── downloads_service.dart     # Offline download manager with progress streams
│   │   ├── favorites_service.dart     # Local favorites with reactive stream updates
│   │   ├── navigation_service.dart    # Context-free programmatic navigation
│   │   ├── r2_storage_service.dart    # Cloudflare R2 S3-compatible file upload/delete
│   │   └── startup_service.dart       # Fetches startup data (notices/links) from Supabase
│   ├── theme/
│   │   └── app_theme.dart             # Material theme configuration
│   ├── usecases/
│   │   └── usecase.dart               # Base UseCase abstract class
│   ├── utils/
│   │   ├── app_logger.dart            # Structured logger
│   │   ├── mosque_permissions.dart    # Mosque-specific permission logic
│   │   └── permission_checker.dart    # Generic runtime permission checker
│   ├── validators/
│   │   └── validators.dart            # Input field validators (login, upload, etc.)
│   └── widgets/
│       └── startup_check_wrapper.dart # Wraps app to intercept startup data at launch
│
└── features/
    ├── auth/                          # Authentication feature
    │   ├── data/
    │   │   ├── datasources/auth_remote_data_source.dart
    │   │   ├── models/profile_model.dart, user_model.dart
    │   │   └── repositories/auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/profile.dart, user.dart
    │   │   ├── repositories/auth_repository.dart
    │   │   └── usecases/auth_usecases.dart, sign_up_usecase.dart ...
    │   └── presentation/
    │       ├── bloc/auth_state.dart
    │       ├── pages/login_page.dart, sign_up_page.dart, profile_page.dart
    │       ├── providers/auth_controller.dart, auth_data_providers.dart
    │       └── widgets/login_form.dart, custom_button.dart ...
    │
    ├── home/                          # Main shell (tabs: Mosques, Downloads, Saved, Settings)
    │   └── presentation/
    │       ├── pages/home_layout.dart, mosques_page.dart, downloads_page.dart ...
    │       ├── providers/downloads_provider.dart, favorites_provider.dart
    │       └── widgets/home_widgets.dart, favorite_audio_player_sheet.dart
    │
    ├── mosques/                       # Mosque & recording management feature
    │   ├── data/
    │   │   ├── datasources/mosque_remote_data_source.dart
    │   │   ├── models/mosque_model.dart, recording_model.dart, daily_video_model.dart ...
    │   │   └── repositories/mosque_repository_impl.dart, video_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/mosque.dart, recording.dart, daily_video.dart, ramadan_day.dart ...
    │   │   ├── repositories/mosque_repository.dart, video_repository.dart
    │   │   └── usecases/get_mosques_usecase.dart, upload_daily_video_usecase.dart ...
    │   └── presentation/
    │       ├── pages/mosque_detail_page.dart, daily_video_page.dart, upload_daily_video_page.dart ...
    │       ├── providers/mosque_controller.dart, video_controller.dart ...
    │       └── widgets/mosque_card.dart, daily_video_widget.dart, audio_player_sheet.dart
    │
    └── shared/
        └── widgets/
            ├── audio_player_widget.dart   # Reusable inline audio player widget
            └── base_audio_sheet.dart      # Base bottom sheet for audio playback UI
```

---

## 🔑 Core Services

| Service | Responsibility |
|---|---|
| `AudioPlayerService` | Wraps `JustAudio` to stream audio from URL with background media metadata (`MediaItem`) |
| `DownloadsService` | Downloads recordings via `Dio`, tracks per-file progress streams, persists metadata locally |
| `FavoritesService` | Persists favorite recordings to `SharedPreferences` and broadcasts changes as a `Stream` |
| `NavigationService` | Provides a global `NavigatorKey` for context-free, type-safe navigation from providers |
| `R2StorageService` | Uploads/deletes audio files and videos on Cloudflare R2 using AWS4 request signing |
| `StartupService` | Queries Supabase `data` table at launch for dynamic messages or redirect links |
| `FCMNotificationService` | Handles Firebase Cloud Messaging token registration and background message handling |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.10.7`
- Android Studio or VS Code with Flutter plugin
- A [Supabase](https://supabase.com) project
- A [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) bucket (for admin audio uploads)

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/sout_salah.git
cd sout_salah
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create `env.json` at the root of the project. **Do not commit this file** (it is gitignored).

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "R2_ENDPOINT": "https://your-account.r2.cloudflarestorage.com",
  "R2_ACCESS_KEY": "your-r2-access-key",
  "R2_SECRET_KEY": "your-r2-secret-key",
  "R2_BUCKET": "your-bucket-name",
  "R2_CDN_URL": "https://your-cdn.r2.dev"
}
```

### 4. Run the app

```bash
flutter run --dart-define-from-file=env.json
```

### 5. Build a release APK / AAB

```bash
# Release APK
flutter build apk --release --dart-define-from-file=env.json

# Google Play bundle
flutter build appbundle --release --dart-define-from-file=env.json
```

---

## 🔒 Security

- All credentials are injected at **compile time** via `--dart-define-from-file`. No secrets are bundled in the APK assets or source code.
- `env.json` is added to `.gitignore`.
- Guest mode stores state only in local `SharedPreferences` — no user data is sent to the backend.
- R2 API calls use **AWS Signature Version 4 (HMAC-SHA256)** for request signing.

---

## 🗃️ Database (Supabase)

Key tables used:

| Table | Purpose |
|---|---|
| `profiles` | User profile data linked to auth |
| `mosques` | Mosque information (name, location, publisher) |
| `recordings` | Audio recording metadata (URL, prayer, mosque, day) |
| `daily_videos` | Video metadata (URL, title, description, day, mosque) |
| `ramadan_days` | Ramadan day records linked to a mosque |
| `fcm_tokens` | Stores Firebase Cloud Messaging tokens for push notifications |
| `data` | Startup notices / redirect links shown at launch |

> **Note:** The `prayer_name` column in `recordings` supports custom values (e.g. `Tahajjud`) in addition to standard prayer names.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ for the Muslim community · Built with Flutter 🐦

</div>
