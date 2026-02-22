import '../../domain/entities/ramadan_day.dart';

class RamadanDayModel extends RamadanDay {
  const RamadanDayModel({
    required super.id,
    required super.mosqueId,
    required super.dayNumber,
    required super.status,
    required super.active,
  });

  factory RamadanDayModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['recordings'] != null && json['recordings'] is List) {
      final list = json['recordings'] as List;
      if (list.isNotEmpty && list.first is Map) {
        count = list.first['count'] ?? 0;
      }
    }

    String calculatedStatus = 'red';
    if (count >= 4) {
      calculatedStatus = 'green';
    } else if (count > 0) {
      calculatedStatus = 'yellow';
    } else {
      calculatedStatus = json['status'] ?? 'red';
    }

    return RamadanDayModel(
      id: json['id'],
      mosqueId: json['mosque_id'],
      dayNumber: json['day_number'],
      status: calculatedStatus,
      active: json['active'] ?? true,
    );
  }
}
