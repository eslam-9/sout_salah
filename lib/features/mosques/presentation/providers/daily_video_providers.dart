import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/riverpod_providers.dart';
import '../../data/models/daily_video_model.dart';
import '../../data/repositories/video_repository.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(
    supabaseClient: ref.watch(supabaseClientProvider),
    r2StorageService: ref.watch(r2StorageServiceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

/// Fetches ALL videos for a given day (supports multiple videos per day).
final dailyVideoListProvider =
    FutureProvider.family<List<DailyVideoModel>, String>((ref, dayId) async {
      final repository = ref.watch(videoRepositoryProvider);
      return repository.getVideosForDay(dayId);
    });
