import 'package:equatable/equatable.dart';

class Recording extends Equatable {
  final String id;
  final String mosqueId;
  final String dayId;
  final String? publisherId;
  final String prayerName;
  final String? sheikhName;
  final String audioUrl;

  const Recording({
    required this.id,
    required this.mosqueId,
    required this.dayId,
    this.publisherId,
    required this.prayerName,
    this.sheikhName,
    required this.audioUrl,
  });

  @override
  List<Object?> get props => [
    id,
    mosqueId,
    dayId,
    publisherId,
    prayerName,
    sheikhName,
    audioUrl,
  ];
}
