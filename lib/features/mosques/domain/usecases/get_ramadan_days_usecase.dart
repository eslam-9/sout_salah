import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ramadan_day.dart';
import '../repositories/ramadan_days_repository.dart';

class GetRamadanDaysParams {

  const GetRamadanDaysParams({required this.mosqueId, this.month, this.year});
  final String mosqueId;
  final int? month;
  final int? year;
}

class GetRamadanDaysUseCase
    implements UseCase<List<RamadanDay>, GetRamadanDaysParams> {

  GetRamadanDaysUseCase(this.repository);
  final RamadanDaysRepository repository;

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
