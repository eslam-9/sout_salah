import 'package:equatable/equatable.dart';

/// Model to store downloaded recording data locally
class DownloadedRecording extends Equatable {
  final String recordingId;
  final String localAudioPath;
  final String prayerName;
  final String sheikhName;
  final String mosqueId;
  final String dayId;
  final int? fileSize; // in bytes
  final DateTime downloadedAt;

  const DownloadedRecording({
    required this.recordingId,
    required this.localAudioPath,
    required this.prayerName,
    required this.sheikhName,
    required this.mosqueId,
    required this.dayId,
    this.fileSize,
    required this.downloadedAt,
  });

  /// Convert to JSON for storage in shared_preferences
  Map<String, dynamic> toJson() {
    return {
      'recordingId': recordingId,
      'localAudioPath': localAudioPath,
      'prayerName': prayerName,
      'sheikhName': sheikhName,
      'mosqueId': mosqueId,
      'dayId': dayId,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  /// Create from JSON stored in shared_preferences
  factory DownloadedRecording.fromJson(Map<String, dynamic> json) {
    return DownloadedRecording(
      recordingId: json['recordingId'] as String,
      localAudioPath: json['localAudioPath'] as String,
      prayerName: json['prayerName'] as String,
      sheikhName: json['sheikhName'] as String,
      mosqueId: json['mosqueId'] as String,
      dayId: json['dayId'] as String,
      fileSize: json['fileSize'] as int?,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    recordingId,
    localAudioPath,
    prayerName,
    sheikhName,
    mosqueId,
    dayId,
    fileSize,
    downloadedAt,
  ];
}
