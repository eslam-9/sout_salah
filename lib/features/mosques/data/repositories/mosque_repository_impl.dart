import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../datasources/mosque_remote_data_source.dart';

class MosqueRepositoryImpl implements MosqueRepository {
  final MosqueRemoteDataSource remoteDataSource;

  MosqueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Mosque>>> getMosques() async {
    try {
      final remoteMosques = await remoteDataSource.getMosques();
      return Right(remoteMosques);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    try {
      final mosque = await remoteDataSource.addMosque(
        name: name,
        location: location,
        description: description,
      );
      return Right(mosque);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addPublisher(
    String mosqueId,
    String email,
  ) async {
    try {
      await remoteDataSource.addPublisher(mosqueId, email);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message: message));
    }
  }
}
