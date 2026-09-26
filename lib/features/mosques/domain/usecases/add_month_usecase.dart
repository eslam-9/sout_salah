import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ramadan_days_repository.dart';

class AddMonthParams {

  const AddMonthParams({
    required this.mosqueId,
    required this.month,
    required this.year,
  });
  final String mosqueId;
  final int month;
  final int year;
}

class AddMonthUseCase implements UseCase<void, AddMonthParams> {

  AddMonthUseCase(this.repository);
  final RamadanDaysRepository repository;

  @override
  Future<Either<Failure, void>> call(AddMonthParams params) async {
    return await repository.addMonth(
      mosqueId: params.mosqueId,
      month: params.month,
      year: params.year,
    );
  }
}
