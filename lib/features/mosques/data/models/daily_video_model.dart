import 'package:equatable/equatable.dart';

class DailyVideoModel extends Equatable {
  final String id;
  final String mosqueId;
  final String dayId;
  final String? publisherId;
  final String videoUrl;
  final String? title;
  final String? description;
  final DateTime createdAt;

  const DailyVideoModel({
    required this.id,
    required this.mosqueId,
    required this.dayId,
    this.publisherId,
    required this.videoUrl,
    this.title,
    this.description,
    required this.createdAt,
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

  @override
  List<Object?> get props => [
        id,
        mosqueId,
        dayId,
        publisherId,
        videoUrl,
        title,
        description,
        createdAt,
      ];
}
