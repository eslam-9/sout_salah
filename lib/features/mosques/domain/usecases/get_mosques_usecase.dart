import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mosque.dart';
import '../repositories/mosque_repository.dart';

class GetMosquesParams {
  final int? limit;
  final int? offset;

  GetMosquesParams({this.limit, this.offset});
}

class GetMosquesUseCase implements UseCase<List<Mosque>, GetMosquesParams> {
  final MosqueRepository repository;

  GetMosquesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Mosque>>> call(GetMosquesParams params) async {
    return await repository.getMosques(limit: params.limit, offset: params.offset);
  }
}
