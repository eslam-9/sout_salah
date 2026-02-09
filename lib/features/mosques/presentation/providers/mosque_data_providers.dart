import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/mosque_remote_data_source.dart';
import '../../data/repositories/mosque_repository_impl.dart';
import '../../domain/repositories/mosque_repository.dart';

final mosqueRemoteDataSourceProvider = Provider<MosqueRemoteDataSource>((ref) {
  return MosqueRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(appLoggerProvider),
  );
});

final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepositoryImpl(
    remoteDataSource: ref.watch(mosqueRemoteDataSourceProvider),
  );
});
