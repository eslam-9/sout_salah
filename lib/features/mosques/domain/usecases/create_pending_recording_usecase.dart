import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recording.dart';
import '../repositories/mosque_repository.dart';
import 'create_pending_recording_params.dart';

class CreatePendingRecordingUseCase
    implements UseCase<Recording, CreatePendingRecordingParams> {
  final MosqueRepository repository;

  CreatePendingRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, Recording>> call(
    CreatePendingRecordingParams params,
  ) async {
    return await repository.createPendingRecording(
      mosqueId: params.mosqueId,
      dayId: params.dayId,
      prayerName: params.prayerName,
    );
  }
}
