import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/ramadan_day_model.dart';
import '../../domain/factories/ramadan_month_factory.dart';

abstract class RamadanDaysRemoteDataSource {
  Future<List<RamadanDayModel>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  });
  Future<void> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  });
  Future<List<Map<String, int>>> getAvailableMonths(String mosqueId);
}

class RamadanDaysRemoteDataSourceImpl implements RamadanDaysRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  RamadanDaysRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<List<RamadanDayModel>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  }) async {
    logger.i(
      'Fetching Ramadan days for mosque: $mosqueId, month: $month, year: $year',
    );
    try {
      var query = supabaseClient
          .from('ramadan_days')
          .select('id, mosque_id, month, year, day_number, active, status, created_at, recordings(count)')
          .eq('mosque_id', mosqueId);

      if (month != null) {
        query = query.eq('month', month);
      }
      if (year != null) {
        query = query.eq('year', year);
      }

      final response = await query.order('day_number', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} days');
      return data.map((json) => RamadanDayModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching Ramadan days', e);
      throw ServerException();
    }
  }

  @override
  Future<void> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  }) async {
    logger.i('Adding new month: $month/$year for mosque $mosqueId');
    try {
      final daysToInsert = RamadanMonthFactory.createDays(
        mosqueId: mosqueId,
        month: month,
        year: year,
      );

      await supabaseClient.from('ramadan_days').insert(daysToInsert);

      logger.i('Successfully added 30 days for month $month/$year');
    } catch (e, stackTrace) {
      logger.e('Error adding month', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<List<Map<String, int>>> getAvailableMonths(String mosqueId) async {
    logger.i('Fetching available months for mosque: $mosqueId (using Dart distinct)');
    try {
      final response = await supabaseClient
          .rpc('get_available_months', params: {'p_mosque_id': mosqueId});

      final data = response as List<dynamic>;
      final result = data.map((row) {
        return {
          'month': row['month'] as int,
          'year': row['year'] as int,
        };
      }).toList();

      result.sort((a, b) {
        final yearCmp = a['year']!.compareTo(b['year']!);
        if (yearCmp != 0) return yearCmp;
        return a['month']!.compareTo(b['month']!);
      });

      return result;
    } catch (e, stackTrace) {
      logger.e('Error fetching available months', e, stackTrace);
      throw ServerException();
    }
  }
}
