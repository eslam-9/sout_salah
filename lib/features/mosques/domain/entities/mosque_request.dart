import 'package:equatable/equatable.dart';

class MosqueRequest extends Equatable {
  final String id;
  final String name;
  final String location;
  final String? description;
  final String requestedBy;
  final String status;
  final DateTime createdAt;

  const MosqueRequest({
    required this.id,
    required this.name,
    required this.location,
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
        description,
        requestedBy,
        status,
        createdAt,
      ];
}
