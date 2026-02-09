import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/mosque_model.dart';
import '../models/ramadan_day_model.dart';

abstract class MosqueRemoteDataSource {
  Future<List<MosqueModel>> getMosques();
  Future<List<RamadanDayModel>> getRamadanDays(String mosqueId);
}

class MosqueRemoteDataSourceImpl implements MosqueRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  MosqueRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<List<MosqueModel>> getMosques() async {
    logger.i('Fetching list of mosques');
    try {
      final response = await supabaseClient.from('mosques').select();
      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} mosques');
      return data.map((json) => MosqueModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching mosques', e);
      throw ServerException();
    }
  }

  @override
  Future<List<RamadanDayModel>> getRamadanDays(String mosqueId) async {
    logger.i('Fetching Ramadan days for mosque: $mosqueId');
    try {
      final response = await supabaseClient
          .from('ramadan_days')
          .select()
          .eq('mosque_id', mosqueId)
          .order('day_number', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} days');
      return data.map((json) => RamadanDayModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching Ramadan days', e);
      throw ServerException();
    }
  }
}
