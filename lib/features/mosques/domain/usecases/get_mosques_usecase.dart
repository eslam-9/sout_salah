import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mosque.dart';
import '../repositories/mosque_repository.dart';

class GetMosquesParams {

  GetMosquesParams({this.limit, this.offset});
  final int? limit;
  final int? offset;
}

class GetMosquesUseCase implements UseCase<List<Mosque>, GetMosquesParams> {

  GetMosquesUseCase(this.repository);
  final MosqueRepository repository;

  @override
  Future<Either<Failure, List<Mosque>>> call(GetMosquesParams params) async {
    return await repository.getMosques(limit: params.limit, offset: params.offset);
  }
}
