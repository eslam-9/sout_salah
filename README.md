# Sout Salah (صوت صلاح)

Sout Salah is a comprehensive mobile application for managing and listening to mosque prayer recordings. It helps users connect with their local mosques, follow prayer times, and access a rich library of daily prayer audio.

## 📚 Documentation

Detailed documentation for the project can be found in the following files:

*   **[Application Documentation](docs/APP_DOCUMENTATION.md)**: Overview of features, architecture, packages, and technical details.
*   **[Permissions & Roles](PERMISSIONS.md)**: Explanation of the user roles (Guest, Admin, Publisher) and their access rights.
*   **[Storage Setup](STORAGE_SETUP.md)**: Guide for configuring Supabase Storage for audio recordings.

## 🚀 Quick Start

1.  **Clone the repository**.
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Configure Environment**:
    Create a `.env` file in the root directory with your Supabase credentials:
    ```env
    SUPABASE_URL=your_url
    SUPABASE_ANON_KEY=your_key
    ```
4.  **Run the App**:
    ```bash
    flutter run
    ```

## 🌟 Key Features

*   **Background Audio Playback**: Listen to prayers even when the app is closed.
*   **Offline Mode**: Download recordings for offline listening.
*   **Multi-Role System**: Dedicated interfaces for Mosque Admins and Publishers.
*   **Favorites**: Save your favorite recitations.
*   **Ramadan Calendar**: Organized daily recordings for the holy month.

## 📦 Tech Stack

Built with **Flutter**, using **Riverpod** for state management and **Supabase** for the backend.
