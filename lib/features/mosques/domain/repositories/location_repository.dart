import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque_location.dart';

abstract class LocationRepository {
  Future<Either<Failure, MosqueLocation>> getCurrentLocation();
  Future<Either<Failure, void>> openInGoogleMaps(double latitude, double longitude);
}
