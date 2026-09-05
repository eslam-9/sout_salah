import '../../domain/entities/mosque_request.dart';

class MosqueRequestModel extends MosqueRequest {
  const MosqueRequestModel({
    required super.id,
    required super.name,
    required super.location,
    super.latitude,
    super.longitude,
    super.description,
    required super.requestedBy,
    required super.status,
    required super.createdAt,
  });

  factory MosqueRequestModel.fromJson(Map<String, dynamic> json) {
    return MosqueRequestModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      description: json['description'],
      requestedBy: json['requested_by'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'requested_by': requestedBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    return map;
  }
}
