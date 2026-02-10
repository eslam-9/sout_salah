import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

// FavoritesService provider
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  throw UnimplementedError('FavoritesService must be overridden in main.dart');
});

// DownloadsService provider
final downloadsServiceProvider = Provider<DownloadsService>((ref) {
  throw UnimplementedError('DownloadsService must be overridden in main.dart');
});
