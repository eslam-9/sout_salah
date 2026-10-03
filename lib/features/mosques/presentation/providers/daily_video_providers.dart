import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_video.dart';
import 'mosque_data_providers.dart';

/// Fetches ALL videos for a given day (supports multiple videos per day).
final dailyVideoListProvider =
    FutureProvider.autoDispose.family<List<DailyVideo>, String>((ref, dayId) async {
      final getVideosForDayUseCase = ref.watch(getVideosForDayUseCaseProvider);
      final result = await getVideosForDayUseCase(dayId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (videos) => videos,
      );
    });
