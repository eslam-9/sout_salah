import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/day_schedule_entry.dart';

abstract class DayScheduleRepository {
  Future<Either<Failure, List<DayScheduleEntry>>> getDaySchedule(String dayId);
  Future<Either<Failure, DayScheduleEntry>> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  });
  Future<Either<Failure, DayScheduleEntry>> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  });
  Future<Either<Failure, void>> deleteScheduleEntry(String entryId);
}
