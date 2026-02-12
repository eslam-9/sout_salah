import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recording.dart';
import '../repositories/mosque_repository.dart';
import 'upload_recording_params.dart';

/// Use case for uploading a recording
class UploadRecordingUseCase
    implements UseCase<Recording, UploadRecordingParams> {
  final MosqueRepository repository;

  UploadRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, Recording>> call(UploadRecordingParams params) async {
    return await repository.uploadRecording(
      mosqueId: params.mosqueId,
      dayId: params.dayId,
      prayer: params.prayer,
      sheikhName: params.sheikhName,
      filePath: params.filePath,
      fileSize: params.fileSize,
      duration: params.duration,
      onProgress: params.onProgress,
    );
  }
}
