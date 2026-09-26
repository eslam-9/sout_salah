import 'package:equatable/equatable.dart';

class User extends Equatable {

  const User({
    required this.id,
    required this.email,
    this.username,
    this.role,
    this.mosqueId,
  });
  final String id;
  final String email;
  final String? username;
  final String? role;
  final String? mosqueId;

  @override
  List<Object?> get props => [id, email, username, role, mosqueId];
}
