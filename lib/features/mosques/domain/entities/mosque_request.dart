import 'package:equatable/equatable.dart';

class MosqueRequest extends Equatable {
  final String id;
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String requestedBy;
  final String status;
  final DateTime createdAt;

  const MosqueRequest({
    required this.id,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        latitude,
        longitude,
        description,
        requestedBy,
        status,
        createdAt,
      ];
}
