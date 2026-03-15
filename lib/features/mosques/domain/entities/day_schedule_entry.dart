import 'package:equatable/equatable.dart';

class DayScheduleEntry extends Equatable {
  final String id;
  final String dayId;
  final String mosqueId;
  final String salah;
  final String shikh;
  final String? comments;
  final int sortOrder;
  final DateTime createdAt;

  const DayScheduleEntry({
    required this.id,
    required this.dayId,
    required this.mosqueId,
    required this.salah,
    required this.shikh,
    this.comments,
    this.sortOrder = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    dayId,
    mosqueId,
    salah,
    shikh,
    comments,
    sortOrder,
    createdAt,
  ];
}
