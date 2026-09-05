import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/favorite_recording.dart';
import '../../../../core/di/riverpod_providers.dart';

/// Provider for favorites stream
final favoritesProvider = StreamProvider<List<FavoriteRecording>>((ref) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.favoritesStream;
});

/// Provider to check if a recording is favorite
final isFavoriteProvider = Provider.autoDispose.family<AsyncValue<bool>, String>((
  ref,
  recordingId,
) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.whenData(
    (favorites) => favorites.any((f) => f.recordingId == recordingId),
  );
});

/// Provider to get all favorites
final allFavoritesProvider = Provider<AsyncValue<List<FavoriteRecording>>>((
  ref,
) {
  return ref.watch(favoritesProvider);
});
