import 'package:equatable/equatable.dart';

/// User roles in the application
/// Note: Roles are per-mosque for admin and publisher
enum UserRole {
  /// Super admin (not currently used, reserved for future)
  superAdmin('admin'),

  /// Mosque admin - creator of a mosque
  mosqueAdmin('mosque_admin'),

  /// Publisher - can upload recordings to assigned mosques
  publisher('publisher'),

  /// Normal user/listener - can view and listen only
  listener('listener');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.superAdmin;
      case 'mosque_admin':
        return UserRole.mosqueAdmin;
      case 'publisher':
        return UserRole.publisher;
      case 'listener':
      default:
        return UserRole.listener;
    }
  }
}

/// Profile entity representing a user profile
class Profile extends Equatable {
  final String id;
  final String? email;
  final String? username;
  final UserRole role;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.email,
    this.username,
    this.role = UserRole.listener,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, username, role, createdAt];

  Profile copyWith({
    String? id,
    String? email,
    String? username,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
