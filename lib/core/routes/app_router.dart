import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_layout.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/mosques/presentation/pages/mosque_detail_page.dart';
import '../../features/mosques/presentation/pages/day_detail_page.dart';
import '../../features/mosques/presentation/pages/upload_recording_page.dart';
import '../../features/mosques/presentation/pages/add_mosque_page.dart';
import '../../features/mosques/presentation/pages/device_audio_selection_page.dart';
import '../../features/mosques/domain/entities/mosque.dart';
import '../../features/mosques/domain/entities/ramadan_day.dart';
import 'app_routes.dart';
import 'route_args.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeLayout());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case AppRoutes.mosqueDetail:
        final mosque = settings.arguments as Mosque;
        return MaterialPageRoute(
          builder: (_) => MosqueDetailPage(mosque: mosque),
        );
      case AppRoutes.dayDetail:
        final day = settings.arguments as RamadanDay;
        return MaterialPageRoute(builder: (_) => DayDetailPage(day: day));
      case AppRoutes.uploadRecording:
        final args = settings.arguments as UploadRecordingArgs;
        return MaterialPageRoute(
          builder: (_) =>
              UploadRecordingPage(mosqueId: args.mosqueId, dayId: args.dayId),
        );
      case AppRoutes.addMosque:
        return MaterialPageRoute(builder: (_) => const AddMosquePage());
      case AppRoutes.deviceAudioSelection:
        return MaterialPageRoute(
          builder: (_) => const DeviceAudioSelectionPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
