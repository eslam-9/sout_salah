import 'package:equatable/equatable.dart';

class SignUpParams extends Equatable {

  const SignUpParams({
    required this.email,
    required this.password,
    this.username,
  });
  final String email;
  final String password;
  final String? username;

  @override
  List<Object?> get props => [email, password, username];
}
