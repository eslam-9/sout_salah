# Sout Salah

Sout Salah is a comprehensive Flutter application for managing and listening to mosque recordings during Ramadan. It allows users to listen to prayers, follow specific mosques, and for mosque admins/publishers to upload and manage daily recordings.

## Features

- **Mosque Management**: Admins can manage mosque details and publishers.
- **Daily Recordings**: Organized by Ramadan days, users can find recordings for specific prayers (Fajr, Taraweeh, etc.).
- **Audio Player**:
  - Background playback support.
  - Playlist management.
  - Offline listening (Download support).
  - Favorites system.
- **User Roles**:
  - **Listener**: Defaults for all users. Can listen, download, and favorite.
  - **Publisher**: Can upload recordings to assigned mosques.
  - **Admin**: Full control over mosque management.
- **Performance**:
  - Uses Cloudflare R2 for efficient audio storage and delivery.
  - Optimized local caching with Hive/SharedPrefs.
  - Efficient network handling with Dio.

## Tech Stack

- **Frontend**: Flutter
- **Backend/Database**: Supabase (PostgreSQL)
- **Storage**: Cloudflare R2 (S3 compatible) & Supabase Storage
- **State Management**: Riverpod
- **Dependency Injection**: GetIt
- **Routing**: Custom Navigator 2.0 implementation
- **Audio**: `just_audio` + `just_audio_background`

## Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Supabase Account
- Cloudflare R2 Bucket (for audio storage)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/sout_salah.git
    cd sout_salah
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env` file in the root directory (added to `.gitignore` for security):
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    R2_BUCKET_URL=your_r2_bucket_url
    R2_ACCESS_KEY_ID=your_access_key
    R2_SECRET_ACCESS_KEY=your_secret_key
    R2_ACCOUNT_ID=your_account_id
    ```

4.  **Database Setup**
    Run the `schema.sql` file in your Supabase SQL Editor to set up the database tables and policies.

5.  **Run the App**
    ```bash
    flutter run
    ```

## Architecture

The app follows a Clean Architecture approach:
- **Presentation**: UI, Widgets, Riverpod Providers.
- **Domain**: Entities, Use Cases, Repository Interfaces.
- **Data**: Models, Data Sources (Remote/Local), Repository Implementations.

## Contributing

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
