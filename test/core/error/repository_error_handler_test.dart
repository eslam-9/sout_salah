import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:sout_salah/core/error/exceptions.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/error/repository_error_handler.dart';

void main() {
  group('executeWithCatch', () {
    test('should return Right with data when action succeeds', () async {
      final result = await executeWithCatch(() async {
        return 'success';
      });

      expect(result, const Right('success'));
    });

    test('should return Left(NetworkFailure) on NetworkException', () async {
      final result = await executeWithCatch(() async {
        throw NetworkException('no internet');
      });

      expect(result, isA<Left<Failure, dynamic>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'no internet');
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return Left(AuthFailure) on AppAuthException', () async {
      final result = await executeWithCatch(() async {
        throw AppAuthException('auth failed');
      });

      expect(result, isA<Left<Failure, dynamic>>());
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'auth failed');
        },
        (_) => fail('Should return Left'),
      );
    });
    
    test('should return Left(ServerFailure) on unexpected Exception', () async {
      final result = await executeWithCatch(() async {
        throw Exception('unexpected error');
      });

      expect(result, isA<Left<Failure, dynamic>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'unexpected error');
        },
        (_) => fail('Should return Left'),
      );
    });
  });
}
