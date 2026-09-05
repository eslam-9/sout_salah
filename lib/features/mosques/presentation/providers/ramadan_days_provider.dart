import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/usecases/get_ramadan_days_usecase.dart';
import '../../domain/usecases/add_month_usecase.dart';
import '../../domain/entities/ramadan_day.dart';
import 'mosque_data_providers.dart';
import 'month_year.dart';
import '../../../../core/network/retry_executor.dart';
import '../../../../core/di/riverpod_providers.dart';

// Provider for GetRamadanDaysUseCase
final getRamadanDaysUseCaseProvider = Provider(
  (ref) => GetRamadanDaysUseCase(ref.watch(ramadanDaysRepositoryProvider)),
);

// Provider for Ramadan Days
final ramadanDaysProvider =
    AsyncNotifierProvider<RamadanDaysNotifier, List<RamadanDay>>(() {
      return RamadanDaysNotifier();
    });

class RamadanDaysNotifier extends AsyncNotifier<List<RamadanDay>>
    with RetryExecutorMixin {
  @override
  FutureOr<List<RamadanDay>> build() {
    return [];
  }

  Future<void> loadDays(String mosqueId, {int? month, int? year}) async {
    // Keep previous data if we're just refreshing
    final previousData = state.valueOrNull;

    state = previousData != null
        ? const AsyncValue<List<RamadanDay>>.loading().copyWithPrevious(
            AsyncData(previousData),
          )
        : const AsyncValue<List<RamadanDay>>.loading();

    final getRamadanDaysUseCase = ref.read(getRamadanDaysUseCaseProvider);
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => getRamadanDaysUseCase(
        GetRamadanDaysParams(mosqueId: mosqueId, month: month, year: year),
      ),
      networkInfo: networkInfo,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(
          Exception(mapFailureToMessage(failure)),
          StackTrace.current,
        );
        if (previousData != null) {
          state = state.copyWithPrevious(AsyncData(previousData));
        }
      },
      (days) {
        state = AsyncValue.data(days);
      },
    );
  }

  Future<bool> addMonth(String mosqueId, int month, int year) async {
    final addMonthUseCase = ref.read(addMonthUseCaseProvider);
    final networkInfo = ref.read(networkInfoProvider);

    final result = await executeWithRetry(
      () => addMonthUseCase(
        AddMonthParams(mosqueId: mosqueId, month: month, year: year),
      ),
      networkInfo: networkInfo,
    );

    return result.fold((failure) => false, (_) => true);
  }
}

// Provider for fetching available months for a mosque
final availableMonthsProvider = FutureProvider.autoDispose
    .family<List<MonthYear>, String>((ref, mosqueId) async {
      final repo = ref.watch(ramadanDaysRepositoryProvider);
      final result = await repo.getAvailableMonths(mosqueId);
      return result.fold(
        (failure) => [],
        (months) => months
            .map((m) => MonthYear(month: m['month']!, year: m['year']!))
            .toList(),
      );
    });
