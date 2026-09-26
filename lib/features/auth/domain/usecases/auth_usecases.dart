import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import 'sign_up_params.dart';

class UpdateProfileParams extends Equatable {

  const UpdateProfileParams({required this.userId, this.username});
  final String userId;
  final String? username;

  @override
  List<Object?> get props => [userId, username];
}

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {

  UpdateProfileUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      params.userId,
      username: params.username,
    );
  }
}

class SignInParams extends Equatable {

  const SignInParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class SignInUseCase implements UseCase<User, SignInParams> {

  SignInUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    return await repository.signInWithEmailAndPassword(
      params.email,
      params.password,
    );
  }
}

class SignUpUseCase implements UseCase<User, SignUpParams> {

  SignUpUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      username: params.username,
    );
  }
}

class SignOutUseCase implements UseCase<void, NoParams> {

  SignOutUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}

class GetCurrentUserUseCase implements UseCase<User, NoParams> {

  GetCurrentUserUseCase(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
