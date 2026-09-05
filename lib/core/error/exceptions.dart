class ServerException implements Exception {
  final String? message;
  ServerException([this.message]);
}

class CacheException implements Exception {}

class NetworkException implements Exception {
  final String? message;
  NetworkException([this.message]);
}

class AppAuthException implements Exception {
  final String? message;
  AppAuthException([this.message]);
}

class NotFoundException implements Exception {
  final String? message;
  NotFoundException([this.message]);
}

class ValidationException implements Exception {
  final String? message;
  ValidationException([this.message]);
}

class StorageException implements Exception {
  final String? message;
  StorageException([this.message]);
}

class LocationPermissionDeniedException implements Exception {}
class LocationPermissionPermanentlyDeniedException implements Exception {}
class LocationServiceDisabledException implements Exception {}
class LocationUnavailableException implements Exception {}
class MapLaunchException implements Exception {}

