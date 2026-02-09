import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque.dart';
import '../entities/ramadan_day.dart';

abstract class MosqueRepository {
  Future<Either<Failure, List<Mosque>>> getMosques();
  Future<Either<Failure, List<RamadanDay>>> getRamadanDays(String mosqueId);
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  });
  // Future<Either<Failure, List<Recording>>> getRecordings(String dayId); // For later
}
