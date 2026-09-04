import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/recordings_repository.dart';

class DeleteRecordingUseCase implements UseCase<void, DeleteRecordingParams> {
  final RecordingsRepository repository;

  DeleteRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRecordingParams params) async {
    return await repository.deleteRecording(params.recordingId);
  }
}

class DeleteRecordingParams extends Equatable {
  final String recordingId;
  final String mosqueId; // For permission checking if needed

  const DeleteRecordingParams({
    required this.recordingId,
    required this.mosqueId,
  });

  @override
  List<Object> get props => [recordingId, mosqueId];
}
