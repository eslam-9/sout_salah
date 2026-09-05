import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/day_schedule_entry.dart';
import 'mosque_data_providers.dart';

final dayScheduleProvider =
    FutureProvider.autoDispose.family<List<DayScheduleEntry>, String>((ref, dayId) async {
      final repository = ref.watch(dayScheduleRepositoryProvider);
      final result = await repository.getDaySchedule(dayId);

      return result.fold(
        (failure) => throw Exception('Failed to load day schedule'),
        (schedule) => schedule,
      );
    });

class DayScheduleNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<DayScheduleEntry>, ({String dayId, String mosqueId})> {
  
  String get dayId => arg.dayId;
  String get mosqueId => arg.mosqueId;

  @override
  FutureOr<List<DayScheduleEntry>> build(({String dayId, String mosqueId}) arg) {
    return _fetchSchedule();
  }

  Future<List<DayScheduleEntry>> _fetchSchedule() async {
    final repository = ref.read(dayScheduleRepositoryProvider);
    final result = await repository.getDaySchedule(dayId);

    return result.fold(
      (failure) => throw Exception('فشل تحميل جدول اليوم'),
      (schedule) => schedule,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSchedule());
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
        refresh();
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
        refresh();
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
        refresh();
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}

// Family provider to instantiate specific notifiers based on dayId/mosqueId
final dayScheduleNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<
      DayScheduleNotifier,
      List<DayScheduleEntry>,
      ({String dayId, String mosqueId})
    >(
      () => DayScheduleNotifier(),
    );

