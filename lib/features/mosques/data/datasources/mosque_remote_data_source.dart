import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/mosque_model.dart';

abstract class MosqueRemoteDataSource {
  Future<List<MosqueModel>> getMosques();
  Future<MosqueModel> addMosque({
    required String name,
    required String location,
    String? description,
  });
  Future<void> addPublisher(String mosqueId, String email);
}

class MosqueRemoteDataSourceImpl implements MosqueRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  MosqueRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<List<MosqueModel>> getMosques() async {
    logger.i('Fetching list of mosques');
    try {
      final response = await supabaseClient
          .from('mosques')
          .select('*, recordings(count)');
      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} mosques');
      return data.map((json) => MosqueModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching mosques', e);
      throw ServerException();
    }
  }

  @override
  Future<MosqueModel> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    logger.i('Adding new mosque: $name');
    try {
      final response = await supabaseClient
          .from('mosques')
          .insert({
            'name': name,
            'location': location,
            ...?description != null ? {'description': description} : null,
          })
          .select()
          .single();

      logger.i('Mosque added successfully: ${response['id']}');
      return MosqueModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error adding mosque', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<void> addPublisher(String mosqueId, String email) async {
    logger.i('Adding publisher with email $email to mosque $mosqueId');
    try {
      final userResponse = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        logger.w('User with email $email not found');
        throw Exception('User not found');
      }

      final userId = userResponse['id'] as String;

      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      await supabaseClient.from('mosque_publishers').insert({
        'mosque_id': mosqueId,
        'publisher_id': userId,
        'added_by': currentUser.id,
      });

      logger.i('Publisher added successfully');
    } catch (e) {
      logger.e('Error adding publisher', e);
      if (e.toString().contains('User not found') ||
          e.toString().contains('User with email')) {
        throw Exception('المستخدم غير موجود');
      }
      if (e.toString().contains('Only Super Admin')) {
        throw Exception('فقط مدير النظام يمكنه إضافة ناشرين');
      }
      throw ServerException();
    }
  }
}
