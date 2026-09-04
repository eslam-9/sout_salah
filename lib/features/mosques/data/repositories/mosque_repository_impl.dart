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
  Future<Either<Failure, List<Mosque>>> getMosques() async {
    return executeWithCatch(() => remoteDataSource.getMosques());
  }

  @override
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    return executeWithCatch(() => remoteDataSource.addMosque(
      name: name,
      location: location,
      description: description,
    ));
  }

  @override
  Future<Either<Failure, void>> addPublisher(
    String mosqueId,
    String email,
  ) async {
    return executeWithCatch(() => remoteDataSource.addPublisher(mosqueId, email));
  }
}
