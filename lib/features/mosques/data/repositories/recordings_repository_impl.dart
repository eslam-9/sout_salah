import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/repositories/recordings_repository.dart';
import '../datasources/recordings_remote_data_source.dart';

class RecordingsRepositoryImpl implements RecordingsRepository {
  final RecordingsRemoteDataSource remoteDataSource;

  RecordingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Recording>>> getDayRecordings(String dayId) async {
    try {
      final recordings = await remoteDataSource.getDayRecordings(dayId);
      return Right(recordings);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Recording>> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  }) async {
    try {
      final recording = await remoteDataSource.uploadRecording(
        mosqueId: mosqueId,
        dayId: dayId,
        prayer: prayer,
        customPrayerName: customPrayerName,
        sheikhName: sheikhName,
        filePath: filePath,
        fileSize: fileSize,
        duration: duration,
        onProgress: onProgress,
      );
      return Right(recording);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecording(String recordingId) async {
    try {
      await remoteDataSource.deleteRecording(recordingId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Recording>> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  }) async {
    try {
      final recording = await remoteDataSource.createPendingRecording(
        mosqueId: mosqueId,
        dayId: dayId,
        prayerName: prayerName,
      );
      return Right(recording);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
