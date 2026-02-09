import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ramadan_day.dart';
import '../repositories/mosque_repository.dart';

class GetRamadanDaysParams {
  final String mosqueId;

  const GetRamadanDaysParams({required this.mosqueId});
}

class GetRamadanDaysUseCase
    implements UseCase<List<RamadanDay>, GetRamadanDaysParams> {
  final MosqueRepository repository;

  GetRamadanDaysUseCase(this.repository);

  @override
  Future<Either<Failure, List<RamadanDay>>> call(
    GetRamadanDaysParams params,
  ) async {
    return await repository.getRamadanDays(params.mosqueId);
  }
}
