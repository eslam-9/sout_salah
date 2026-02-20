# Sout Salah - Technical Documentation

## 1. Project Overview & Features
**Sout Salah** is a comprehensive Flutter-based mobile application designed to manage and listen to mosque prayer recordings and read the Holy Quran. 
It connects users with mosques, allowing them to follow prayer times, listen to daily prayer recordings (Fajr, Maghrib, Isha, Taraweeh), manage mosque details, and features a locally synced and beautifully laid out Mushaf.

### Key Features
*   **Audio Playback**: Background audio with notification controls, support for online recordings, and a custom picker for local device audio.
*   **Holy Quran (Mushaf)**: A pixel-perfect implementation of the Quran (pages 1-604) utilizing CDN images, custom app bars/footers to maximize screen space, and page caching.
*   **Mosque Management**: Browse, detail view, creation, and role-based management of mosques and their recordings.
*   **Offline / Downloads Strategy**: Users can favorite and download recordings (via R2/Supabase) to their device, playable without an internet connection.

---

## 2. Technical Architecture

The project follows a **Feature-First / Clean Architecture** pattern ensuring separation of concerns:

*   **`core/`**: Shared infrastructure.
    *   `di/`: Dependency Injection using `get_it`.
    *   `routes/`: Centralized routing (`AppRouter`) using Flutter's native Navigator with custom slide/fade transitions and route guards.
    *   `services/`: Singleton core services (`DownloadsService`, `FavoritesService`, `AudioPlayerService`).
*   **`features/`**: Independent, decoupled domains (e.g., `auth/`, `home/`, `mosques/`, `quran/`).
    *   Each feature contains its own `data/` (Models, Repositories), `domain/` (Entities), and `presentation/` (Pages, Widgets, Providers).

### State Management & Dependency Injection
*   **State Management**: `flutter_riverpod` (v2.x) handles robust reactive state across the application, separating business logic from UI.
*   **Dependency Injection**: `get_it` is used to register singletons (e.g., `AppLogger`, Services, Supabase Client) making them available globally without context.

---

## 3. Environment & Configuration

To prevent exposing sensitive API keys and handle environments securely, the app uses a compile-time configuration strategy, completely removing `flutter_dotenv`.

### Build Configuration (`env.json`)
The application defines environment variables at compile time using `env.json` (which is `.gitignore`d). 
A custom Dart class (`AppConfig`) reads these variables securely via `String.fromEnvironment`.

**Setup:**
1. Create `env.json` at the project root:
   ```json
   {
     "SUPABASE_URL": "your_supabase_url",
     "SUPABASE_ANON_KEY": "your_supabase_anon_key"
   }
   ```
2. Build or Run the app using:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

---

## 4. Authentication & Roles

The app utilizes **Supabase Auth** paired with a custom implementation for Guest users.

### True Guest Mode
Bypasses Supabase Auth logic to provide immediate access for non-registered users.
*   **State**: The `AuthNotifier` explicitly emits an `AuthGuest` state.
*   **Persistence**: Handled locally via `SharedPreferences` (`is_guest_mode`), guaranteeing the user stays as a guest across app restarts.

### Roles & Permissions (`PERMISSIONS.md`)
*   **Guest**: Can view content but cannot interact with authenticated features.
*   **Normal User**: Authenticated users who can create mosques and favorite/download.
*   **Publisher**: Can upload audio to specifically assigned mosques.
*   **Admin**: Full control over a mosque, its details, publishers, and recordings.

### Routing Auth Guard (`AppRouter`)
The `AppRouter.onGenerateRoute` explicitly checks if a user `_isAuthenticated()` or `_isGuest()` before allowing navigation to protected routes (like `AppRoutes.home`), otherwise immediately redirecting to the `LoginPage`.

---

## 5. Core Services Details

### Audio Service (`just_audio` & `just_audio_background`)
Responsible for seamless playback and background integration.
*   **Metadata (`MediaItem`)**: The service maps recordings to `MediaItem`s so the OS lock screen and notification shade display the Surah name, artist (reciter), and artwork.
*   **Local Audio**: Uses `on_audio_query` and `file_picker` to fetch and select audio files directly from the device's internal storage.

### Data & Storage (Supabase & R2)
*   **Database**: PostgreSQL hosted on Supabase containing tables for `mosques`, `profiles`, `recordings`, and `mosque_publishers`.
*   **File Storage**: `R2StorageService` manages files. It communicates with S3-compatible endpoints for downloading/uploading recordings. Database triggers manage related metadata.

---

## 6. Quran Mushaf Feature

Implemented as a highly optimized, scrollable/pannable image viewer.

*   **CDN Integration**: Pages are dynamically loaded from a CDN URL representing pages 1 to 604 securely and consistently.
*   **Custom Framework**: To maximize reading space, the standard `AppBar` and `BottomNavigationBar` are completely hidden. Instead, custom overlaid widgets exist at the top and bottom for displaying Surah details, page numbers, and navigation arrows.
*   **Amiri Font**: Embedded locally to ensure accurate Arabic typographic styling for headers and footers outside the main images.

---

## 7. Package Dependencies Summary

| Package | Purpose |
| :--- | :--- |
| **flutter_riverpod** | Reactive State Management. |
| **supabase_flutter** | Authentication and Database operations. |
| **just_audio** / **_background** | Audio playback, queues, and background notification controls. |
| **file_picker** / **on_audio_query** | Android storage access for local audio. |
| **shared_preferences** | Local persistent settings (Guest Mode, Onboarding). |
| **get_it** | Dependency Injection container. |
| **dio** / **url_launcher** | HTTP requests and opening external URLs. |
