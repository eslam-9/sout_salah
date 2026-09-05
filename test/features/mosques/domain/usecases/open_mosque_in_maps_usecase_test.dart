import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/features/mosques/domain/usecases/open_mosque_in_maps_usecase.dart';
import 'package:sout_salah/features/mosques/domain/repositories/location_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:sout_salah/core/error/failures.dart';

import 'package:sout_salah/features/mosques/domain/entities/mosque_location.dart';

class MockLocationRepository implements LocationRepository {
  bool willFail = false;
  
  @override
  Future<Either<Failure, void>> openInGoogleMaps(double latitude, double longitude) async {
    if (willFail) {
      return Left(ServerFailure(message: 'Failed to open maps'));
    }
    return const Right(null);
  }
  
  @override
  Future<Either<Failure, MosqueLocation>> getCurrentLocation() async {
    return const Right(MosqueLocation(latitude: 30, longitude: 30, locationName: 'Mock'));
  }
}

void main() {
  late OpenMosqueInMapsUseCase useCase;
  late MockLocationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocationRepository();
    useCase = OpenMosqueInMapsUseCase(mockRepository);
  });

  final params = OpenMapsParams(latitude: 30.0, longitude: 31.0);

  test('should return Right(null) when opening maps is successful', () async {
    final result = await useCase(params);

    expect(result, const Right(null));
  });

  test('should return Left(Failure) when opening maps fails', () async {
    mockRepository.willFail = true;
    final result = await useCase(params);

    expect(result.isLeft(), isTrue);
  });
}
