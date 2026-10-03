import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sout_salah/core/services/favorites_service.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:sout_salah/features/mosques/domain/entities/recording.dart';
import 'package:sout_salah/features/mosques/domain/entities/prayer.dart';

class MockAppLogger extends Mock implements AppLogger {}

Recording _makeRecording({String id = 'rec-1'}) => Recording(
  id: id,
  mosqueId: 'mosque-1',
  dayId: 'day-1',
  prayer: Prayer.fajr,
  sheikhName: 'Test Sheikh',
  audioUrl: 'https://example.com/audio.mp3',
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  late FavoritesService sut;
  late MockAppLogger mockLogger;
  late SharedPreferences prefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // path_provider has no platform channel in unit tests — stub it so
    // addFavorite (which checks the downloads directory) can run.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') return '/tmp';
        return null;
      },
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockLogger = MockAppLogger();
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.e(any(), any(), any())).thenReturn(null);
    sut = FavoritesService(prefs, mockLogger);
  });

  tearDown(() => sut.dispose());

  group('getFavorites', () {
    test('returns empty list initially', () async {
      expect(await sut.getFavorites(), isEmpty);
    });
  });

  group('isFavorite', () {
    test('returns false when not favorited', () async {
      expect(await sut.isFavorite('rec-1'), isFalse);
    });
  });

  group('addFavorite', () {
    test('adds a recording to favorites', () async {
      await sut.addFavorite(_makeRecording());
      expect(await sut.isFavorite('rec-1'), isTrue);
      expect(await sut.getFavorites(), hasLength(1));
    });

    test('does not add duplicate favorites', () async {
      await sut.addFavorite(_makeRecording());
      await sut.addFavorite(_makeRecording()); // same id
      expect(await sut.getFavorites(), hasLength(1));
    });
  });

  group('removeFavorite', () {
    test('removes an existing favorite', () async {
      await sut.addFavorite(_makeRecording());
      await sut.removeFavorite('rec-1');
      expect(await sut.isFavorite('rec-1'), isFalse);
    });

    test('throws when recording not in favorites', () async {
      await expectLater(
        sut.removeFavorite('non-existent'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('favoritesStream', () {
    test('emits list when listened', () async {
      await expectLater(sut.favoritesStream, emits(isA<List>()));
    });
  });
}
