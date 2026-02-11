import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/presentation/pages/home_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'core/services/favorites_service.dart';
import 'core/services/downloads_service.dart';
import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';

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
  final favoritesService = FavoritesService(prefs);
  final downloadsService = DownloadsService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        favoritesServiceProvider.overrideWithValue(favoritesService),
        downloadsServiceProvider.overrideWithValue(downloadsService),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const HomeLayout(),
    );
  }
}
