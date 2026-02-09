import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_mosques_usecase.dart';

import 'mosque_data_providers.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../bloc/mosque_state_event.dart'; // Reuse state classes

final getMosquesUseCaseProvider = Provider(
  (ref) => GetMosquesUseCase(ref.watch(mosqueRepositoryProvider)),
);

final mosqueProvider = StateNotifierProvider<MosqueNotifier, MosqueState>((
  ref,
) {
  return MosqueNotifier(getMosquesUseCase: ref.watch(getMosquesUseCaseProvider))
    ..getMosques();
});

class MosqueNotifier extends StateNotifier<MosqueState> {
  final GetMosquesUseCase getMosquesUseCase;

  MosqueNotifier({required this.getMosquesUseCase}) : super(MosqueInitial());

  Future<void> getMosques() async {
    state = MosqueLoading();
    final result = await getMosquesUseCase(NoParams());
    result.fold(
      (failure) => state = MosqueError(_mapFailureToMessage(failure)),
      (mosques) => state = MosqueLoaded(mosques),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Failure';
    } else if (failure is CacheFailure) {
      return 'Cache Failure';
    } else {
      return 'Unexpected Error';
    }
  }
}
