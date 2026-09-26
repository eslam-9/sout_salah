import '../../../../core/error/failures.dart';
import '../entities/recording.dart';

sealed class UploadState {
  const UploadState();
}

class UploadInitial extends UploadState {
  const UploadInitial();
}

class UploadProgress extends UploadState {
  const UploadProgress(this.progress);
  final double progress;
}

class UploadSuccess extends UploadState {
  const UploadSuccess(this.recording);
  final Recording recording;
}

class UploadError extends UploadState {
  const UploadError(this.failure);
  final Failure failure;
}
