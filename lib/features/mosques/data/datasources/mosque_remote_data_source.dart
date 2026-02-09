import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/mosque_model.dart';
import '../models/ramadan_day_model.dart';
import '../models/recording_model.dart';
import '../../domain/entities/prayer.dart';
import 'dart:io';

abstract class MosqueRemoteDataSource {
  Future<List<MosqueModel>> getMosques();
  Future<List<RamadanDayModel>> getRamadanDays(String mosqueId);
  Future<List<RecordingModel>> getDayRecordings(String dayId);
  Future<MosqueModel> addMosque({
    required String name,
    required String location,
    String? description,
  });
  Future<RecordingModel> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
  });
  Future<void> deleteRecording(String recordingId);
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
      logger.e('Error details: ${e.toString()}');
      throw ServerException();
    }
  }

  @override
  Future<List<RecordingModel>> getDayRecordings(String dayId) async {
    logger.i('Fetching recordings for day: $dayId');
    try {
      final response = await supabaseClient
          .from('recordings')
          .select()
          .eq('day_id', dayId)
          .order('prayer_name', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} recordings');
      return data.map((json) => RecordingModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      logger.e('Error fetching recordings', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<RecordingModel> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
  }) async {
    logger.i('Uploading recording for prayer: ${prayer.englishName}');
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${prayer.englishName}.mp3';
      final storagePath = 'recordings/$mosqueId/$dayId/$fileName';

      // Upload file to Supabase Storage
      await supabaseClient.storage
          .from('audio-recordings')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: false),
          );

      // Get public URL
      final audioUrl = supabaseClient.storage
          .from('audio-recordings')
          .getPublicUrl(storagePath);

      // Save metadata to database
      final response = await supabaseClient
          .from('recordings')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'prayer_name': prayer.englishName,
            'sheikh_name': sheikhName,
            'audio_url': audioUrl,
            'file_size': fileSize,
            'duration': duration,
          })
          .select()
          .single();

      logger.i('Recording uploaded successfully');
      return RecordingModel.fromJson(response);
    } catch (e) {
      logger.e('Error uploading recording', e);
      throw ServerException();
    }
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    logger.i('Deleting recording: $recordingId');
    try {
      // Get recording to find audio URL
      final recording = await supabaseClient
          .from('recordings')
          .select('audio_url')
          .eq('id', recordingId)
          .single();

      final audioUrl = recording['audio_url'] as String;

      // Extract storage path from URL
      final uri = Uri.parse(audioUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('audio-recordings');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

        // Delete from storage
        await supabaseClient.storage.from('audio-recordings').remove([
          storagePath,
        ]);
      }

      // Delete from database
      await supabaseClient.from('recordings').delete().eq('id', recordingId);

      logger.i('Recording deleted successfully');
    } catch (e) {
      logger.e('Error deleting recording', e);
      throw ServerException();
    }
  }
}
