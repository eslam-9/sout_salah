import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {

  AuthRepositoryImpl({required this.remoteDataSource});
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return executeWithCatch(() async {
      final user = await remoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      );
      return user;
    });
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? username,
  }) {
    return executeWithCatch(() async {
      final user = await remoteDataSource.signUp(
        email: email,
        password: password,
        username: username,
      );
      return user;
    });
  }

  @override
  Future<Either<Failure, User>> signInAnonymously() {
    return executeWithCatch(() async {
      final user = await remoteDataSource.signInAnonymously();
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> signOut() {
    return executeWithCatch(() async {
      await remoteDataSource.signOut();
    });
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() {
    return executeWithCatch(() async {
      final user = await remoteDataSource.getCurrentUser();
      if (user != null) {
        return user;
      }
      throw const ServerFailure(message: 'User not found');
    });
  }

  @override
  Future<Either<Failure, User>> updateProfile(
    String userId, {
    String? username,
  }) {
    return executeWithCatch(() async {
      final user = await remoteDataSource.updateProfile(
        userId,
        username: username,
      );
      return user;
    });
  }
}
