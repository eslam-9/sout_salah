import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ramadan_day.dart';
import '../../domain/repositories/ramadan_days_repository.dart';
import '../datasources/ramadan_days_remote_data_source.dart';

class RamadanDaysRepositoryImpl implements RamadanDaysRepository {
  final RamadanDaysRemoteDataSource remoteDataSource;

  RamadanDaysRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  }) async {
    try {
      final remoteDays = await remoteDataSource.getRamadanDays(
        mosqueId,
        month: month,
        year: year,
      );
      return Right(remoteDays);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  }) async {
    try {
      await remoteDataSource.addMonth(
        mosqueId: mosqueId,
        month: month,
        year: year,
      );
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Map<String, int>>>> getAvailableMonths(
    String mosqueId,
  ) async {
    try {
      final months = await remoteDataSource.getAvailableMonths(mosqueId);
      return Right(months);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
