import 'package:equatable/equatable.dart';
import 'prayer.dart';

class Recording extends Equatable {

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

  Recording copyWith({
    String? id,
    String? mosqueId,
    String? dayId,
    String? publisherId,
    Prayer? prayer,
    String? customPrayerName,
    String? sheikhName,
    String? audioUrl,
    int? fileSize,
    int? duration,
    DateTime? createdAt,
  }) {
    return Recording(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      dayId: dayId ?? this.dayId,
      publisherId: publisherId ?? this.publisherId,
      prayer: prayer ?? this.prayer,
      customPrayerName: customPrayerName ?? this.customPrayerName,
      sheikhName: sheikhName ?? this.sheikhName,
      audioUrl: audioUrl ?? this.audioUrl,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
