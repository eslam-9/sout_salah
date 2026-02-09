import 'package:equatable/equatable.dart';

class Mosque extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? adminId;

  const Mosque({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.adminId,
  });

  @override
  List<Object?> get props => [id, name, description, location, adminId];
}
