import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/mosque_remote_data_source.dart';
import '../../data/repositories/mosque_repository_impl.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../../domain/entities/recording.dart';
import '../../domain/usecases/upload_recording_usecase.dart';
import '../../domain/usecases/delete_recording_usecase.dart';
import '../../domain/usecases/add_publisher_usecase.dart';

final mosqueRemoteDataSourceProvider = Provider<MosqueRemoteDataSource>((ref) {
  return MosqueRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(r2StorageServiceProvider),
    ref.watch(appLoggerProvider),
  );
});

final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepositoryImpl(
    remoteDataSource: ref.watch(mosqueRemoteDataSourceProvider),
  );
});

// Provider for fetching recordings for a specific day
final dayRecordingsProvider = FutureProvider.family<List<Recording>, String>((
  ref,
  dayId,
) async {
  final repository = ref.watch(mosqueRepositoryProvider);
  final result = await repository.getDayRecordings(dayId);

  return result.fold(
    (failure) => throw Exception('Failed to load recordings'),
    (recordings) => recordings,
  );
});

final uploadRecordingUseCaseProvider = Provider<UploadRecordingUseCase>((ref) {
  return UploadRecordingUseCase(ref.watch(mosqueRepositoryProvider));
});

final deleteRecordingUseCaseProvider = Provider<DeleteRecordingUseCase>((ref) {
  return DeleteRecordingUseCase(ref.watch(mosqueRepositoryProvider));
});

final addPublisherUseCaseProvider = Provider<AddPublisherUseCase>((ref) {
  return AddPublisherUseCase(ref.watch(mosqueRepositoryProvider));
});
