import 'package:equatable/equatable.dart';
import '../entities/prayer.dart';

/// Parameters for uploading a recording
class UploadRecordingParams extends Equatable {
  final String mosqueId;
  final String dayId;
  final Prayer prayer;
  final String sheikhName;
  final String filePath;
  final int fileSize;
  final int? duration;
  final void Function(double)? onProgress;

  const UploadRecordingParams({
    required this.mosqueId,
    required this.dayId,
    required this.prayer,
    required this.sheikhName,
    required this.filePath,
    required this.fileSize,
    this.duration,
    this.onProgress,
  });

  UploadRecordingParams copyWith({
    String? mosqueId,
    String? dayId,
    Prayer? prayer,
    String? sheikhName,
    String? filePath,
    int? fileSize,
    int? duration,
    void Function(double)? onProgress,
  }) {
    return UploadRecordingParams(
      mosqueId: mosqueId ?? this.mosqueId,
      dayId: dayId ?? this.dayId,
      prayer: prayer ?? this.prayer,
      sheikhName: sheikhName ?? this.sheikhName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      onProgress: onProgress ?? this.onProgress,
    );
  }

  @override
  List<Object?> get props => [
    mosqueId,
    dayId,
    prayer,
    sheikhName,
    filePath,
    fileSize,
    duration,
    onProgress,
  ];
}
