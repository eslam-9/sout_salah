import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sout_salah/core/error/exceptions.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sout_salah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sout_salah/features/auth/domain/entities/user.dart';
import 'package:sout_salah/features/auth/data/models/user_model.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tUserModel = UserModel(id: '123', email: 'test@test.com', username: 'Test User');
  const tUser = tUserModel;

  group('signInWithEmailAndPassword', () {
    const tEmail = 'test@test.com';
    const tPassword = 'password123';

    test('should return User when remote data source returns user', () async {
      when(() => mockRemoteDataSource.signInWithEmailAndPassword(tEmail, tPassword))
          .thenAnswer((_) async => tUserModel);

      final result = await repository.signInWithEmailAndPassword(tEmail, tPassword);

      expect(result, const Right(tUser));
      verify(() => mockRemoteDataSource.signInWithEmailAndPassword(tEmail, tPassword)).called(1);
    });

    test('should return ServerFailure when remote data source throws ServerException', () async {
      when(() => mockRemoteDataSource.signInWithEmailAndPassword(tEmail, tPassword))
          .thenThrow(ServerException('Invalid credentials'));

      final result = await repository.signInWithEmailAndPassword(tEmail, tPassword);

      expect(result, const Left(ServerFailure(message: 'Invalid credentials')));
    });
  });

  group('getCurrentUser', () {
    test('should return User when one is cached/found', () async {
      when(() => mockRemoteDataSource.getCurrentUser()).thenAnswer((_) async => tUserModel);

      final result = await repository.getCurrentUser();

      expect(result, const Right(tUser));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return ServerFailure when no user is found', () async {
      when(() => mockRemoteDataSource.getCurrentUser()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, const Left(ServerFailure(message: 'User not found')));
    });
  });
}
