import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';

class LocationService {
  final AppLogger _logger;

  LocationService(this._logger);

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.e('Location services are disabled.');
      throw LocationServiceDisabledException();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final status = await Permission.location.request();
      if (status.isDenied) {
        _logger.e('Location permission denied.');
        throw LocationPermissionDeniedException();
      }
      if (status.isPermanentlyDenied) {
        _logger.e('Location permission permanently denied.');
        throw LocationPermissionPermanentlyDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.e('Location permission permanently denied (Geolocator).');
      throw LocationPermissionPermanentlyDeniedException();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      _logger.e('Failed to get location: $e');
      throw LocationUnavailableException();
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      await setLocaleIdentifier('ar');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressParts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);

        return addressParts.join('، ');
      }
    } catch (e) {
      _logger.e('Reverse geocoding failed: $e');
    }
    return null;
  }
}
