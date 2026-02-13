import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/entities/ramadan_day.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../datasources/mosque_remote_data_source.dart';

class MosqueRepositoryImpl implements MosqueRepository {
  final MosqueRemoteDataSource remoteDataSource;

  MosqueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Mosque>>> getMosques() async {
    try {
      final remoteMosques = await remoteDataSource.getMosques();
      return Right(remoteMosques);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(
    String mosqueId,
  ) async {
    try {
      final remoteDays = await remoteDataSource.getRamadanDays(mosqueId);
      return Right(remoteDays);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    try {
      final mosque = await remoteDataSource.addMosque(
        name: name,
        location: location,
        description: description,
      );
      return Right(mosque);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Recording>>> getDayRecordings(
    String dayId,
  ) async {
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
  Future<Either<Failure, void>> addPublisher(
    String mosqueId,
    String email,
  ) async {
    try {
      await remoteDataSource.addPublisher(mosqueId, email);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
