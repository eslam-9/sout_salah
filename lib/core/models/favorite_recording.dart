import 'package:equatable/equatable.dart';

/// Model to store favorite recording data locally
class FavoriteRecording extends Equatable {
  final String recordingId;
  final String localAudioPath; // Empty if not downloaded
  final String audioUrl; // URL for streaming
  final String prayerName;
  final String sheikhName;
  final String mosqueId;
  final String dayId;
  final int? fileSize; // in bytes, null if not downloaded
  final DateTime savedAt;

  const FavoriteRecording({
    required this.recordingId,
    required this.localAudioPath,
    required this.audioUrl,
    required this.prayerName,
    required this.sheikhName,
    required this.mosqueId,
    required this.dayId,
    this.fileSize,
    required this.savedAt,
  });

  /// Convert to JSON for storage in shared_preferences
  Map<String, dynamic> toJson() {
    return {
      'recordingId': recordingId,
      'localAudioPath': localAudioPath,
      'audioUrl': audioUrl,
      'prayerName': prayerName,
      'sheikhName': sheikhName,
      'mosqueId': mosqueId,
      'dayId': dayId,
      'fileSize': fileSize,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  /// Create from JSON stored in shared_preferences
  factory FavoriteRecording.fromJson(Map<String, dynamic> json) {
    return FavoriteRecording(
      recordingId: json['recordingId'] as String,
      localAudioPath: json['localAudioPath'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      prayerName: json['prayerName'] as String,
      sheikhName: json['sheikhName'] as String,
      mosqueId: json['mosqueId'] as String,
      dayId: json['dayId'] as String,
      fileSize: json['fileSize'] as int?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    recordingId,
    localAudioPath,
    audioUrl,
    prayerName,
    sheikhName,
    mosqueId,
    dayId,
    fileSize,
    savedAt,
  ];
}
