import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mosque_request.dart';
import '../../domain/usecases/mosque_request_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/providers.dart';
import 'mosque_data_providers.dart';

// --- UseCase Providers ---
final createMosqueRequestUseCaseProvider = Provider(
  (ref) => CreateMosqueRequestUseCase(ref.watch(mosqueRepositoryProvider)),
);

final getPendingRequestsUseCaseProvider = Provider(
  (ref) => GetPendingRequestsUseCase(ref.watch(mosqueRepositoryProvider)),
);

final acceptMosqueRequestUseCaseProvider = Provider(
  (ref) => AcceptMosqueRequestUseCase(ref.watch(mosqueRepositoryProvider)),
);

final declineMosqueRequestUseCaseProvider = Provider(
  (ref) => DeclineMosqueRequestUseCase(ref.watch(mosqueRepositoryProvider)),
);

// --- State ---
abstract class MosqueRequestsState {}

class MosqueRequestsInitial extends MosqueRequestsState {}
class MosqueRequestsLoading extends MosqueRequestsState {}
class MosqueRequestsLoaded extends MosqueRequestsState {
  final List<MosqueRequest> requests;
  MosqueRequestsLoaded(this.requests);
}
class MosqueRequestsError extends MosqueRequestsState {
  final String message;
  MosqueRequestsError(this.message);
}
class MosqueRequestSuccess extends MosqueRequestsState {
  final String message;
  MosqueRequestSuccess(this.message);
}

// --- Provider ---
final mosqueRequestsProvider = StateNotifierProvider<MosqueRequestsNotifier, MosqueRequestsState>((ref) {
  return MosqueRequestsNotifier(
    createMosqueRequestUseCase: ref.watch(createMosqueRequestUseCaseProvider),
    getPendingRequestsUseCase: ref.watch(getPendingRequestsUseCaseProvider),
    acceptMosqueRequestUseCase: ref.watch(acceptMosqueRequestUseCaseProvider),
    declineMosqueRequestUseCase: ref.watch(declineMosqueRequestUseCaseProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// --- Notifier ---
class MosqueRequestsNotifier extends StateNotifier<MosqueRequestsState> with RetryExecutorMixin {
  final CreateMosqueRequestUseCase createMosqueRequestUseCase;
  final GetPendingRequestsUseCase getPendingRequestsUseCase;
  final AcceptMosqueRequestUseCase acceptMosqueRequestUseCase;
  final DeclineMosqueRequestUseCase declineMosqueRequestUseCase;
  final NetworkInfo networkInfo;

  MosqueRequestsNotifier({
    required this.createMosqueRequestUseCase,
    required this.getPendingRequestsUseCase,
    required this.acceptMosqueRequestUseCase,
    required this.declineMosqueRequestUseCase,
    required this.networkInfo,
  }) : super(MosqueRequestsInitial());

  Future<void> fetchPendingRequests() async {
    state = MosqueRequestsLoading();
    final result = await executeWithRetry(
      () => getPendingRequestsUseCase(NoParams()),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) => state = MosqueRequestsError(mapFailureToMessage(failure)),
      (requests) => state = MosqueRequestsLoaded(requests),
    );
  }

  Future<void> createRequest({
    required String name,
    required String location,
    String? description,
  }) async {
    state = MosqueRequestsLoading();
    final result = await executeWithRetry(
      () => createMosqueRequestUseCase(
        CreateMosqueRequestParams(
          name: name,
          location: location,
          description: description,
        ),
      ),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) => state = MosqueRequestsError(mapFailureToMessage(failure)),
      (_) => state = MosqueRequestSuccess("تم إرسال طلب إنشاء المسجد بنجاح. سيتم مراجعته من قبل الإدارة."),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    final currentState = state;
    state = MosqueRequestsLoading();
    final result = await executeWithRetry(
      () => acceptMosqueRequestUseCase(requestId),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) {
        state = MosqueRequestsError(mapFailureToMessage(failure));
        if (currentState is MosqueRequestsLoaded) {
          state = currentState;
        }
      },
      (_) {
        state = MosqueRequestSuccess("تم قبول الطلب وإنشاء المسجد بنجاح.");
        fetchPendingRequests();
      },
    );
  }

  Future<void> declineRequest(String requestId) async {
    final currentState = state;
    state = MosqueRequestsLoading();
    final result = await executeWithRetry(
      () => declineMosqueRequestUseCase(requestId),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) {
        state = MosqueRequestsError(mapFailureToMessage(failure));
        if (currentState is MosqueRequestsLoaded) {
          state = currentState;
        }
      },
      (_) {
        state = MosqueRequestSuccess("تم رفض الطلب.");
        fetchPendingRequests();
      },
    );
  }
}
