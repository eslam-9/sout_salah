import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/usecases/get_ramadan_days_usecase.dart';
import '../../domain/usecases/add_month_usecase.dart';
import '../../domain/entities/ramadan_day.dart';
import 'mosque_data_providers.dart';
import 'month_year.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

// State for Ramadan Days
abstract class RamadanDaysState {
  const RamadanDaysState();
}

class RamadanDaysInitial extends RamadanDaysState {}

class RamadanDaysLoading extends RamadanDaysState {}

class RamadanDaysLoadedState extends RamadanDaysState {
  final List<RamadanDay> days;
  const RamadanDaysLoadedState(this.days);
}

class RamadanDaysError extends RamadanDaysState {
  final String message;
  final List<RamadanDay>? previousData;
  const RamadanDaysError(this.message, {this.previousData});
}

// Provider for GetRamadanDaysUseCase
final getRamadanDaysUseCaseProvider = Provider(
  (ref) => GetRamadanDaysUseCase(ref.watch(mosqueRepositoryProvider)),
);

// StateNotifier for Ramadan Days
class RamadanDaysNotifier extends StateNotifier<RamadanDaysState> {
  final GetRamadanDaysUseCase getRamadanDaysUseCase;
  final AddMonthUseCase addMonthUseCase;

  // Timeout duration for network requests
  static const Duration _timeoutDuration = Duration(seconds: 5);
  // Maximum retry attempts
  static const int _maxRetryAttempts = 3;

  RamadanDaysNotifier({
    required this.getRamadanDaysUseCase,
    required this.addMonthUseCase,
  }) : super(RamadanDaysInitial());

  Future<void> loadDays(String mosqueId) async {
    final currentState = state;
    List<RamadanDay>? oldData;
    if (currentState is RamadanDaysLoadedState) {
      oldData = currentState.days;
    } else if (currentState is RamadanDaysError) {
      oldData = currentState.previousData;
    }

    if (oldData == null) {
      state = RamadanDaysLoading();
    }

    final result = await getRamadanDaysUseCase(
      GetRamadanDaysParams(mosqueId: mosqueId, month: month, year: year),
    );
    result.fold(
      (failure) => state = RamadanDaysError(
        _mapFailureToMessage(failure),
        previousData: oldData,
      ),
      (days) => state = RamadanDaysLoadedState(days),
    );
  }

  Future<bool> addMonth(String mosqueId, int month, int year) async {
    final result = await _executeWithTimeoutAndRetry(
      () => addMonthUseCase(
        AddMonthParams(mosqueId: mosqueId, month: month, year: year),
      ),
    );

    return result.fold((failure) => false, (_) => true);
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

// Provider for Ramadan Days
final ramadanDaysProvider =
    StateNotifierProvider<RamadanDaysNotifier, RamadanDaysState>((ref) {
      return RamadanDaysNotifier(
        getRamadanDaysUseCase: ref.watch(getRamadanDaysUseCaseProvider),
        addMonthUseCase: ref.watch(addMonthUseCaseProvider),
      );
    });

// Provider for fetching available months for a mosque
final availableMonthsProvider = FutureProvider.family<List<MonthYear>, String>((
  ref,
  mosqueId,
) async {
  final repo = ref.watch(mosqueRepositoryProvider);
  final result = await repo.getAvailableMonths(mosqueId);
  return result.fold(
    (failure) => [],
    (months) => months
        .map((m) => MonthYear(month: m['month']!, year: m['year']!))
        .toList(),
  );
});
