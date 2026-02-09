import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sout_salah/core/utils/app_logger.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});
