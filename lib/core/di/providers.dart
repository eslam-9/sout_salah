import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/network_info.dart';

import 'package:sout_salah/core/utils/app_logger.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../services/r2_storage_service.dart';
import '../services/audio_player_service.dart';

// Services
final dioProvider = Provider<Dio>((ref) => GetIt.I<Dio>());
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => GetIt.I<SupabaseClient>(),
);
final appLoggerProvider = Provider<AppLogger>((ref) => GetIt.I<AppLogger>());
final r2StorageServiceProvider = Provider<R2StorageService>(
  (ref) => GetIt.I<R2StorageService>(),
);
final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => GetIt.I<FavoritesService>(),
);
final downloadsServiceProvider = Provider<DownloadsService>(
  (ref) => GetIt.I<DownloadsService>(),
);
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => GetIt.I<SharedPreferences>(),
);
final audioPlayerServiceProvider = Provider<AudioPlayerService>(
  (ref) => GetIt.I<AudioPlayerService>(),
);
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(Connectivity()),
);

/// Current playing recording ID provider
final currentPlayingRecordingProvider = StateProvider<String?>((ref) => null);
