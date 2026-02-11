import '../../domain/entities/mosque.dart';

class MosqueModel extends Mosque {
  const MosqueModel({
    required super.id,
    required super.name,
    super.description,
    super.location,
    super.adminId,
    super.recordingCount,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    // Extract count from Supabase response which might look like:
    // "recordings": [{"count": 123}] or just a number if using a view/function
    // When using .select('*, recordings(count)'), it returns a list with one object
    int count = 0;
    if (json['recordings'] != null && json['recordings'] is List) {
      final list = json['recordings'] as List;
      if (list.isNotEmpty && list.first is Map) {
        count = list.first['count'] ?? 0;
      }
    }

    return MosqueModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      adminId: json['admin_id'],
      recordingCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'admin_id': adminId,
      // We generally don't send recordingCount back to server this way
    };
  }
}
