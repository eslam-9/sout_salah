import '../../domain/entities/ramadan_day.dart';
import '../../domain/services/ramadan_status_service.dart';

class RamadanDayModel extends RamadanDay {
  const RamadanDayModel({
    required super.id,
    required super.mosqueId,
    required super.dayNumber,
    required super.status,
    required super.active,
    required super.month,
    required super.year,
  });

  factory RamadanDayModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['recordings'] != null && json['recordings'] is List) {
      final list = json['recordings'] as List;
      if (list.isNotEmpty && list.first is Map) {
        count = list.first['count'] ?? 0;
      }
    }

    String calculatedStatus = json['status'] ?? 'red';
    if (json.containsKey('recordings') && count > 0) {
      calculatedStatus = RamadanStatusService.computeStatus(count);
    }

    return RamadanDayModel(
      id: json['id'],
      mosqueId: json['mosque_id'],
      dayNumber: json['day_number'],
      status: calculatedStatus,
      active: json['active'] ?? true,
      month: json['month'] ?? 9,
      year: json['year'] ?? 1445,
    );
  }
}
