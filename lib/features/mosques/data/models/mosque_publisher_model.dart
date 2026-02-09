import '../../domain/entities/mosque_publisher.dart';

class MosquePublisherModel extends MosquePublisher {
  const MosquePublisherModel({
    required super.id,
    required super.mosqueId,
    required super.publisherId,
    required super.addedBy,
    required super.createdAt,
  });

  factory MosquePublisherModel.fromJson(Map<String, dynamic> json) {
    return MosquePublisherModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      publisherId: json['publisher_id'] as String,
      addedBy: json['added_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mosque_id': mosqueId,
      'publisher_id': publisherId,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
