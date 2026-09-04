import 'dart:async';

import '../../../../core/error/failures.dart';
import '../repositories/recordings_repository.dart';
import 'upload_recording_params.dart';
import '../entities/upload_state.dart';

/// Use case for uploading a recording, returning a stream of upload state
class UploadRecordingUseCase {
  final RecordingsRepository repository;

  UploadRecordingUseCase(this.repository);

  Stream<UploadState> call(UploadRecordingParams params) {
    final controller = StreamController<UploadState>();
    
    controller.add(const UploadInitial());

    repository.uploadRecording(
      mosqueId: params.mosqueId,
      dayId: params.dayId,
      prayer: params.prayer,
      customPrayerName: params.customPrayerName,
      sheikhName: params.sheikhName,
      filePath: params.filePath,
      fileSize: params.fileSize,
      duration: params.duration,
      onProgress: (progress) {
        if (!controller.isClosed) {
          controller.add(UploadProgress(progress));
        }
      },
    ).then((result) async {
      result.fold(
        (failure) {
          if (!controller.isClosed) {
            controller.add(UploadError(failure));
            controller.close();
          }
        },
        (recording) async {
          if (params.pendingRecordingId != null) {
            try {
              await repository.deleteRecording(params.pendingRecordingId!);
            } catch (e) {
              // Ignore error if deleting pending recording fails
            }
          }
          if (!controller.isClosed) {
            controller.add(UploadSuccess(recording));
            controller.close();
          }
        },
      );
    }).catchError((error) {
      // In case of unexpected unhandled exceptions
      if (!controller.isClosed) {
        controller.add(UploadError(ServerFailure(message: error.toString())));
        controller.close();
      }
    });

    return controller.stream;
  }
}
