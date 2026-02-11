# Sout Salah - Application Documentation

## 1. Project Overview
**Sout Salah** is a Flutter-based mobile application designed to manage and listen to mosque prayer recordings. It connects users with mosques, allowing them to follow prayer times, listen to daily prayer recordings (Fajr, Maghrib, Isha, Taraweeh), and manage mosque details.

The app supports multiple user roles (Guest, Normal User, Publisher, Admin) with granular permissions for managing content. It leverages **Supabase** for backend services (Database, Auth, Storage) and **Riverpod** for robust state management.

---

## 2. Features & Capabilities

### 🕌 Mosque Management
*   **Browse Mosques**: Users can view a list of registered mosques.
*   **Mosque Details**: View detailed information about a mosque, including location and description.
*   **Create Mosque**: Users can register new mosques (automatically becoming the Admin).
*   **Role Management**: Admins can assign Publishers to help manage recordings.

### 🎧 Audio Playback & Recordings
*   **Daily Recordings**: Organized by Ramadan days and prayer times (Fajr, Maghrib, Isha, Taraweeh).
*   **Background Playback**: Audio continues playing when the app is in the background, with notification controls (Play/Pause/Stop).
*   **Device Audio**: Option to select and play audio files from the local device.
*   **Upload Recordings**: Publishers and Admins can upload prayer recordings directly from their device.

### 👤 User Roles (See `PERMISSIONS.md` for details)
*   **Guest**: View-only access to mosques and recordings.
*   **Normal User**: Can view content and create new mosques.
*   **Publisher**: Can upload recordings to assigned mosques.
*   **Admin**: Full control over their created mosque (Edit details, Manage publishers, Delete recordings).

---

## 3. Technical Architecture

### Tech Stack
*   **Framework**: Flutter (Dart)
*   **State Management**: `flutter_riverpod` (2.x)
*   **Backend**: Supabase (PostgreSQL, Auth, Storage)
*   **Audio Engine**: `just_audio` + `just_audio_background`

### Project Structure (`lib/`)
The project follows a **Feature-First / Clean Architecture** approach:

*   **`core/`**: Shared utilities and infrastructure.
    *   `di/`: Dependency Injection setup.
    *   `routes/`: Application routing configuration (`AppRouter`).
    *   `services/`: Core services (Downloads, Favorites).
    *   `theme/`: App styling and theme definitions.
    *   `error/`: Error handling logic.
*   **`features/`**: Independent feature modules.
    *   **`auth/`**: Authentication logic (Login, Signup) using Supabase Auth.
    *   **`home/`**: Main dashboard and layout.
    *   **`mosques/`**: Core business logic.
        *   `data/`: Models and Repositories (API calls).
        *   `domain/`: Entities and Use Cases (Business rules).
        *   `presentation/`: Widgets and Pages (UI).

---

## 4. Key Packages & Dependencies

| Package | Purpose |
| :--- | :--- |
| **flutter_riverpod** | State management and dependency injection. |
| **supabase_flutter** | Interface for Supabase Authentication and Database. |
| **just_audio** | Feature-rich audio player. |
| **just_audio_background** | Background audio support and notification controls. |
| **go_router** / **Navigator** | Navigation management (Standard Navigator used currently). |
| **file_picker** | Selecting audio files from device storage. |
| **on_audio_query** | Querying audio files stored on the Android device. |
| **shared_preferences** | Local checks (e.g., onboarding status, simple settings). |
| **permission_handler** | Requesting storage and notification permissions. |
| **flutter_dotenv** | Managing environment variables (API Keys). |

---

## 5. Setup & Installation

### Prerequisites
*   Flutter SDK (v3.10.7 or compatible)
*   Supabase Project (URL and Anon Key)

### Environment Configuration
1.  Create a `.env` file in the root directory.
2.  Add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```
3.  Ensure `.env` is added to `assets` in `pubspec.yaml` (Already configured).

### Android Configuration
*   **Permissions**: The app requires `INTERNET`, `READ_MEDIA_AUDIO` (or `READ_EXTERNAL_STORAGE` for older Android), and `POST_NOTIFICATIONS`.
*   **Background Audio**: Configured in `AndroidManifest.xml` with `service` and `receiver` tags for `just_audio_background`.

### Running the App
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 6. Additional Documentation
*   [PERMISSIONS.md](../PERMISSIONS.md): Detailed matrix of user roles and access rights.
*   [STORAGE_SETUP.md](../STORAGE_SETUP.md): Guide on Supabase Storage bucket configuration and policies.
