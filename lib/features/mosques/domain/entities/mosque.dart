import 'package:equatable/equatable.dart';

class Mosque extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? adminId;
  final int recordingCount;

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
