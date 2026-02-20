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

  const UploadRecordingParams({
    required this.mosqueId,
    required this.dayId,
    required this.prayer,
    required this.sheikhName,
    required this.filePath,
    required this.fileSize,
    this.duration,
  });

  @override
  List<Object?> get props => [
    mosqueId,
    dayId,
    prayer,
    sheikhName,
    filePath,
    fileSize,
    duration,
  ];
}
