import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.mosqueId,
    required super.dayId,
    super.publisherId,
    required super.prayer,
    required super.sheikhName,
    required super.audioUrl,
    super.fileSize,
    super.duration,
    required super.createdAt,
    super.customPrayerName,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    final prayerName = json['prayer_name'] as String;
    final prayer = Prayer.fromString(prayerName);

    return RecordingModel(
      id: json['id'] as String,
      mosqueId: json['mosque_id'] as String,
      dayId: json['day_id'] as String,
      publisherId: json['publisher_id'] as String?,
      prayer: prayer,
      customPrayerName: prayer == Prayer.other ? prayerName : null,
      sheikhName: json['sheikh_name'] as String? ?? 'غير معروف',
      audioUrl: json['audio_url'] as String,
      fileSize: json['file_size'] as int?,
      duration: json['duration'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mosque_id': mosqueId,
      'day_id': dayId,
      'publisher_id': publisherId,
      'prayer_name': prayer == Prayer.other
          ? customPrayerName
          : prayer.englishName,
      'sheikh_name': sheikhName,
      'audio_url': audioUrl,
      'file_size': fileSize,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
