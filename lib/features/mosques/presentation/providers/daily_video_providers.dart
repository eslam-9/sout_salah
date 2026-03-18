import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/models/daily_video_model.dart';
import '../../data/repositories/video_repository.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(
    supabaseClient: ref.watch(supabaseClientProvider),
    r2StorageService: ref.watch(r2StorageServiceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final dailyVideoProvider = FutureProvider.family<DailyVideoModel?, String>((
  ref,
  dayId,
) async {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getVideoForDay(dayId);
});
