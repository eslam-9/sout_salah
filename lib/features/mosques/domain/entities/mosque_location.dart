import 'package:equatable/equatable.dart';

class MosqueLocation extends Equatable {

  const MosqueLocation({
    required this.latitude,
    required this.longitude,
    this.locationName,
  });
  final double latitude;
  final double longitude;
  final String? locationName;

  bool get isValid => latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  @override
  List<Object?> get props => [latitude, longitude, locationName];
}
