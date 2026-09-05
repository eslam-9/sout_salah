import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/mosque_request_model.dart';

abstract class MosqueRequestsRemoteDataSource {
  Future<MosqueRequestModel> createMosqueRequest({
    required String name,
    required String location,
    double? latitude,
    double? longitude,
    String? description,
  });
  Future<List<MosqueRequestModel>> getPendingRequests();
  Future<void> acceptMosqueRequest(String requestId);
  Future<void> declineMosqueRequest(String requestId);
}

class MosqueRequestsRemoteDataSourceImpl
    implements MosqueRequestsRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  MosqueRequestsRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<MosqueRequestModel> createMosqueRequest({
    required String name,
    required String location,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    logger.i('Creating mosque request for: $name');
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final insertData = <String, dynamic>{
        'name': name,
        'location': location,
        'description': description,
        'requested_by': currentUser.id,
        'status': 'pending',
      };
      if (latitude != null) insertData['latitude'] = latitude;
      if (longitude != null) insertData['longitude'] = longitude;

      final response = await supabaseClient
          .from('mosque_requests')
          .insert(insertData)
          .select('id, name, location, latitude, longitude, description, requested_by, status, created_at')
          .single();

      logger.i('Mosque request created successfully');
      return MosqueRequestModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating mosque request', e);
      throw ServerException();
    }
  }

  @override
  Future<List<MosqueRequestModel>> getPendingRequests() async {
    logger.i('Fetching pending mosque requests');
    try {
      final response = await supabaseClient
          .from('mosque_requests')
          .select('id, name, location, latitude, longitude, description, requested_by, status, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => MosqueRequestModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching pending requests', e);
      throw ServerException();
    }
  }

  @override
  Future<void> acceptMosqueRequest(String requestId) async {
    logger.i('Accepting mosque request: $requestId');
    try {
      final requestData = await supabaseClient
          .from('mosque_requests')
          .select('id, name, location, latitude, longitude, description, requested_by, status, created_at')
          .eq('id', requestId)
          .single();

      final insertData = <String, dynamic>{
        'name': requestData['name'],
        'location': requestData['location'],
        'description': requestData['description'],
        'admin_id': requestData['requested_by'],
      };
      if (requestData['latitude'] != null) insertData['latitude'] = requestData['latitude'];
      if (requestData['longitude'] != null) insertData['longitude'] = requestData['longitude'];

      await supabaseClient
          .from('mosques')
          .insert(insertData)
          .select('id, name, location, description, created_at, admin_id')
          .single();

      await supabaseClient
          .from('mosque_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      logger.i('Mosque request accepted and mosque created');
    } catch (e) {
      logger.e('Error accepting mosque request', e);
      throw ServerException();
    }
  }

  @override
  Future<void> declineMosqueRequest(String requestId) async {
    logger.i('Declining mosque request: $requestId');
    try {
      await supabaseClient
          .from('mosque_requests')
          .update({'status': 'declined'})
          .eq('id', requestId);

      logger.i('Mosque request declined');
    } catch (e) {
      logger.e('Error declining mosque request', e);
      throw ServerException();
    }
  }
}
