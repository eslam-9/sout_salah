import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque.dart';
import '../entities/ramadan_day.dart';
import '../entities/recording.dart';
import '../entities/prayer.dart';
import '../entities/day_schedule_entry.dart';

abstract class MosqueRepository {
  Future<Either<Failure, List<Mosque>>> getMosques();
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  });
  Future<Either<Failure, void>> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  });
  Future<Either<Failure, List<Map<String, int>>>> getAvailableMonths(
    String mosqueId,
  );
  Future<Either<Failure, List<Recording>>> getDayRecordings(String dayId);
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  });

  Future<Either<Failure, Recording>> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  });

  Future<Either<Failure, void>> deleteRecording(String recordingId);
  Future<Either<Failure, void>> addPublisher(String mosqueId, String email);
  Future<Either<Failure, Recording>> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  });

  // Day Schedule Methods
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

