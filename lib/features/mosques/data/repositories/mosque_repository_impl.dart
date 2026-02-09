import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/entities/ramadan_day.dart';
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
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(
    String mosqueId,
  ) async {
    try {
      final remoteDays = await remoteDataSource.getRamadanDays(mosqueId);
      return Right(remoteDays);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
