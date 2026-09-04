import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/day_schedule_entry.dart';
import '../../domain/repositories/day_schedule_repository.dart';
import '../datasources/day_schedule_remote_data_source.dart';

class DayScheduleRepositoryImpl implements DayScheduleRepository {
  final DayScheduleRemoteDataSource remoteDataSource;

  DayScheduleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DayScheduleEntry>>> getDaySchedule(String dayId) async {
    return executeWithCatch(() => remoteDataSource.getDaySchedule(dayId));
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
    return executeWithCatch(() => remoteDataSource.addScheduleEntry(
      dayId: dayId,
      mosqueId: mosqueId,
      salah: salah,
      shikh: shikh,
      comments: comments,
      sortOrder: sortOrder,
    ));
  }

  @override
  Future<Either<Failure, DayScheduleEntry>> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  }) async {
    return executeWithCatch(() => remoteDataSource.updateScheduleEntry(
      entryId: entryId,
      salah: salah,
      shikh: shikh,
      comments: comments,
    ));
  }

  @override
  Future<Either<Failure, void>> deleteScheduleEntry(String entryId) async {
    return executeWithCatch(() => remoteDataSource.deleteScheduleEntry(entryId));
  }
}
