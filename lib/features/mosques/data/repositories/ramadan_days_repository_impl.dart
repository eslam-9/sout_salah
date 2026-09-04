import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
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
    return executeWithCatch(() => remoteDataSource.getRamadanDays(
      mosqueId,
      month: month,
      year: year,
    ));
  }

  @override
  Future<Either<Failure, void>> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  }) async {
    return executeWithCatch(() => remoteDataSource.addMonth(
      mosqueId: mosqueId,
      month: month,
      year: year,
    ));
  }

  @override
  Future<Either<Failure, List<Map<String, int>>>> getAvailableMonths(
    String mosqueId,
  ) async {
    return executeWithCatch(() => remoteDataSource.getAvailableMonths(mosqueId));
  }
}
