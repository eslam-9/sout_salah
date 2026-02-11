import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/presentation/pages/home_layout.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/mosques/presentation/pages/mosque_detail_page.dart';
import '../../features/mosques/presentation/pages/day_detail_page.dart';
import '../../features/mosques/presentation/pages/add_mosque_page.dart';
import '../../features/mosques/presentation/pages/upload_recording_page.dart';
import '../../features/mosques/presentation/pages/device_audio_selection_page.dart';
import '../../features/mosques/presentation/pages/audio_player_page.dart';
import '../../features/mosques/domain/entities/mosque.dart';
import '../../features/mosques/domain/entities/ramadan_day.dart';

import '../presentation/pages/error_page.dart';
import 'app_routes.dart';
import 'route_args.dart';
import 'route_transitions.dart';

/// Centralized router for the application
///
/// Handles route generation, authentication guards, and custom transitions
class AppRouter {
  /// Check if user is authenticated (not guest)
  static bool _isAuthenticated() {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  }

  /// Main route generator
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('🧭 AppRouter: Navigating to ${settings.name}');

    // Check if route requires authentication
    final requiresAuth = AppRoutes.authRequiredRoutes.contains(settings.name);

    // If route requires auth and user is not authenticated, redirect to login
    if (requiresAuth && !_isAuthenticated()) {
      debugPrint('⚠️ AppRouter: Route requires auth, redirecting to login');
      return RouteTransitions.fadeTransition(
        const LoginPage(),
        const RouteSettings(name: AppRoutes.login),
      );
    }

    // Route handling
    switch (settings.name) {
      case AppRoutes.home:
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
          debugPrint('❌ AppRouter: Invalid arguments for mosqueDetail');
          return _errorRoute(settings);
        }
        final mosque = settings.arguments as Mosque;
        return RouteTransitions.slideTransition(
          MosqueDetailPage(mosque: mosque),
          settings,
        );

      case AppRoutes.dayDetail:
        // Validate arguments
        if (settings.arguments is! RamadanDay) {
          debugPrint('❌ AppRouter: Invalid arguments for dayDetail');
          return _errorRoute(settings);
        }
        final day = settings.arguments as RamadanDay;
        return RouteTransitions.slideTransition(
          DayDetailPage(day: day),
          settings,
        );

      case AppRoutes.uploadRecording:
        // Validate arguments
        if (settings.arguments is! UploadRecordingArgs) {
          debugPrint('❌ AppRouter: Invalid arguments for uploadRecording');
          return _errorRoute(settings);
        }
        final args = settings.arguments as UploadRecordingArgs;
        if (!args.validate()) {
          debugPrint('❌ AppRouter: Invalid uploadRecording arguments');
          return _errorRoute(settings);
        }
        return RouteTransitions.slideTransition(
          UploadRecordingPage(mosqueId: args.mosqueId, dayId: args.dayId),
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
          debugPrint('❌ AppRouter: Invalid arguments for audioPlayer');
          return _errorRoute(settings);
        }
        final args = settings.arguments as AudioPlayerArgs;
        return RouteTransitions.slideTransition(
          AudioPlayerPage(recording: args.recording),
          settings,
        );

      default:
        debugPrint('❌ AppRouter: Unknown route ${settings.name}');
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
    debugPrint('❌ AppRouter: Unknown route ${settings.name}');
    return _errorRoute(settings);
  }
}
