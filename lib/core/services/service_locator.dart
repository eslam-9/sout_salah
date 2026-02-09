import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sout_salah/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sout_salah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sout_salah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sout_salah/features/auth/domain/usecases/auth_usecases.dart';
import 'package:sout_salah/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:sout_salah/features/auth/domain/usecases/sign_in_anonymously_usecase.dart';

import 'package:sout_salah/core/utils/app_logger.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Core
  sl.registerLazySingleton(() => AppLogger());
  // NetworkInfo implementation if needed

  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      signInAnonymouslyUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignInAnonymouslyUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl(), sl()),
  );

  //! External
  sl.registerLazySingleton(() => Supabase.instance.client);
  // sl.registerLazySingleton(() => InternetConnectionChecker()); // Commented out for now
}
