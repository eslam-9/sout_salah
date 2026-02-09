import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_mosques_usecase.dart';
import '../../domain/usecases/add_mosque_usecase.dart';
import 'mosque_data_providers.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../bloc/mosque_state_event.dart'; // Reuse state classes

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
  )..getMosques();
});

class MosqueNotifier extends StateNotifier<MosqueState> {
  final GetMosquesUseCase getMosquesUseCase;
  final AddMosqueUseCase addMosqueUseCase;

  MosqueNotifier({
    required this.getMosquesUseCase,
    required this.addMosqueUseCase,
  }) : super(MosqueInitial());

  Future<void> getMosques() async {
    state = MosqueLoading();
    final result = await getMosquesUseCase(NoParams());
    result.fold(
      (failure) => state = MosqueError(_mapFailureToMessage(failure)),
      (mosques) => state = MosqueLoaded(mosques),
    );
  }

  Future<void> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    state = MosqueLoading();
    final result = await addMosqueUseCase(
      AddMosqueParams(name: name, location: location, description: description),
    );

    result.fold(
      (failure) => state = MosqueError(_mapFailureToMessage(failure)),
      (mosque) {
        // Refresh the list after adding
        getMosques();
      },
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
