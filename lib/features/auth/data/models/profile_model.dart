import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    super.email,
    super.username,
    super.role,
    required super.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      role: json['role'] != null
          ? UserRole.fromString(json['role'] as String)
          : UserRole.listener,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
