import '../../domain/entities/mosque_request.dart';

class MosqueRequestModel extends MosqueRequest {
  const MosqueRequestModel({
    required super.id,
    required super.name,
    required super.location,
    super.description,
    required super.requestedBy,
    required super.status,
    required super.createdAt,
  });

  factory MosqueRequestModel.fromJson(Map<String, dynamic> json) {
    return MosqueRequestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String?,
      requestedBy: json['requested_by'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'requested_by': requestedBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
