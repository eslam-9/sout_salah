import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/usecases/get_mosques_usecase.dart';
import '../../domain/usecases/add_mosque_usecase.dart';
import 'mosque_data_providers.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/providers.dart';
import 'mosque_state.dart';

final getMosquesUseCaseProvider = Provider(
  (ref) => GetMosquesUseCase(ref.watch(mosqueRepositoryProvider)),
);
final addMosquesUseCaseProvider = Provider(
  (ref) => AddMosqueUseCase(ref.watch(mosqueRepositoryProvider)),
);

final mosqueProvider = StateNotifierProvider<MosqueNotifier, MosqueState>((
  ref,
) {
  return MosqueNotifier(
    getMosquesUseCase: ref.watch(getMosquesUseCaseProvider),
    addMosqueUseCase: ref.watch(addMosquesUseCaseProvider),
    networkInfo: ref.watch(networkInfoProvider),
  )..getMosques();
});

class MosqueNotifier extends StateNotifier<MosqueState>
    with RetryExecutorMixin {
  final GetMosquesUseCase getMosquesUseCase;
  final AddMosqueUseCase addMosqueUseCase;
  final NetworkInfo networkInfo;

  MosqueNotifier({
    required this.getMosquesUseCase,
    required this.addMosqueUseCase,
    required this.networkInfo,
  }) : super(MosqueInitial());

  Future<void> getMosques() async {
    state = MosqueLoading();
    final result = await executeWithRetry(
      () => getMosquesUseCase(NoParams()),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) => state = MosqueError(mapFailureToMessage(failure)),
      (mosques) => state = MosqueLoaded(mosques),
    );
  }

  Future<void> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    state = MosqueLoading();
    final result = await executeWithRetry(
      () => addMosqueUseCase(
        AddMosqueParams(
          name: name,
          location: location,
          description: description,
        ),
      ),
      networkInfo: networkInfo,
    );

    result.fold(
      (failure) => state = MosqueError(mapFailureToMessage(failure)),
      (mosque) {
        // Refresh the list after adding
        getMosques();
      },
    );
  }
}
