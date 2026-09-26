import 'package:equatable/equatable.dart';

class RamadanDay extends Equatable {

  const RamadanDay({
    required this.id,
    required this.mosqueId,
    required this.dayNumber,
    required this.status,
    required this.active,
    required this.month,
    required this.year,
  });
  final String id;
  final String mosqueId;
  final int dayNumber;
  final String status; // 'red', 'yellow', 'green'
  final bool active;
  final int month;
  final int year;

  RamadanDay copyWith({
    String? id,
    String? mosqueId,
    int? dayNumber,
    String? status,
    bool? active,
    int? month,
    int? year,
  }) {
    return RamadanDay(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      dayNumber: dayNumber ?? this.dayNumber,
      status: status ?? this.status,
      active: active ?? this.active,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  List<Object?> get props => [
    id,
    mosqueId,
    dayNumber,
    status,
    active,
    month,
    year,
  ];
}
