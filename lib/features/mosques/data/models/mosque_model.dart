import '../../domain/entities/mosque.dart';

class MosqueModel extends Mosque {
  const MosqueModel({
    required super.id,
    required super.name,
    super.latitude,
    super.longitude,
    super.description,
    super.location,
    super.adminId,
    super.recordingCount,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    int rCount = 0;
    if (json['recordings'] != null) {
      if (json['recordings'] is List && (json['recordings'] as List).isNotEmpty) {
        final countItem = (json['recordings'] as List).first;
        if (countItem is Map) {
          rCount = countItem['count'] ?? 0;
        }
      } else if (json['recordings'] is Map) {
        rCount = json['recordings']['count'] ?? 0;
      } else if (json['recordings'] is num) {
        rCount = (json['recordings'] as num).toInt();
      }
    } else if (json['recording_count'] != null) {
      rCount = (json['recording_count'] as num).toInt();
    }

    return MosqueModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      adminId: json['admin_id'],
      recordingCount: rCount,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'admin_id': adminId,
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    return map;
  }
}
