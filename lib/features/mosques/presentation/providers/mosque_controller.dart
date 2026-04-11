import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/usecases/get_mosques_usecase.dart';
import '../../domain/usecases/add_mosque_usecase.dart';
import 'mosque_data_providers.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../bloc/mosque_state_event.dart';

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

  // Timeout duration for network requests
  static const Duration _timeoutDuration = Duration(seconds: 5);
  // Maximum retry attempts
  static const int _maxRetryAttempts = 3;

  MosqueNotifier({
    required this.getMosquesUseCase,
    required this.addMosqueUseCase,
  }) : super(MosqueInitial());

  Future<void> getMosques() async {
    state = MosqueLoading();
    final result = await _executeWithTimeoutAndRetry(
      () => getMosquesUseCase(NoParams()),
    );
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
    final result = await _executeWithTimeoutAndRetry(
      () => addMosqueUseCase(
        AddMosqueParams(
          name: name,
          location: location,
          description: description,
        ),
      ),
    );

    result.fold(
      (failure) => state = MosqueError(_mapFailureToMessage(failure)),
      (mosque) {
        // Refresh the list after adding
        getMosques();
      },
    );
  }

  /// Executes a future with timeout and retry mechanism
  Future<Either<Failure, T>> _executeWithTimeoutAndRetry<T>(
    Future<Either<Failure, T>> Function() operation,
  ) async {
    int attempt = 0;
    while (attempt <= _maxRetryAttempts) {
      try {
        // Create a timeout for the operation
        final result = await operation().timeout(
          _timeoutDuration,
          onTimeout: () =>
              Left(const ServerFailure(message: 'Request timeout')),
        );

        // If successful, return the result
        if (result.isRight()) {
          return result;
        }

        // If we got a failure, check if we should retry
        attempt++;
        if (attempt > _maxRetryAttempts) {
          return result; // Return the failure after max attempts
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      } on TimeoutException catch (_) {
        attempt++;
        if (attempt > _maxRetryAttempts) {
          return Left(const ServerFailure(message: 'Request timeout'));
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        attempt++;
        if (attempt > _maxRetryAttempts) {
          return Left(ServerFailure(message: e.toString()));
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // Should not reach here, but just in case
    return Left(const ServerFailure(message: 'Max retry attempts exceeded'));
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
