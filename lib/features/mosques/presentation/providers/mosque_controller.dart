import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/usecases/get_mosques_usecase.dart';
import '../../domain/usecases/add_mosque_usecase.dart';
import '../../domain/entities/mosque.dart';
import 'mosque_data_providers.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/riverpod_providers.dart';

final getMosquesUseCaseProvider = Provider(
  (ref) => GetMosquesUseCase(ref.watch(mosqueRepositoryProvider)),
);
final addMosquesUseCaseProvider = Provider(
  (ref) => AddMosqueUseCase(ref.watch(mosqueRepositoryProvider)),
);

final mosqueProvider = AsyncNotifierProvider<MosqueNotifier, List<Mosque>>(() {
  return MosqueNotifier();
});

class MosqueNotifier extends AsyncNotifier<List<Mosque>>
    with RetryExecutorMixin {
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  FutureOr<List<Mosque>> build() async {
    _currentPage = 0;
    _hasMore = true;
    return _fetchMosques(page: _currentPage, pageSize: _pageSize);
  }

  Future<List<Mosque>> _fetchMosques({
    required int page,
    required int pageSize,
  }) async {
    final getMosquesUseCase = ref.read(getMosquesUseCaseProvider);
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => getMosquesUseCase(
        GetMosquesParams(limit: pageSize, offset: page * pageSize),
      ),
      networkInfo: networkInfo,
    );

    return result.fold(
      (failure) => throw Exception(mapFailureToMessage(failure)),
      (mosques) {
        if (mosques.length < pageSize) {
          _hasMore = false;
        }
        return mosques;
      },
    );
  }

  Future<void> getMosques() async {
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchMosques(page: _currentPage, pageSize: _pageSize),
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || state.isRefreshing) return;

    final currentState = state;
    if (currentState.hasValue) {
      final currentList = currentState.value!;
      state = const AsyncValue.loading();

      try {
        _currentPage++;
        final newMosques = await _fetchMosques(
          page: _currentPage,
          pageSize: _pageSize,
        );
        state = AsyncValue.data([...currentList, ...newMosques]);
      } catch (e, st) {
        _currentPage--;
        state = AsyncValue<List<Mosque>>.error(
          e,
          st,
        ).copyWithPrevious(currentState);
      }
    }
  }

  Future<void> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    final addMosqueUseCase = ref.read(addMosquesUseCaseProvider);
    final networkInfo = ref.read(networkInfoProvider);

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
      (failure) {
        state = AsyncValue.error(
          Exception(mapFailureToMessage(failure)),
          StackTrace.current,
        );
        // Restore previous state if needed, or leave it in error
      },
      (mosque) {
        // Refresh the list after adding
        getMosques();
      },
    );
  }
}
