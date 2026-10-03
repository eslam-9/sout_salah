import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_logger.dart';
import 'package:get_it/get_it.dart';

class StartupData {

  StartupData({required this.info, required this.link});

  factory StartupData.fromJson(Map<String, dynamic> json) {
    return StartupData(
      info: json['info'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }
  final String info;
  final String link;
}

class StartupService {

  StartupService(this._supabase) : _logger = GetIt.I<AppLogger>();
  final SupabaseClient _supabase;
  final AppLogger _logger;

  Future<StartupData?> checkStartupData() async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _logger.i('Startup data found: $response');
        return StartupData.fromJson(response);
      } else {
        _logger.i('No startup data found');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetching startup data', e, stackTrace);
      return null;
    }
  }
}
