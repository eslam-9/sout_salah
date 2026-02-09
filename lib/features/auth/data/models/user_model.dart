import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.role,
    super.mosqueId,
  });

  factory UserModel.fromSupabase(
    supabase.User user, {
    Map<String, dynamic>? profileData,
  }) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: profileData?['username'],
      role: profileData?['role'],
      mosqueId: profileData?['mosque_id'],
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'],
      role: json['role'],
      mosqueId: json['mosque_id'],
    );
  }
}
