import '../../domain/entities/day_schedule_entry.dart';

class DayScheduleEntryModel extends DayScheduleEntry {
  const DayScheduleEntryModel({
    required super.id,
    required super.dayId,
    required super.mosqueId,
    required super.salah,
    required super.shikh,
    super.comments,
    super.sortOrder = 0,
    required super.createdAt,
  });

  factory DayScheduleEntryModel.fromJson(Map<String, dynamic> json) {
    return DayScheduleEntryModel(
      id: json['id'] as String,
      dayId: json['day_id'] as String,
      mosqueId: json['mosque_id'] as String,
      salah: json['salah'] as String,
      shikh: json['shikh'] as String,
      comments: json['comments'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_id': dayId,
      'mosque_id': mosqueId,
      'salah': salah,
      'shikh': shikh,
      'comments': comments,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
