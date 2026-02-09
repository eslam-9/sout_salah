import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recording.dart';
import '../repositories/mosque_repository.dart';

class GetDayRecordingsParams {
  final String dayId;

  const GetDayRecordingsParams({required this.dayId});
}

class GetDayRecordingsUseCase
    implements UseCase<List<Recording>, GetDayRecordingsParams> {
  final MosqueRepository repository;

  GetDayRecordingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Recording>>> call(
    GetDayRecordingsParams params,
  ) async {
    return await repository.getDayRecordings(params.dayId);
  }
}
