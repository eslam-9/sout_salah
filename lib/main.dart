import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/config/app_config.dart';
import 'core/services/navigation_service.dart';
import 'package:get_it/get_it.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/widgets/startup_check_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Service Locator
  await di.setupServiceLocator();

  // Initialize JustAudioBackground for background audio and notifications
  try {
    GetIt.I<AppLogger>().i('Initializing JustAudioBackground...');
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.sout_salah.audio',
      androidNotificationChannelName: 'Sout Salah Audio',
      androidNotificationOngoing: true,
    );
    GetIt.I<AppLogger>().i('JustAudioBackground initialized successfully');
  } catch (e, stackTrace) {
    GetIt.I<AppLogger>().e(
      '❌ CRITICAL ERROR: Failed to initialize JustAudioBackground',
      e,
      stackTrace,
    );
  }

  runApp(const ProviderScope(child: MyApp()));
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
      initialRoute: AppRoutes.splash,

      builder: (context, child) {
        return StartupCheckWrapper(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
  }
}
