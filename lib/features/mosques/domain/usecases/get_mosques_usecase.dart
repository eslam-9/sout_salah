import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mosque.dart';
import '../repositories/mosque_repository.dart';

class GetMosquesUseCase implements UseCase<List<Mosque>, NoParams> {
  final MosqueRepository repository;

  GetMosquesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Mosque>>> call(NoParams params) async {
    return await repository.getMosques();
  }
}
