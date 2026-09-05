import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/recording.dart';
import '../entities/prayer.dart';

abstract class RecordingsRepository {
  Future<Either<Failure, List<Recording>>> getDayRecordings(String dayId, {int? limit, int? offset});
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
  Future<Either<Failure, Recording>> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  });
}
