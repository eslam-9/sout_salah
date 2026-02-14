import 'package:equatable/equatable.dart';
import 'prayer.dart';

class Recording extends Equatable {
  final String id;
  final String mosqueId;
  final String dayId;
  final String? publisherId;
  final Prayer prayer;
  final String? customPrayerName;
  final String sheikhName;
  final String audioUrl;
  final int? fileSize; // in bytes
  final int? duration; // in seconds
  final DateTime createdAt;

  const Recording({
    required this.id,
    required this.mosqueId,
    required this.dayId,
    this.publisherId,
    required this.prayer,
    this.customPrayerName,
    required this.sheikhName,
    required this.audioUrl,
    this.fileSize,
    this.duration,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    mosqueId,
    dayId,
    publisherId,
    prayer,
    customPrayerName,
    sheikhName,
    audioUrl,
    fileSize,
    duration,
    createdAt,
  ];
}
