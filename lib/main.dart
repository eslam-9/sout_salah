import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:dio/dio.dart';

import 'core/services/favorites_service.dart';
import 'core/services/downloads_service.dart';
import 'core/services/navigation_service.dart';
import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize JustAudioBackground for background audio and notifications
  try {
    debugPrint('Initializing JustAudioBackground...');
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.sout_salah.audio',
      androidNotificationChannelName: 'Sout Salah Audio',
      androidNotificationOngoing: true,
    );
    debugPrint('JustAudioBackground initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR: Failed to initialize JustAudioBackground');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  try {
    debugPrint('Initializing Supabase...');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR: Failed to initialize Supabase');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Dio
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ),
  );

  final favoritesService = FavoritesService(prefs);
  final downloadsService = DownloadsService(prefs, dio);

  runApp(
    ProviderScope(
      overrides: [
        favoritesServiceProvider.overrideWithValue(favoritesService),
        downloadsServiceProvider.overrideWithValue(downloadsService),
        sharedPreferencesProvider.overrideWithValue(prefs),
        dioProvider.overrideWithValue(dio),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sout Salah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Navigation configuration
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
      initialRoute: AppRoutes.home,

      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
