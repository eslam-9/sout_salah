import 'package:equatable/equatable.dart';

class DailyVideo extends Equatable {
  const DailyVideo({
    required this.id,
    required this.mosqueId,
    required this.dayId,
    this.publisherId,
    required this.videoUrl,
    this.title,
    this.description,
    required this.createdAt,
  });
  
  final String id;
  final String mosqueId;
  final String dayId;
  final String? publisherId;
  final String videoUrl;
  final String? title;
  final String? description;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        mosqueId,
        dayId,
        publisherId,
        videoUrl,
        title,
        description,
        createdAt,
      ];
}
