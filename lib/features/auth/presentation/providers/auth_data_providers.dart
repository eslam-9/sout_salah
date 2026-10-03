import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/riverpod_providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/user_permission_service.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final userPermissionServiceProvider = Provider<UserPermissionService>((ref) {
  return const UserPermissionService();
});
