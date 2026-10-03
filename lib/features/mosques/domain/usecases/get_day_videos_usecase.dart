import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_video.dart';
import '../repositories/video_repository.dart';

class GetDayVideosUseCase {
  const GetDayVideosUseCase(this.repository);

  final VideoRepository repository;

  Future<Either<Failure, List<DailyVideo>>> call(String dayId) {
    return repository.getVideosForDay(dayId);
  }
}
