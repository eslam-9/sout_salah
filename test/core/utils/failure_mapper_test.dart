import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/utils/failure_mapper.dart';

void main() {
  group('mapFailureToMessage', () {
    test('maps NetworkFailure', () {
      expect(
        mapFailureToMessage(const NetworkFailure()),
        equals('لا يوجد اتصال بالإنترنت'),
      );
    });

    test('maps ServerFailure with custom message', () {
      expect(
        mapFailureToMessage(const ServerFailure(message: 'custom error')),
        equals('custom error'),
      );
    });

    test('maps AuthFailure', () {
      expect(
        mapFailureToMessage(const AuthFailure()),
        equals('خطأ في المصادقة'),
      );
    });

    test('maps CacheFailure', () {
      expect(
        mapFailureToMessage(CacheFailure()),
        equals('خطأ في التخزين المؤقت'),
      );
    });
  });
}
