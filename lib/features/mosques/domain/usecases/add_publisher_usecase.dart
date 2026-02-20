import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/mosque_repository.dart';

class AddPublisherUseCase {
  final MosqueRepository repository;

  AddPublisherUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String mosqueId,
    required String email,
  }) async {
    return await repository.addPublisher(mosqueId, email);
  }
}
