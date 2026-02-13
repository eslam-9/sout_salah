/// Centralized route definitions for the application
class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';

  // Home routes
  static const String home = '/';
  static const String profile = '/profile';
  static const String downloads = '/downloads';
  static const String savedRecordings = '/saved-recordings';
  static const String settings = '/settings';

  // Mosque routes
  static const String mosqueDetail = '/mosque-detail';
  static const String dayDetail = '/day-detail';
  static const String uploadRecording = '/upload-recording';
  static const String addMosque = '/add-mosque';
  static const String deviceAudioSelection = '/device-audio-selection';
  static const String audioPlayer = '/audio-player';

  // List of routes that require authentication
  static const List<String> authRequiredRoutes = [
    profile,
    addMosque,
    uploadRecording,
  ];

  // List of routes that should be accessible to guests
  static const List<String> guestAccessibleRoutes = [
    home,
    mosqueDetail,
    dayDetail,
    downloads,
    savedRecordings,
    settings,
    deviceAudioSelection,
  ];
}
