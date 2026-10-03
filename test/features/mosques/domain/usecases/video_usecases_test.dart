import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sout_salah/features/mosques/domain/entities/daily_video.dart';
import 'package:sout_salah/features/mosques/domain/repositories/video_repository.dart';
import 'package:sout_salah/features/mosques/domain/usecases/delete_video_usecase.dart';
import 'package:sout_salah/features/mosques/domain/usecases/get_day_videos_usecase.dart';
import 'package:sout_salah/features/mosques/domain/usecases/upload_video_usecase.dart';

class MockVideoRepository extends Mock implements VideoRepository {}

void main() {
  late MockVideoRepository mockRepository;
  late GetDayVideosUseCase getDayVideosUseCase;
  late UploadVideoUseCase uploadVideoUseCase;
  late DeleteVideoUseCase deleteVideoUseCase;

  setUpAll(() {
    registerFallbackValue(
      DailyVideo(
        id: '1',
        mosqueId: 'm1',
        dayId: 'd1',
        videoUrl: 'url',
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(File('test.mp4'));
  });

  setUp(() {
    mockRepository = MockVideoRepository();
    getDayVideosUseCase = GetDayVideosUseCase(mockRepository);
    uploadVideoUseCase = UploadVideoUseCase(mockRepository);
    deleteVideoUseCase = DeleteVideoUseCase(mockRepository);
  });

  final tVideo = DailyVideo(
    id: '1',
    mosqueId: 'm1',
    dayId: 'd1',
    videoUrl: 'url',
    createdAt: DateTime.now(),
  );

  group('GetDayVideosUseCase', () {
    test('should get videos from the repository', () async {
      when(
        () => mockRepository.getVideosForDay(any()),
      ).thenAnswer((_) async => Right([tVideo]));

      final result = await getDayVideosUseCase('d1');

      expect(result, Right([tVideo]));
      verify(() => mockRepository.getVideosForDay('d1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('UploadVideoUseCase', () {
    test('should upload video to the repository', () async {
      final tFile = File('test.mp4');
      when(
        () => mockRepository.uploadVideo(
          videoFile: any(named: 'videoFile'),
          mosqueId: any(named: 'mosqueId'),
          dayId: any(named: 'dayId'),
          dayNumber: any(named: 'dayNumber'),
        ),
      ).thenAnswer((_) async => Right(tVideo));

      final result = await uploadVideoUseCase(
        UploadVideoParams(
          videoFile: tFile,
          mosqueId: 'm1',
          dayId: 'd1',
          dayNumber: 1,
        ),
      );

      expect(result, Right(tVideo));
      verify(
        () => mockRepository.uploadVideo(
          videoFile: tFile,
          mosqueId: 'm1',
          dayId: 'd1',
          dayNumber: 1,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('DeleteVideoUseCase', () {
    test('should delete video using the repository', () async {
      when(
        () => mockRepository.deleteVideo(any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await deleteVideoUseCase(tVideo);

      expect(result, const Right(null));
      verify(() => mockRepository.deleteVideo(tVideo)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
