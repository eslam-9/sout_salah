import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque.dart';
import '../entities/ramadan_day.dart';
import '../entities/recording.dart';
import '../entities/prayer.dart';

abstract class MosqueRepository {
  Future<Either<Failure, List<Mosque>>> getMosques();
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(String mosqueId);
  Future<Either<Failure, List<Recording>>> getDayRecordings(String dayId);
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  });

  Future<Either<Failure, Recording>> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  });

  Future<Either<Failure, void>> deleteRecording(String recordingId);
  Future<Either<Failure, void>> addPublisher(String mosqueId, String email);
}
