import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sout_salah/core/services/downloads_service.dart';
import 'package:sout_salah/core/utils/app_logger.dart';

class MockDio extends Mock implements Dio {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late DownloadsService sut;
  late MockDio mockDio;
  late MockAppLogger mockLogger;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockDio = MockDio();
    mockLogger = MockAppLogger();

    // Stub logger methods to do nothing
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.e(any(), any(), any())).thenReturn(null);
    when(() => mockLogger.w(any())).thenReturn(null);

    sut = DownloadsService(prefs, mockDio, mockLogger);
  });

  tearDown(() => sut.dispose());

  group('getDownloads', () {
    test('returns empty list when no downloads stored', () async {
      final result = await sut.getDownloads();
      expect(result, isEmpty);
    });

    test('returns empty list when JSON is corrupt', () async {
      await prefs.setString('downloaded_recordings', 'not-valid-json');
      final result = await sut.getDownloads();
      expect(result, isEmpty);
    });
  });

  group('isDownloaded', () {
    test('returns false when recording not downloaded', () async {
      final result = await sut.isDownloaded('non-existent-id');
      expect(result, isFalse);
    });
  });

  group('cancelDownload', () {
    test('does nothing if recording is not downloading', () {
      // Should not throw
      expect(() => sut.cancelDownload('some-id'), returnsNormally);
    });
  });

  group('downloadsStream', () {
    test('emits a list when listened', () async {
      await expectLater(sut.downloadsStream, emits(isA<List>()));
    });
  });

  group('removeDownload', () {
    test('throws when recording not found', () async {
      await expectLater(
        sut.removeDownload('non-existent'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
