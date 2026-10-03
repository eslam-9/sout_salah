import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_video.dart';
import '../repositories/video_repository.dart';

class UploadVideoParams {
  const UploadVideoParams({
    required this.videoFile,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
    this.title,
    this.description,
    this.onProgress,
  });

  final File videoFile;
  final String mosqueId;
  final String dayId;
  final int dayNumber;
  final String? title;
  final String? description;
  final void Function(double)? onProgress;
}

class UploadVideoUseCase {
  const UploadVideoUseCase(this.repository);

  final VideoRepository repository;

  Future<Either<Failure, DailyVideo>> call(UploadVideoParams params) {
    return repository.uploadVideo(
      videoFile: params.videoFile,
      mosqueId: params.mosqueId,
      dayId: params.dayId,
      dayNumber: params.dayNumber,
      title: params.title,
      description: params.description,
      onProgress: params.onProgress,
    );
  }
}
