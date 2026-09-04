import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import '../services/navigation_service.dart';
import '../services/startup_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Supabase.instance.client);

  // 2. Core Services
  sl.registerLazySingleton(() => AppLogger());
  sl.registerLazySingleton(() => NavigationService());

  // Services that depend on other services/externals
  sl.registerLazySingleton(() => StartupService(sl())); // Startup Service
}
