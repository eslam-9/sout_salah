import 'package:equatable/equatable.dart';

class Mosque extends Equatable {

  const Mosque({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.adminId,
    this.recordingCount = 0,
  });
  final String id;
  final String name;
  final String? description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? adminId;
  final int recordingCount;

  Mosque copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? adminId,
    int? recordingCount,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adminId: adminId ?? this.adminId,
      recordingCount: recordingCount ?? this.recordingCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    location,
    latitude,
    longitude,
    adminId,
    recordingCount,
  ];
}
