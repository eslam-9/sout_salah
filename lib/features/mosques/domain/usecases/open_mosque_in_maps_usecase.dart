import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/location_repository.dart';

class OpenMapsParams {
  final double latitude;
  final double longitude;

  OpenMapsParams({required this.latitude, required this.longitude});
}

class OpenMosqueInMapsUseCase implements UseCase<void, OpenMapsParams> {
  final LocationRepository repository;

  OpenMosqueInMapsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(OpenMapsParams params) async {
    return await repository.openInGoogleMaps(params.latitude, params.longitude);
  }
}
