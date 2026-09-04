import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/mosque_request.dart';

abstract class MosqueRequestsRepository {
  Future<Either<Failure, void>> createMosqueRequest({
    required String name,
    required String location,
    String? description,
  });
  Future<Either<Failure, List<MosqueRequest>>> getPendingRequests();
  Future<Either<Failure, void>> acceptMosqueRequest(String requestId);
  Future<Either<Failure, void>> declineMosqueRequest(String requestId);
}
