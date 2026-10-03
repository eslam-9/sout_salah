import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/location_repository.dart';

class OpenMapsParams {

  OpenMapsParams({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class OpenMosqueInMapsUseCase implements UseCase<void, OpenMapsParams> {

  OpenMosqueInMapsUseCase(this.repository);
  final LocationRepository repository;

  @override
  Future<Either<Failure, void>> call(OpenMapsParams params) async {
    return await repository.openInGoogleMaps(params.latitude, params.longitude);
  }
}
