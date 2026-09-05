import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/mosque_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../services/location_service.dart';
import '../services/maps_navigation_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationService locationService;
  final MapsNavigationService mapsNavigationService;

  LocationRepositoryImpl(this.locationService, this.mapsNavigationService);

  @override
  Future<Either<Failure, MosqueLocation>> getCurrentLocation() async {
    return executeWithCatch(() async {
      final position = await locationService.getCurrentPosition();
      final address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return MosqueLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: address,
      );
    });
  }

  @override
  Future<Either<Failure, void>> openInGoogleMaps(double latitude, double longitude) async {
    return executeWithCatch(() async {
      await mapsNavigationService.openGoogleMaps(latitude, longitude);
    });
  }
}
