import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/usecases/get_ramadan_days_usecase.dart';
import '../../domain/usecases/add_month_usecase.dart';
import '../../domain/entities/ramadan_day.dart';
import 'mosque_data_providers.dart';
import 'month_year.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/riverpod_providers.dart';

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
  (ref) => GetRamadanDaysUseCase(ref.watch(ramadanDaysRepositoryProvider)),
);

// StateNotifier for Ramadan Days
class RamadanDaysNotifier extends StateNotifier<RamadanDaysState>
    with RetryExecutorMixin {
  final GetRamadanDaysUseCase getRamadanDaysUseCase;
  final AddMonthUseCase addMonthUseCase;
  final NetworkInfo networkInfo;

  RamadanDaysNotifier({
    required this.getRamadanDaysUseCase,
    required this.addMonthUseCase,
    required this.networkInfo,
  }) : super(RamadanDaysInitial());

  Future<void> loadDays(String mosqueId, {int? month, int? year}) async {
    final previousData = state is RamadanDaysLoadedState 
        ? (state as RamadanDaysLoadedState).days 
        : (state is RamadanDaysError ? (state as RamadanDaysError).previousData : null);
    state = RamadanDaysLoading();
    final result = await executeWithRetry(
      () => getRamadanDaysUseCase(
        GetRamadanDaysParams(mosqueId: mosqueId, month: month, year: year),
      ),
      networkInfo: networkInfo,
    );
    result.fold(
      (failure) => state = RamadanDaysError(mapFailureToMessage(failure), previousData: previousData),
      (days) => state = RamadanDaysLoadedState(days),
    );
  }

  Future<bool> addMonth(String mosqueId, int month, int year) async {
    final result = await executeWithRetry(
      () => addMonthUseCase(
        AddMonthParams(mosqueId: mosqueId, month: month, year: year),
      ),
      networkInfo: networkInfo,
    );

    return result.fold((failure) => false, (_) => true);
  }
}

// Provider for Ramadan Days
final ramadanDaysProvider =
    StateNotifierProvider<RamadanDaysNotifier, RamadanDaysState>((ref) {
      return RamadanDaysNotifier(
        getRamadanDaysUseCase: ref.watch(getRamadanDaysUseCaseProvider),
        addMonthUseCase: ref.watch(addMonthUseCaseProvider),
        networkInfo: ref.watch(networkInfoProvider),
      );
    });

// Provider for fetching available months for a mosque
final availableMonthsProvider = FutureProvider.family<List<MonthYear>, String>((
  ref,
  mosqueId,
) async {
  final repo = ref.watch(ramadanDaysRepositoryProvider);
  final result = await repo.getAvailableMonths(mosqueId);
  return result.fold(
    (failure) => [],
    (months) => months
        .map((m) => MonthYear(month: m['month']!, year: m['year']!))
        .toList(),
  );
});
