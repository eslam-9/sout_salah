import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? username,
  });
  Future<Either<Failure, User>> signInAnonymously();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User>> getCurrentUser();
}
