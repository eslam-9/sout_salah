import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import 'mosque_data_providers.dart';
import 'mosque_location_picker_state.dart';

final mosqueLocationPickerProvider = AsyncNotifierProvider.autoDispose<MosqueLocationPickerNotifier, MosqueLocationPickerState>(
  MosqueLocationPickerNotifier.new,
);

class MosqueLocationPickerNotifier extends AutoDisposeAsyncNotifier<MosqueLocationPickerState> {
  @override
  FutureOr<MosqueLocationPickerState> build() {
    return MosqueLocationPickerState.idle();
  }

  Future<void> requestCurrentLocation() async {
    state = AsyncValue.data(MosqueLocationPickerState.loading());

    final getCurrentLocationUseCase = ref.read(getCurrentLocationUseCaseProvider);
    final result = await getCurrentLocationUseCase(NoParams());

    result.fold(
      (failure) {
        LocationPickerStatus errorStatus;
        if (failure is LocationPermissionDeniedFailure) {
          errorStatus = LocationPickerStatus.permissionDenied;
        } else if (failure is LocationPermissionPermanentlyDeniedFailure) {
          errorStatus = LocationPickerStatus.permissionPermanentlyDenied;
        } else if (failure is LocationServiceDisabledFailure) {
          errorStatus = LocationPickerStatus.serviceDisabled;
        } else {
          errorStatus = LocationPickerStatus.error;
        }
        state = AsyncValue.data(MosqueLocationPickerState.error(errorStatus, failure.message));
      },
      (mosqueLocation) {
        state = AsyncValue.data(MosqueLocationPickerState.success(mosqueLocation));
      },
    );
  }

  void clearLocation() {
    state = AsyncValue.data(MosqueLocationPickerState.idle());
  }
}
