import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../utils/app_logger.dart';
import '../services/navigation_service.dart';
import '../services/r2_storage_service.dart';
import '../services/downloads_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../services/startup_service.dart';

// Import Feature Data Sources
import '../../features/mosques/data/datasources/mosque_remote_data_source.dart';

// Import Feature Repositories
import '../../features/mosques/domain/repositories/mosque_repository.dart';
import '../../features/mosques/data/repositories/mosque_repository_impl.dart';

// Import Feature Use Cases
import '../../features/mosques/domain/usecases/get_mosques_usecase.dart';
import '../../features/mosques/domain/usecases/get_ramadan_days_usecase.dart';
import '../../features/mosques/domain/usecases/get_day_recordings_usecase.dart';
import '../../features/mosques/domain/usecases/upload_recording_usecase.dart';
import '../../features/mosques/domain/usecases/delete_recording_usecase.dart';
import '../../features/mosques/domain/usecases/add_mosque_usecase.dart';

// Import Auth Feature (assuming existing structure, adjusting as needed)
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/domain/usecases/sign_in_anonymously_usecase.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(
    () => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    ),
  );

  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  // 2. Core Services
  sl.registerLazySingleton(() => AppLogger());
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => R2StorageService());

  // Services that depend on other services/externals
  sl.registerLazySingleton(() => DownloadsService(sl(), sl(), sl()));
  sl.registerLazySingleton(() => AudioPlayerService());
  sl.registerLazySingleton(() => FavoritesService(sl(), sl()));
  sl.registerLazySingleton(() => StartupService(sl())); // Startup Service

  // 3. Features - Auth
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl(), sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  // sl.registerLazySingleton(() => VerifyOtpUseCase(sl())); // File missing
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignInAnonymouslyUseCase(sl()));

  // 4. Features - Mosques
  // Data Sources
  sl.registerLazySingleton<MosqueRemoteDataSource>(
    () => MosqueRemoteDataSourceImpl(sl(), sl(), sl()),
  );

  // Repositories
  sl.registerLazySingleton<MosqueRepository>(
    () => MosqueRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetMosquesUseCase(sl()));
  sl.registerLazySingleton(() => GetRamadanDaysUseCase(sl()));
  sl.registerLazySingleton(() => GetDayRecordingsUseCase(sl()));
  sl.registerLazySingleton(() => UploadRecordingUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRecordingUseCase(sl()));
  sl.registerLazySingleton(() => AddMosqueUseCase(sl()));
}
