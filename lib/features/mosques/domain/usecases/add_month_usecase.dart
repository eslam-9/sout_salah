import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/mosque_repository.dart';

class AddMonthParams {
  final String mosqueId;
  final int month;
  final int year;

  const AddMonthParams({
    required this.mosqueId,
    required this.month,
    required this.year,
  });
}

class AddMonthUseCase implements UseCase<void, AddMonthParams> {
  final MosqueRepository repository;

  AddMonthUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddMonthParams params) async {
    return await repository.addMonth(
      mosqueId: params.mosqueId,
      month: params.month,
      year: params.year,
    );
  }
}
