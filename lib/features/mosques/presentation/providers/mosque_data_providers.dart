import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/riverpod_providers.dart';
import '../../data/datasources/mosque_remote_data_source.dart';
import '../../data/datasources/ramadan_days_remote_data_source.dart';
import '../../data/datasources/recordings_remote_data_source.dart';
import '../../data/datasources/mosque_requests_remote_data_source.dart';
import '../../data/datasources/day_schedule_remote_data_source.dart';
import '../../data/repositories/mosque_repository_impl.dart';
import '../../data/repositories/ramadan_days_repository_impl.dart';
import '../../data/repositories/recordings_repository_impl.dart';
import '../../data/repositories/mosque_requests_repository_impl.dart';
import '../../data/repositories/day_schedule_repository_impl.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../../domain/repositories/ramadan_days_repository.dart';
import '../../domain/repositories/recordings_repository.dart';
import '../../domain/repositories/mosque_requests_repository.dart';
import '../../domain/repositories/day_schedule_repository.dart';
import '../../domain/entities/recording.dart';
import '../../domain/usecases/upload_recording_usecase.dart';
import '../../domain/usecases/delete_recording_usecase.dart';
import '../../domain/usecases/add_publisher_usecase.dart';
import '../../domain/usecases/add_mosque_usecase.dart';
import '../../domain/usecases/add_month_usecase.dart';
import '../../domain/usecases/create_pending_recording_usecase.dart';

// --- Data Sources ---
final mosqueRemoteDataSourceProvider = Provider<MosqueRemoteDataSource>((ref) {
  return MosqueRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});

final ramadanDaysRemoteDataSourceProvider = Provider<RamadanDaysRemoteDataSource>((ref) {
  return RamadanDaysRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});

final recordingsRemoteDataSourceProvider = Provider<RecordingsRemoteDataSource>((ref) {
  return RecordingsRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(r2StorageServiceProvider),
    ref.watch(appLoggerProvider),
  );
});

final mosqueRequestsRemoteDataSourceProvider = Provider<MosqueRequestsRemoteDataSource>((ref) {
  return MosqueRequestsRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});

final dayScheduleRemoteDataSourceProvider = Provider<DayScheduleRemoteDataSource>((ref) {
  return DayScheduleRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});


// --- Repositories ---
final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepositoryImpl(
    remoteDataSource: ref.watch(mosqueRemoteDataSourceProvider),
  );
});

final ramadanDaysRepositoryProvider = Provider<RamadanDaysRepository>((ref) {
  return RamadanDaysRepositoryImpl(
    remoteDataSource: ref.watch(ramadanDaysRemoteDataSourceProvider),
  );
});

final recordingsRepositoryProvider = Provider<RecordingsRepository>((ref) {
  return RecordingsRepositoryImpl(
    remoteDataSource: ref.watch(recordingsRemoteDataSourceProvider),
  );
});

final mosqueRequestsRepositoryProvider = Provider<MosqueRequestsRepository>((ref) {
  return MosqueRequestsRepositoryImpl(
    remoteDataSource: ref.watch(mosqueRequestsRemoteDataSourceProvider),
  );
});

final dayScheduleRepositoryProvider = Provider<DayScheduleRepository>((ref) {
  return DayScheduleRepositoryImpl(
    remoteDataSource: ref.watch(dayScheduleRemoteDataSourceProvider),
  );
});

// --- Use Cases & Providers ---
final dayRecordingsProvider = FutureProvider.family<List<Recording>, String>((
  ref,
  dayId,
) async {
  final repository = ref.watch(recordingsRepositoryProvider);
  final result = await repository.getDayRecordings(dayId);

  return result.fold(
    (failure) => throw Exception('Failed to load recordings'),
    (recordings) => recordings,
  );
});

final uploadRecordingUseCaseProvider = Provider<UploadRecordingUseCase>((ref) {
  return UploadRecordingUseCase(ref.watch(recordingsRepositoryProvider));
});

final deleteRecordingUseCaseProvider = Provider<DeleteRecordingUseCase>((ref) {
  return DeleteRecordingUseCase(ref.watch(recordingsRepositoryProvider));
});

final addPublisherUseCaseProvider = Provider<AddPublisherUseCase>((ref) {
  return AddPublisherUseCase(ref.watch(mosqueRepositoryProvider));
});

final addMosqueUseCaseProvider = Provider<AddMosqueUseCase>((ref) {
  return AddMosqueUseCase(ref.watch(mosqueRepositoryProvider));
});

final addMonthUseCaseProvider = Provider<AddMonthUseCase>((ref) {
  return AddMonthUseCase(ref.watch(ramadanDaysRepositoryProvider));
});

final createPendingRecordingUseCaseProvider =
    Provider<CreatePendingRecordingUseCase>((ref) {
      return CreatePendingRecordingUseCase(ref.watch(recordingsRepositoryProvider));
    });
