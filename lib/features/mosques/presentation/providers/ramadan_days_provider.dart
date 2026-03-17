import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_ramadan_days_usecase.dart';
import '../../domain/usecases/add_month_usecase.dart';
import '../../domain/entities/ramadan_day.dart';
import 'mosque_data_providers.dart';
import 'month_year.dart';
import '../../../../core/error/failures.dart';

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
    final result = await addMonthUseCase(
      AddMonthParams(mosqueId: mosqueId, month: month, year: year),
    );
    
    return result.fold(
      (failure) => false,
      (_) => true,
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

// Provider for Ramadan Days
final ramadanDaysProvider =
    StateNotifierProvider<RamadanDaysNotifier, RamadanDaysState>((ref) {
      return RamadanDaysNotifier(
        getRamadanDaysUseCase: ref.watch(getRamadanDaysUseCaseProvider),
        addMonthUseCase: ref.watch(addMonthUseCaseProvider),
      );
    });

// Provider for fetching available months for a mosque
final availableMonthsProvider = FutureProvider.family<List<MonthYear>, String>((ref, mosqueId) async {
  final repo = ref.watch(mosqueRepositoryProvider);
  final result = await repo.getAvailableMonths(mosqueId);
  return result.fold(
    (failure) => [],
    (months) => months.map((m) => MonthYear(month: m['month']!, year: m['year']!)).toList(),
  );
});
