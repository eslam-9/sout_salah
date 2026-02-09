import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.mosqueId,
    required super.dayId,
    super.publisherId,
    required super.prayerName,
    super.sheikhName,
    required super.audioUrl,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'],
      mosqueId: json['mosque_id'],
      dayId: json['day_id'],
      publisherId: json['publisher_id'],
      prayerName: json['prayer_name'],
      sheikhName: json['sheikh_name'],
      audioUrl: json['audio_url'],
    );
  }
}
