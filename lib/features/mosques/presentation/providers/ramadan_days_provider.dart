import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_ramadan_days_usecase.dart';
import '../../domain/entities/ramadan_day.dart';
import 'mosque_data_providers.dart';
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
  const RamadanDaysError(this.message);
}

// Provider for GetRamadanDaysUseCase
final getRamadanDaysUseCaseProvider = Provider(
  (ref) => GetRamadanDaysUseCase(ref.watch(mosqueRepositoryProvider)),
);

// StateNotifier for Ramadan Days
class RamadanDaysNotifier extends StateNotifier<RamadanDaysState> {
  final GetRamadanDaysUseCase getRamadanDaysUseCase;

  RamadanDaysNotifier({required this.getRamadanDaysUseCase})
    : super(RamadanDaysInitial());

  Future<void> loadDays(String mosqueId) async {
    state = RamadanDaysLoading();
    final result = await getRamadanDaysUseCase(
      GetRamadanDaysParams(mosqueId: mosqueId),
    );
    result.fold(
      (failure) => state = RamadanDaysError(_mapFailureToMessage(failure)),
      (days) => state = RamadanDaysLoadedState(days),
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
      );
    });
