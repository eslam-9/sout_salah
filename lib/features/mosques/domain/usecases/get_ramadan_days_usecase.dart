import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ramadan_day.dart';
import '../repositories/ramadan_days_repository.dart';

class GetRamadanDaysParams {
  final String mosqueId;
  final int? month;
  final int? year;

  const GetRamadanDaysParams({required this.mosqueId, this.month, this.year});
}

class GetRamadanDaysUseCase
    implements UseCase<List<RamadanDay>, GetRamadanDaysParams> {
  final RamadanDaysRepository repository;

  GetRamadanDaysUseCase(this.repository);

  @override
  Future<Either<Failure, List<RamadanDay>>> call(
    GetRamadanDaysParams params,
  ) async {
    return await repository.getRamadanDays(
      params.mosqueId,
      month: params.month,
      year: params.year,
    );
  }
}
