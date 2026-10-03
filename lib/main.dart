import 'dart:ui';

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
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Startup assertions: fail fast if secrets were not injected ---
  assert(
    AppConfig.supabaseUrl.isNotEmpty,
    'SUPABASE_URL must be provided via --dart-define-from-file=secrets.json',
  );
  assert(
    AppConfig.supabaseAnonKey.isNotEmpty,
    'SUPABASE_ANON_KEY must be provided via --dart-define-from-file=secrets.json',
  );
  assert(
    AppConfig.r2Endpoint.isNotEmpty,
    'R2_ENDPOINT must be provided',
  );
  assert(
    AppConfig.r2AccessKey.isNotEmpty,
    'R2_ACCESS_KEY must be provided',
  );
  assert(
    AppConfig.r2SecretKey.isNotEmpty,
    'R2_SECRET_KEY must be provided',
  );
  assert(
    AppConfig.r2Bucket.isNotEmpty,
    'R2_BUCKET must be provided',
  );
  assert(
    AppConfig.r2CdnUrl.isNotEmpty,
    'R2_CDN_URL must be provided',
  );

  // Initialize Service Locator first so AppLogger is available
  await di.setupServiceLocator();

  // --- Global error boundary: log all uncaught errors in release builds ---
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // still shows red screen in debug
    GetIt.I<AppLogger>().e(
      'Uncaught Flutter Error',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    GetIt.I<AppLogger>().e('Unhandled Platform Error', error, stack);
    return true; // prevent app crash
  };

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    // Register client AFTER successful initialization
    di.sl.registerLazySingleton(() => Supabase.instance.client);
  } catch (e, stackTrace) {
    GetIt.I<AppLogger>().e(
      'Failed to initialize Supabase (likely offline)',
      e,
      stackTrace,
    );
  }

  // Initialize Notification Service for Push Notifications
  GetIt.I<AppLogger>().i('Initializing NotificationService...');
  try {
    await NotificationService.initialize();
  } catch (e, stackTrace) {
    GetIt.I<AppLogger>().e(
      'Failed to initialize NotificationService (likely offline)',
      e,
      stackTrace,
    );
  }

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
      'Failed to initialize JustAudioBackground',
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
      title: 'صوت صلاه',
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
