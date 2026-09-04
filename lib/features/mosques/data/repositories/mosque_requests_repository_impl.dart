import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
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
    String? description,
  }) async {
    try {
      await remoteDataSource.createMosqueRequest(
        name: name,
        location: location,
        description: description,
      );
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MosqueRequest>>> getPendingRequests() async {
    try {
      final requests = await remoteDataSource.getPendingRequests();
      return Right(requests);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> acceptMosqueRequest(String requestId) async {
    try {
      await remoteDataSource.acceptMosqueRequest(requestId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> declineMosqueRequest(String requestId) async {
    try {
      await remoteDataSource.declineMosqueRequest(requestId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
