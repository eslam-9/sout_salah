import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recording.dart';
import '../repositories/recordings_repository.dart';
import 'upload_recording_params.dart';

/// Use case for uploading a recording
class UploadRecordingUseCase
    implements UseCase<Recording, UploadRecordingParams> {
  final RecordingsRepository repository;

  UploadRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, Recording>> call(UploadRecordingParams params) async {
    final result = await repository.uploadRecording(
      mosqueId: params.mosqueId,
      dayId: params.dayId,
      prayer: params.prayer,
      customPrayerName: params.customPrayerName,
      sheikhName: params.sheikhName,
      filePath: params.filePath,
      fileSize: params.fileSize,
      duration: params.duration,
      onProgress: params.onProgress,
    );

    return result.fold((failure) => Left(failure), (recording) async {
      if (params.pendingRecordingId != null) {
        try {
          await repository.deleteRecording(params.pendingRecordingId!);
        } catch (e) {
          // Ignore error if deleting pending recording fails,
          // as the main upload was successful.
          // Ideally should log this.
        }
      }
      return Right(recording);
    });
  }
}
