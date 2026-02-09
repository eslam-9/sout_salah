import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_day_recordings_usecase.dart';
import '../../domain/entities/recording.dart';
import 'mosque_data_providers.dart';
import '../../../../core/error/failures.dart';

// State for Recordings
abstract class RecordingsState {
  const RecordingsState();
}

class RecordingsInitial extends RecordingsState {}

class RecordingsLoading extends RecordingsState {}

class RecordingsLoadedState extends RecordingsState {
  final List<Recording> recordings;
  const RecordingsLoadedState(this.recordings);
}

class RecordingsError extends RecordingsState {
  final String message;
  const RecordingsError(this.message);
}

// Provider for GetDayRecordingsUseCase
final getDayRecordingsUseCaseProvider = Provider(
  (ref) => GetDayRecordingsUseCase(ref.watch(mosqueRepositoryProvider)),
);

// StateNotifier for Recordings
class RecordingsNotifier extends StateNotifier<RecordingsState> {
  final GetDayRecordingsUseCase getDayRecordingsUseCase;

  RecordingsNotifier({required this.getDayRecordingsUseCase})
    : super(RecordingsInitial());

  Future<void> loadRecordings(String dayId) async {
    state = RecordingsLoading();
    final result = await getDayRecordingsUseCase(
      GetDayRecordingsParams(dayId: dayId),
    );
    result.fold(
      (failure) => state = RecordingsError(_mapFailureToMessage(failure)),
      (recordings) => state = RecordingsLoadedState(recordings),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Failure';
    } else if (failure is CacheFailure) {
      return 'Cache Failure';
    } else {
      return 'Unexpected Error';
    }
  }
}

// Provider for Recordings
final recordingsProvider =
    StateNotifierProvider<RecordingsNotifier, RecordingsState>((ref) {
      return RecordingsNotifier(
        getDayRecordingsUseCase: ref.watch(getDayRecordingsUseCaseProvider),
      );
    });
