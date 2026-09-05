import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/mosque_requests_repository.dart';
import '../entities/mosque_request.dart';
import 'package:equatable/equatable.dart';

class CreateMosqueRequestParams extends Equatable {
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;

  const CreateMosqueRequestParams({
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
  });

  @override
  List<Object?> get props => [name, location, latitude, longitude, description];
}

class CreateMosqueRequestUseCase implements UseCase<void, CreateMosqueRequestParams> {
  final MosqueRequestsRepository repository;

  CreateMosqueRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateMosqueRequestParams params) {
    return repository.createMosqueRequest(
      name: params.name,
      location: params.location,
      latitude: params.latitude,
      longitude: params.longitude,
      description: params.description,
    );
  }
}

class GetPendingRequestsUseCase implements UseCase<List<MosqueRequest>, NoParams> {
  final MosqueRequestsRepository repository;

  GetPendingRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MosqueRequest>>> call(NoParams params) {
    return repository.getPendingRequests();
  }
}

class AcceptMosqueRequestUseCase implements UseCase<void, String> {
  final MosqueRequestsRepository repository;

  AcceptMosqueRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.acceptMosqueRequest(requestId);
  }
}

class DeclineMosqueRequestUseCase implements UseCase<void, String> {
  final MosqueRequestsRepository repository;

  DeclineMosqueRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.declineMosqueRequest(requestId);
  }
}
