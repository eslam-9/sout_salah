import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sout_salah/features/mosques/domain/entities/prayer.dart';
import 'package:sout_salah/features/mosques/domain/entities/recording.dart';
import 'package:sout_salah/features/mosques/domain/entities/upload_state.dart';
import 'package:sout_salah/features/mosques/domain/usecases/upload_recording_params.dart';
import 'package:sout_salah/features/mosques/domain/usecases/upload_recording_usecase.dart';
import 'package:sout_salah/features/mosques/presentation/providers/mosque_data_providers.dart';
import 'package:sout_salah/features/mosques/presentation/providers/upload_recording_notifier.dart';

class MockUploadRecordingUseCase extends Mock implements UploadRecordingUseCase {}
class MockFile extends Mock implements File {}

void main() {
  late MockUploadRecordingUseCase mockUseCase;
  late MockFile mockFile;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const UploadRecordingParams(
        mosqueId: 'dummy_mosque',
        dayId: 'dummy_day',
        prayer: Prayer.fajr,
        customPrayerName: null,
        sheikhName: 'dummy_sheikh',
        filePath: 'dummy_path',
        fileSize: 100,
        pendingRecordingId: null,
      ),
    );
  });

  setUp(() {
    mockUseCase = MockUploadRecordingUseCase();
    mockFile = MockFile();

    container = ProviderContainer(
      overrides: [
        uploadRecordingUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('UploadRecordingNotifier', () {
    test('initial state should be UploadInitial', () {
      final state = container.read(uploadRecordingNotifierProvider);
      expect(state, isA<UploadInitial>());
    });

    test('startUpload should yield states from the usecase stream', () async {
      when(() => mockFile.length()).thenAnswer((_) async => 1024);
      when(() => mockFile.path).thenReturn('/path/to/file.mp3');

      final tRecording = Recording(
        id: 'rec1',
        mosqueId: 'mosque1',
        dayId: 'day1',
        publisherId: 'pub1',
        prayer: Prayer.fajr,
        sheikhName: 'Sheikh Eslam',
        audioUrl: 'https://audio.mp3',
        createdAt: DateTime.now(),
      );

      final stream = Stream<UploadState>.fromIterable([
        const UploadProgress(0.5),
        UploadSuccess(tRecording),
      ]);

      when(() => mockUseCase.call(any())).thenAnswer((_) => stream);

      final notifier = container.read(uploadRecordingNotifierProvider.notifier);
      
      final states = <UploadState>[];
      container.listen(
        uploadRecordingNotifierProvider,
        (previous, next) {
          states.add(next);
        },
        fireImmediately: false,
      );

      await Future(() => notifier.startUpload(
        selectedFile: mockFile,
        selectedPrayer: Prayer.fajr,
        mosqueId: 'mosque1',
        dayId: 'day1',
        pendingRecordingId: null,
        customPrayerName: '',
        sheikhName: 'Sheikh Eslam',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<UploadProgress>());
      expect((states[0] as UploadProgress).progress, 0.5);
      expect(states[1], isA<UploadSuccess>());
      expect((states[1] as UploadSuccess).recording, tRecording);

      verify(() => mockUseCase.call(any(that: isA<UploadRecordingParams>()))).called(1);
    });

    test('startUpload should properly pass customPrayerName only if it differs from englishName', () async {
      when(() => mockFile.length()).thenAnswer((_) async => 2048);
      when(() => mockFile.path).thenReturn('/path/to/file2.mp3');

      final tRecording = Recording(
        id: 'rec2',
        mosqueId: 'mosque1',
        dayId: 'day1',
        publisherId: 'pub1',
        prayer: Prayer.other,
        sheikhName: 'Sheikh Ali',
        audioUrl: 'https://audio.mp3',
        createdAt: DateTime.now(),
      );

      final stream = Stream<UploadState>.fromIterable([
        UploadSuccess(tRecording),
      ]);

      when(() => mockUseCase.call(any())).thenAnswer((_) => stream);

      final notifier = container.read(uploadRecordingNotifierProvider.notifier);
      
      await Future(() => notifier.startUpload(
        selectedFile: mockFile,
        selectedPrayer: Prayer.other,
        mosqueId: 'mosque1',
        dayId: 'day1',
        pendingRecordingId: null,
        customPrayerName: 'Qiyam',
        sheikhName: 'Sheikh Ali',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      final captured = verify(() => mockUseCase.call(captureAny())).captured;
      final params = captured.first as UploadRecordingParams;
      
      expect(params.prayer, Prayer.other);
      expect(params.customPrayerName, 'Qiyam');
      expect(params.sheikhName, 'Sheikh Ali');
      expect(params.filePath, '/path/to/file2.mp3');
      expect(params.fileSize, 2048);
    });
  });
}
