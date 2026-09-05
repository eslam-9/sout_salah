import 'package:equatable/equatable.dart';
import '../../domain/entities/mosque_location.dart';

enum LocationPickerStatus {
  idle,
  loading,
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  unavailable,
  error
}

class MosqueLocationPickerState extends Equatable {
  final LocationPickerStatus status;
  final MosqueLocation? mosqueLocation;
  final String? errorMessage;

  const MosqueLocationPickerState({
    required this.status,
    this.mosqueLocation,
    this.errorMessage,
  });

  factory MosqueLocationPickerState.idle() {
    return const MosqueLocationPickerState(status: LocationPickerStatus.idle);
  }

  factory MosqueLocationPickerState.loading() {
    return const MosqueLocationPickerState(status: LocationPickerStatus.loading);
  }

  factory MosqueLocationPickerState.success(MosqueLocation location) {
    return MosqueLocationPickerState(
      status: LocationPickerStatus.success,
      mosqueLocation: location,
    );
  }

  factory MosqueLocationPickerState.error(LocationPickerStatus status, [String? message]) {
    return MosqueLocationPickerState(
      status: status,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [status, mosqueLocation, errorMessage];
}
