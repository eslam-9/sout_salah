import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/day_schedule_entry.dart';
import 'mosque_data_providers.dart';

final dayScheduleProvider =
    FutureProvider.family<List<DayScheduleEntry>, String>((ref, dayId) async {
      final repository = ref.watch(dayScheduleRepositoryProvider);
      final result = await repository.getDaySchedule(dayId);

      return result.fold(
        (failure) => throw Exception('Failed to load day schedule'),
        (schedule) => schedule,
      );
    });

class DayScheduleNotifier
    extends StateNotifier<AsyncValue<List<DayScheduleEntry>>> {
  final String dayId;
  final String mosqueId;
  final Ref ref;

  DayScheduleNotifier({
    required this.dayId,
    required this.mosqueId,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(dayScheduleRepositoryProvider);
      final result = await repository.getDaySchedule(dayId);

      result.fold(
        (failure) {
          state = AsyncValue.error(
            Exception('فشل تحميل جدول اليوم'),
            StackTrace.current,
          );
        },
        (schedule) {
          state = AsyncValue.data(schedule);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadSchedule();
  }

  Future<bool> addEntry({
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  }) async {
    try {
      final repository = ref.read(dayScheduleRepositoryProvider);
      final result = await repository.addScheduleEntry(
        dayId: dayId,
        mosqueId: mosqueId,
        salah: salah,
        shikh: shikh,
        comments: comments,
        sortOrder: sortOrder,
      );

      return result.fold((failure) => false, (_) {
        _loadSchedule();
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  }) async {
    try {
      final repository = ref.read(dayScheduleRepositoryProvider);
      final result = await repository.updateScheduleEntry(
        entryId: entryId,
        salah: salah,
        shikh: shikh,
        comments: comments,
      );

      return result.fold((failure) => false, (_) {
        _loadSchedule();
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEntry(String entryId) async {
    try {
      final repository = ref.read(dayScheduleRepositoryProvider);
      final result = await repository.deleteScheduleEntry(entryId);

      return result.fold((failure) => false, (_) {
        _loadSchedule();
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}

// Family provider to instantiate specific notifiers based on dayId/mosqueId
final dayScheduleNotifierProvider =
    StateNotifierProvider.family<
      DayScheduleNotifier,
      AsyncValue<List<DayScheduleEntry>>,
      ({String dayId, String mosqueId})
    >(
      (ref, args) => DayScheduleNotifier(
        dayId: args.dayId,
        mosqueId: args.mosqueId,
        ref: ref,
      ),
    );
