import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mosque.dart';
import '../repositories/mosque_repository.dart';

class AddMosqueParams extends Equatable {
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;

  const AddMosqueParams({
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
  });

  @override
  List<Object?> get props => [name, location, latitude, longitude, description];
}

class AddMosqueUseCase implements UseCase<Mosque, AddMosqueParams> {
  final MosqueRepository repository;

  AddMosqueUseCase(this.repository);

  @override
  Future<Either<Failure, Mosque>> call(AddMosqueParams params) async {
    return await repository.addMosque(
      name: params.name,
      location: params.location,
      description: params.description,
    );
  }
}
