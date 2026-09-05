import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mosque_request.dart';
import '../../domain/usecases/mosque_request_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/riverpod_providers.dart';
import 'mosque_data_providers.dart';

// --- UseCase Providers ---
final createMosqueRequestUseCaseProvider = Provider(
  (ref) =>
      CreateMosqueRequestUseCase(ref.watch(mosqueRequestsRepositoryProvider)),
);

final getPendingRequestsUseCaseProvider = Provider(
  (ref) =>
      GetPendingRequestsUseCase(ref.watch(mosqueRequestsRepositoryProvider)),
);

final acceptMosqueRequestUseCaseProvider = Provider(
  (ref) =>
      AcceptMosqueRequestUseCase(ref.watch(mosqueRequestsRepositoryProvider)),
);

final declineMosqueRequestUseCaseProvider = Provider(
  (ref) =>
      DeclineMosqueRequestUseCase(ref.watch(mosqueRequestsRepositoryProvider)),
);

// --- Provider ---
final mosqueRequestsProvider =
    AsyncNotifierProvider<MosqueRequestsNotifier, List<MosqueRequest>>(() {
      return MosqueRequestsNotifier();
    });

// --- Notifier ---
class MosqueRequestsNotifier extends AsyncNotifier<List<MosqueRequest>>
    with RetryExecutorMixin {
  @override
  FutureOr<List<MosqueRequest>> build() async {
    return _fetchPendingRequests();
  }

  Future<List<MosqueRequest>> _fetchPendingRequests() async {
    final getPendingRequestsUseCase = ref.read(
      getPendingRequestsUseCaseProvider,
    );
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => getPendingRequestsUseCase(NoParams()),
      networkInfo: networkInfo,
    );

    return result.fold(
      (failure) => throw Exception(mapFailureToMessage(failure)),
      (requests) => requests,
    );
  }

  Future<void> fetchPendingRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPendingRequests());
  }

  Future<void> createRequest({
    required String name,
    required String location,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    final createMosqueRequestUseCase = ref.read(
      createMosqueRequestUseCaseProvider,
    );
    final networkInfo = ref.read(networkInfoProvider);

    // We don't change state to loading here because the user might not be an admin
    // and thus state is just an empty list or not initialized for them.
    final result = await executeWithRetry(
      () => createMosqueRequestUseCase(
        CreateMosqueRequestParams(
          name: name,
          location: location,
          latitude: latitude,
          longitude: longitude,
          description: description,
        ),
      ),
      networkInfo: networkInfo,
    );

    result.fold(
      (failure) => throw Exception(mapFailureToMessage(failure)),
      (_) => null,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();

    final acceptMosqueRequestUseCase = ref.read(
      acceptMosqueRequestUseCaseProvider,
    );
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => acceptMosqueRequestUseCase(requestId),
      networkInfo: networkInfo,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(
          Exception(mapFailureToMessage(failure)),
          StackTrace.current,
        );
      },
      (_) {
        fetchPendingRequests();
      },
    );
  }

  Future<void> declineRequest(String requestId) async {
    state = const AsyncValue.loading();

    final declineMosqueRequestUseCase = ref.read(
      declineMosqueRequestUseCaseProvider,
    );
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => declineMosqueRequestUseCase(requestId),
      networkInfo: networkInfo,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(
          Exception(mapFailureToMessage(failure)),
          StackTrace.current,
        );
      },
      (_) {
        fetchPendingRequests();
      },
    );
  }
}
