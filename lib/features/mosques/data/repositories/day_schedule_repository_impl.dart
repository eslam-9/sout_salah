import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/day_schedule_entry.dart';
import '../../domain/repositories/day_schedule_repository.dart';
import '../datasources/day_schedule_remote_data_source.dart';

class DayScheduleRepositoryImpl implements DayScheduleRepository {
  final DayScheduleRemoteDataSource remoteDataSource;

  DayScheduleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DayScheduleEntry>>> getDaySchedule(String dayId) async {
    try {
      final schedule = await remoteDataSource.getDaySchedule(dayId);
      return Right(schedule);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, DayScheduleEntry>> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  }) async {
    try {
      final entry = await remoteDataSource.addScheduleEntry(
        dayId: dayId,
        mosqueId: mosqueId,
        salah: salah,
        shikh: shikh,
        comments: comments,
        sortOrder: sortOrder,
      );
      return Right(entry);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, DayScheduleEntry>> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  }) async {
    try {
      final entry = await remoteDataSource.updateScheduleEntry(
        entryId: entryId,
        salah: salah,
        shikh: shikh,
        comments: comments,
      );
      return Right(entry);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteScheduleEntry(String entryId) async {
    try {
      await remoteDataSource.deleteScheduleEntry(entryId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
