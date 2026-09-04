import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../constants/app_constants.dart';
import '../network/network_info.dart';
import '../utils/app_logger.dart';
import '../services/r2_storage_service.dart';
import '../services/downloads_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => GetIt.I<SharedPreferences>());

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: NetworkConfig.standardTimeout,
      receiveTimeout: NetworkConfig.standardTimeout,
      sendTimeout: NetworkConfig.standardTimeout,
    ),
  );
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final appLoggerProvider = Provider<AppLogger>((ref) => GetIt.I<AppLogger>());

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  return R2StorageService(
    dio: ref.watch(dioProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final downloadsServiceProvider = Provider<DownloadsService>((ref) {
  return DownloadsService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(dioProvider),
    ref.watch(appLoggerProvider),
  );
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) => AudioPlayerService());

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(appLoggerProvider),
  );
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

/// Current playing recording ID provider
final currentPlayingRecordingProvider = StateProvider<String?>((ref) => null);
