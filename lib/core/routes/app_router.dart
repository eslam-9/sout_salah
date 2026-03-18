import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import '../utils/app_logger.dart';
import '../../features/home/presentation/pages/home_layout.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/mosques/presentation/pages/mosque_detail_page.dart';
import '../../features/mosques/presentation/pages/day_detail_page.dart';
import '../../features/mosques/presentation/pages/day_schedule_page.dart';
import '../../features/mosques/presentation/pages/add_mosque_page.dart';
import '../../features/mosques/presentation/pages/upload_recording_page.dart';
import '../../features/mosques/presentation/pages/device_audio_selection_page.dart';
import '../../features/mosques/presentation/pages/audio_player_page.dart';
import '../../features/mosques/presentation/pages/video_player_page.dart';
import '../../features/mosques/presentation/pages/daily_video_page.dart';
import '../../features/mosques/presentation/pages/upload_daily_video_page.dart';
import '../../features/mosques/domain/entities/mosque.dart';

import '../presentation/pages/error_page.dart';
import '../presentation/pages/splash_screen.dart';
import 'app_routes.dart';
import 'route_args.dart';
import 'route_transitions.dart';



/// Centralized router for the application
///
/// Handles route generation, authentication guards, and custom transitions
class AppRouter {
  /// Check if user is authenticated (including anonymous guests)
  static bool _isAuthenticated() {
    try {
      final user = GetIt.I<SupabaseClient>().auth.currentUser;
      return user != null;
    } catch (_) {
      // Return false if Supabase throws (e.g., offline)
      return false;
    }
  }

  /// Main route generator
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    GetIt.I<AppLogger>().i('🧭 AppRouter: Navigating to ${settings.name}');

    // Check if route requires authentication
    final requiresAuth = AppRoutes.authRequiredRoutes.contains(settings.name);

    // If route requires auth and user is not authenticated, redirect to login
    if (requiresAuth && !_isAuthenticated()) {
      GetIt.I<AppLogger>().w(
        '⚠️ AppRouter: Route requires auth, redirecting to login',
      );
      return RouteTransitions.fadeTransition(
        const LoginPage(),
        const RouteSettings(name: AppRoutes.login),
      );
    }

    // Route handling
    switch (settings.name) {
      case AppRoutes.splash:
        return RouteTransitions.fadeTransition(const SplashScreen(), settings);

      case AppRoutes.home:
        if (!_isAuthenticated()) {
          GetIt.I<AppLogger>().i(
            'Redirecting home to login (not authenticated)',
          );
          return RouteTransitions.fadeTransition(const LoginPage(), settings);
        }
        return RouteTransitions.fadeTransition(const HomeLayout(), settings);

      case AppRoutes.login:
        return RouteTransitions.fadeTransition(const LoginPage(), settings);

      case AppRoutes.signup:
        return RouteTransitions.slideTransition(const SignUpPage(), settings);

      case AppRoutes.profile:
        return RouteTransitions.slideTransition(const ProfilePage(), settings);

      case AppRoutes.mosqueDetail:
        // Validate arguments
        if (settings.arguments is! Mosque) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for mosqueDetail',
          );
          return _errorRoute(settings);
        }
        final mosque = settings.arguments as Mosque;
        return RouteTransitions.slideTransition(
          MosqueDetailPage(mosque: mosque),
          settings,
        );

      case AppRoutes.dayDetail:
        // Validate arguments
        if (settings.arguments is! DayDetailArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for dayDetail',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as DayDetailArgs;
        return RouteTransitions.slideTransition(
          DayDetailPage(day: args.day),
          settings,
        );

      case AppRoutes.daySchedule:
        if (settings.arguments is! DayScheduleArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for daySchedule',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as DayScheduleArgs;
        return RouteTransitions.slideTransition(
          DaySchedulePage(
            dayId: args.dayId,
            mosqueId: args.mosqueId,
            dayNumber: args.dayNumber,
            month: args.month,
          ),
          settings,
        );

      case AppRoutes.uploadRecording:
        // Validate arguments
        if (settings.arguments is! UploadRecordingArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for uploadRecording',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as UploadRecordingArgs;
        if (!args.validate()) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid uploadRecording arguments',
          );
          return _errorRoute(settings);
        }
        return RouteTransitions.slideTransition(
          UploadRecordingPage(
            mosqueId: args.mosqueId,
            dayId: args.dayId,
            dayNumber: args.dayNumber,
            month: args.month,
            prayer: args.prayer,
            customPrayerName: args.customPrayerName,
            pendingRecordingId: args.pendingRecordingId,
          ),
          settings,
        );

      case AppRoutes.addMosque:
        return RouteTransitions.slideTransition(
          const AddMosquePage(),
          settings,
        );

      case AppRoutes.deviceAudioSelection:
        return RouteTransitions.slideTransition(
          const DeviceAudioSelectionPage(),
          settings,
        );

      case AppRoutes.audioPlayer:
        if (settings.arguments is! AudioPlayerArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for audioPlayer',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as AudioPlayerArgs;
        return RouteTransitions.slideTransition(
          AudioPlayerPage(recording: args.recording),
          settings,
        );

      case AppRoutes.videoPlayer:
        if (settings.arguments is! VideoPlayerArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for videoPlayer',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as VideoPlayerArgs;
        return RouteTransitions.slideTransition(
          VideoPlayerPage(video: args.video),
          settings,
        );

      case AppRoutes.dailyVideo:
        if (settings.arguments is! DailyVideoArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for dailyVideo',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as DailyVideoArgs;
        return MaterialPageRoute(
          builder: (_) => DailyVideoPage(dayId: args.dayId),
          settings: settings,
        );

      case AppRoutes.uploadDailyVideo:
        if (settings.arguments is! UploadDailyVideoArgs) {
          GetIt.I<AppLogger>().e(
            '❌ AppRouter: Invalid arguments for uploadDailyVideo',
          );
          return _errorRoute(settings);
        }
        final args = settings.arguments as UploadDailyVideoArgs;
        return RouteTransitions.slideTransition(
          UploadDailyVideoPage(
            mosqueId: args.mosqueId,
            dayId: args.dayId,
            dayNumber: args.dayNumber,
          ),
          settings,
        );

      default:
        GetIt.I<AppLogger>().e('❌ AppRouter: Unknown route ${settings.name}');
        return _errorRoute(settings);
    }
  }

  /// Error route for invalid routes
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => ErrorPage(routeName: settings.name),
    );
  }

  /// Handler for unknown routes
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    GetIt.I<AppLogger>().e('❌ AppRouter: Unknown route ${settings.name}');
    return _errorRoute(settings);
  }
}
