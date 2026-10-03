import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/network/network_info.dart';
import 'package:sout_salah/core/network/retry_executor.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class TestClass with RetryExecutorMixin {}

void main() {
  late TestClass testClass;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    testClass = TestClass();
    mockNetworkInfo = MockNetworkInfo();
  });

  group('executeWithRetry', () {
    test('returns Right when operation is successful', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      final result = await testClass.executeWithRetry(
        () async => const Right('success'),
        networkInfo: mockNetworkInfo,
      );

      expect(result, const Right('success'));
    });

    test('returns Left(NetworkFailure) immediately if offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await testClass.executeWithRetry(
        () async => const Right('success'),
        networkInfo: mockNetworkInfo,
      );

      expect(result, isA<Left<Failure, dynamic>>());
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('retries on failure and returns Left after max attempts', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      int attempts = 0;
      final result = await testClass.executeWithRetry(
        () async {
          attempts++;
          return const Left(ServerFailure(message: 'server down'));
        },
        networkInfo: mockNetworkInfo,
      );

      expect(result, isA<Left<Failure, dynamic>>());
      expect(attempts, greaterThan(1));
    });
  });
}
