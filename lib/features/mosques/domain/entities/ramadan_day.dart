import 'package:equatable/equatable.dart';

class RamadanDay extends Equatable {
  final String id;
  final String mosqueId;
  final int dayNumber;
  final String status; // 'red', 'yellow', 'green'
  final bool active;

  const RamadanDay({
    required this.id,
    required this.mosqueId,
    required this.dayNumber,
    required this.status,
    required this.active,
  });

  @override
  List<Object?> get props => [id, mosqueId, dayNumber, status, active];
}
