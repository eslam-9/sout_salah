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
    return RamadanDayModel(
      id: json['id'],
      mosqueId: json['mosque_id'],
      dayNumber: json['day_number'],
      status: json['status'] ?? 'red',
      active: json['active'] ?? true,
    );
  }
}
