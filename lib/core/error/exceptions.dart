class ServerException implements Exception {
  ServerException([this.message, this.statusCode]);
  final String? message;
  final int? statusCode;
}

class CacheException implements Exception {}

class NetworkException implements Exception {
  NetworkException([this.message]);
  final String? message;
}

class AppAuthException implements Exception {
  AppAuthException([this.message]);
  final String? message;
}

class NotFoundException implements Exception {
  NotFoundException([this.message]);
  final String? message;
}

class ValidationException implements Exception {
  ValidationException([this.message]);
  final String? message;
}

class StorageException implements Exception {
  StorageException([this.message]);
  final String? message;
}

// NEW: typed exception for when a user lookup fails
class UserNotFoundException implements Exception {
  UserNotFoundException(this.email);
  final String email;
}

// NEW: typed exception for audio playback failures
class AudioPlaybackException implements Exception {
  AudioPlaybackException([this.message, this.cause]);
  final String? message;
  final Object? cause;
}

class LocationPermissionDeniedException implements Exception {}
class LocationPermissionPermanentlyDeniedException implements Exception {}
class LocationServiceDisabledException implements Exception {}
class LocationUnavailableException implements Exception {}
class MapLaunchException implements Exception {}
