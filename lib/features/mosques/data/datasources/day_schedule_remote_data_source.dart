import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/day_schedule_entry_model.dart';

abstract class DayScheduleRemoteDataSource {
  Future<List<DayScheduleEntryModel>> getDaySchedule(String dayId);
  Future<DayScheduleEntryModel> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  });
  Future<DayScheduleEntryModel> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  });
  Future<void> deleteScheduleEntry(String entryId);
}

class DayScheduleRemoteDataSourceImpl implements DayScheduleRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  DayScheduleRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<List<DayScheduleEntryModel>> getDaySchedule(String dayId) async {
    logger.i('Fetching schedule for day: $dayId');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .select('id, day_id, mosque_id, salah, shikh, comments, sort_order, created_at')
          .eq('day_id', dayId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} schedule entries');
      return data.map((json) => DayScheduleEntryModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      logger.e('Error fetching day schedule', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<DayScheduleEntryModel> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  }) async {
    logger.i('Adding schedule entry for $salah by $shikh');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .insert({
            'day_id': dayId,
            'mosque_id': mosqueId,
            'salah': salah,
            'shikh': shikh,
            ...?comments != null ? {'comments': comments} : null,
            'sort_order': sortOrder,
          })
          .select('id, day_id, mosque_id, salah, shikh, comments, sort_order, created_at')
          .single();

      logger.i('Schedule entry added successfully');
      return DayScheduleEntryModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error adding schedule entry', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<DayScheduleEntryModel> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  }) async {
    logger.i('Updating schedule entry: $entryId');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .update({'salah': salah, 'shikh': shikh, 'comments': comments})
          .eq('id', entryId)
          .select('id, day_id, mosque_id, salah, shikh, comments, sort_order, created_at')
          .single();

      logger.i('Schedule entry updated successfully');
      return DayScheduleEntryModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error updating schedule entry', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<void> deleteScheduleEntry(String entryId) async {
    logger.i('Deleting schedule entry: $entryId');
    try {
      await supabaseClient.from('day_schedule').delete().eq('id', entryId);
      logger.i('Schedule entry deleted successfully');
    } catch (e, stackTrace) {
      logger.e('Error deleting schedule entry', e, stackTrace);
      throw ServerException();
    }
  }
}
