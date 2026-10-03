import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_video.dart';
import '../repositories/video_repository.dart';

class DeleteVideoUseCase {
  const DeleteVideoUseCase(this.repository);

  final VideoRepository repository;

  Future<Either<Failure, void>> call(DailyVideo video) {
    return repository.deleteVideo(video);
  }
}
