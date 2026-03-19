class AppConstants {
  // Start date of Ramadan 1447 (2026)
  // Note: Adjust this date based on moon sighting
  static final DateTime ramadanStartDate = DateTime(2026, 2, 18);
}

class NetworkConfig {
  /// Strict global default timeout (10 seconds) for standard API/JSON calls [SC-002]
  static const Duration standardTimeout = Duration(seconds: 10);

  /// Extended timeout (120 seconds) for large media uploads and downloads [FR-001, FR-002]
  static const Duration audioTimeout = Duration(seconds: 120);
}
