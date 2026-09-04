import 'package:equatable/equatable.dart';
import '../entities/prayer.dart';

/// Parameters for uploading a recording
class UploadRecordingParams extends Equatable {
  final String mosqueId;
  final String dayId;
  final Prayer prayer;
  final String? customPrayerName;
  final String sheikhName;
  final String filePath;
  final int fileSize;
  final int? duration;
  final String? pendingRecordingId;

  const UploadRecordingParams({
    required this.mosqueId,
    required this.dayId,
    required this.prayer,
    this.customPrayerName,
    required this.sheikhName,
    required this.filePath,
    required this.fileSize,
    this.duration,
    this.pendingRecordingId,
  });

  UploadRecordingParams copyWith({
    String? mosqueId,
    String? dayId,
    Prayer? prayer,
    String? customPrayerName,
    String? sheikhName,
    String? filePath,
    int? fileSize,
    int? duration,
    String? pendingRecordingId,
  }) {
    return UploadRecordingParams(
      mosqueId: mosqueId ?? this.mosqueId,
      dayId: dayId ?? this.dayId,
      prayer: prayer ?? this.prayer,
      customPrayerName: customPrayerName ?? this.customPrayerName,
      sheikhName: sheikhName ?? this.sheikhName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      pendingRecordingId: pendingRecordingId ?? this.pendingRecordingId,
    );
  }

  @override
  List<Object?> get props => [
    mosqueId,
    dayId,
    prayer,
    customPrayerName,
    sheikhName,
    filePath,
    fileSize,
    duration,
    pendingRecordingId,
  ];
}
