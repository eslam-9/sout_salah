import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque.dart';

abstract class MosqueRepository {
  Future<Either<Failure, List<Mosque>>> getMosques({int? limit, int? offset});
  Future<Either<Failure, Mosque>> addMosque({
    required String name,
    required String location,
    String? description,
  });
  Future<Either<Failure, void>> addPublisher(String mosqueId, String email);
}
