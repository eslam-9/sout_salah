import '../../domain/entities/mosque.dart';

class MosqueModel extends Mosque {
  const MosqueModel({
    required super.id,
    required super.name,
    super.description,
    super.location,
    super.adminId,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      adminId: json['admin_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'admin_id': adminId,
    };
  }
}
