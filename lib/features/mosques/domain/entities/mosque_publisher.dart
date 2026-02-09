import 'package:equatable/equatable.dart';

/// Represents a mosque publisher relationship
/// Links a user (publisher) to a mosque they can upload recordings for
class MosquePublisher extends Equatable {
  final String id;
  final String mosqueId;
  final String publisherId;
  final String addedBy; // Admin who added them
  final DateTime createdAt;

  const MosquePublisher({
    required this.id,
    required this.mosqueId,
    required this.publisherId,
    required this.addedBy,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, mosqueId, publisherId, addedBy, createdAt];
}
