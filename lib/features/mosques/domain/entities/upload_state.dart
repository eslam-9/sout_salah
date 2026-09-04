import '../../../../core/error/failures.dart';
import '../entities/recording.dart';

sealed class UploadState {
  const UploadState();
}

class UploadInitial extends UploadState {
  const UploadInitial();
}

class UploadProgress extends UploadState {
  final double progress;
  const UploadProgress(this.progress);
}

class UploadSuccess extends UploadState {
  final Recording recording;
  const UploadSuccess(this.recording);
}

class UploadError extends UploadState {
  final Failure failure;
  const UploadError(this.failure);
}
