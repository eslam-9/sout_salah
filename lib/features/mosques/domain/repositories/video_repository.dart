import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_video.dart';

abstract class VideoRepository {
  Future<Either<Failure, List<DailyVideo>>> getVideosForDay(String dayId);
  Future<Either<Failure, DailyVideo>> uploadVideo({
    required File videoFile,
    required String mosqueId,
    required String dayId,
    required int dayNumber,
    String? title,
    String? description,
    void Function(double)? onProgress,
  });
  Future<Either<Failure, void>> deleteVideo(DailyVideo video);
}
