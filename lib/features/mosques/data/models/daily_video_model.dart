import '../../domain/entities/daily_video.dart';

class DailyVideoModel extends DailyVideo {
  const DailyVideoModel({
    required super.id,
    required super.mosqueId,
    required super.dayId,
    super.publisherId,
    required super.videoUrl,
    super.title,
    super.description,
    required super.createdAt,
  });

  factory DailyVideoModel.fromJson(Map<String, dynamic> json) {
    return DailyVideoModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      dayId: json['day_id'] as String,
      publisherId: json['publisher_id'] as String?,
      videoUrl: json['video_url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mosque_id': mosqueId,
      'day_id': dayId,
      'publisher_id': publisherId,
      'video_url': videoUrl,
      'title': title,
      'description': description,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
