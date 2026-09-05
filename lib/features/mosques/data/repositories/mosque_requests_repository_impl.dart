import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_error_handler.dart';
import '../../domain/entities/mosque_request.dart';
import '../../domain/repositories/mosque_requests_repository.dart';
import '../datasources/mosque_requests_remote_data_source.dart';

class MosqueRequestsRepositoryImpl implements MosqueRequestsRepository {
  final MosqueRequestsRemoteDataSource remoteDataSource;

  MosqueRequestsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> createMosqueRequest({
    required String name,
    required String location,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    return executeWithCatch(() => remoteDataSource.createMosqueRequest(
      name: name,
      location: location,
      latitude: latitude,
      longitude: longitude,
      description: description,
    ));
  }

  @override
  Future<Either<Failure, List<MosqueRequest>>> getPendingRequests() async {
    return executeWithCatch(() => remoteDataSource.getPendingRequests());
  }

  @override
  Future<Either<Failure, void>> acceptMosqueRequest(String requestId) async {
    return executeWithCatch(() => remoteDataSource.acceptMosqueRequest(requestId));
  }

  @override
  Future<Either<Failure, void>> declineMosqueRequest(String requestId) async {
    return executeWithCatch(() => remoteDataSource.declineMosqueRequest(requestId));
  }
}
