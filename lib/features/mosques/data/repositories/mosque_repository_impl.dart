import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../datasources/mosque_remote_data_source.dart';

class MosqueRepositoryImpl implements MosqueRepository {
  final MosqueRemoteDataSource remoteDataSource;

  MosqueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Mosque>>> getMosques({int? limit, int? offset}) async {
    return executeWithCatch(() => remoteDataSource.getMosques(limit: limit, offset: offset));
  }

  @override
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    return executeWithCatch(() async {
      final mosqueModel = await remoteDataSource.addMosque(
        name: name,
        location: location,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      return mosqueModel;
    });
  }

  @override
  Future<Either<Failure, void>> addPublisher(
    String mosqueId,
    String email,
  ) async {
    return executeWithCatch(() => remoteDataSource.addPublisher(mosqueId, email));
  }
}
