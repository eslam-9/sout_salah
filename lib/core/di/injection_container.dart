// NOTE: GetIt is used ONLY as a bootstrap bridge.
// AppLogger and NavigationService are registered here so that main.dart's
// global error handlers can access them before ProviderScope is initialized.
// All feature code must use Riverpod providers, not GetIt.
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../services/navigation_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // 2. Core Services
  sl.registerLazySingleton(() => AppLogger());
  sl.registerLazySingleton(() => NavigationService());
}
