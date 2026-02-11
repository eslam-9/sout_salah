import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../services/r2_storage_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  return R2StorageService();
});

// FavoritesService provider
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  throw UnimplementedError('FavoritesService must be overridden in main.dart');
});

// DownloadsService provider
final downloadsServiceProvider = Provider<DownloadsService>((ref) {
  throw UnimplementedError('DownloadsService must be overridden in main.dart');
});

final sharedPreferencesProvider = Provider<sp.SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});
