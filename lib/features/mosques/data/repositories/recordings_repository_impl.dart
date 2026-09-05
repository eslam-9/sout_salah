import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/repositories/recordings_repository.dart';
import '../datasources/recordings_remote_data_source.dart';

class RecordingsRepositoryImpl implements RecordingsRepository {
  final RecordingsRemoteDataSource remoteDataSource;

  RecordingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Recording>>> getDayRecordings(String dayId, {int? limit, int? offset}) async {
    return executeWithCatch(() => remoteDataSource.getDayRecordings(dayId, limit: limit, offset: offset));
  }

  @override
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
  }) async {
    return executeWithCatch(() => remoteDataSource.uploadRecording(
      mosqueId: mosqueId,
      dayId: dayId,
      prayer: prayer,
      customPrayerName: customPrayerName,
      sheikhName: sheikhName,
      filePath: filePath,
      fileSize: fileSize,
      duration: duration,
      onProgress: onProgress,
    ));
  }

  @override
  Future<Either<Failure, void>> deleteRecording(String recordingId) async {
    return executeWithCatch(() => remoteDataSource.deleteRecording(recordingId));
  }

  @override
  Future<Either<Failure, Recording>> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  }) async {
    return executeWithCatch(() => remoteDataSource.createPendingRecording(
      mosqueId: mosqueId,
      dayId: dayId,
      prayerName: prayerName,
    ));
  }
}
