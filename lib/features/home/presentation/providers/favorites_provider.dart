import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/favorite_recording.dart';
import '../../../../core/di/providers.dart';

/// Provider for favorites stream
final favoritesProvider = StreamProvider<List<FavoriteRecording>>((ref) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.favoritesStream;
});

/// Provider to check if a recording is favorite
final isFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  recordingId,
) async {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return await favoritesService.isFavorite(recordingId);
});

/// Provider to get all favorites
final allFavoritesProvider = FutureProvider<List<FavoriteRecording>>((
  ref,
) async {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return await favoritesService.getFavorites();
});
