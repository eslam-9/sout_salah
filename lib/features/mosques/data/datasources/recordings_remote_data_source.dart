import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../models/recording_model.dart';
import '../../domain/entities/prayer.dart';
import 'dart:io';

abstract class RecordingsRemoteDataSource {
  Future<List<RecordingModel>> getDayRecordings(String dayId, {int? limit, int? offset});
  Future<RecordingModel> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  });
  Future<void> deleteRecording(String recordingId);
  Future<RecordingModel> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  });
}

class RecordingsRemoteDataSourceImpl implements RecordingsRemoteDataSource {
  final SupabaseClient supabaseClient;
  final R2StorageService r2StorageService;
  final AppLogger logger;

  RecordingsRemoteDataSourceImpl(
    this.supabaseClient,
    this.r2StorageService,
    this.logger,
  );

  @override
  Future<List<RecordingModel>> getDayRecordings(String dayId, {int? limit, int? offset}) async {
    logger.i('Fetching recordings for day: $dayId (limit: $limit, offset: $offset)');
    try {
      dynamic query = supabaseClient
          .from('recordings')
          .select('id, mosque_id, day_id, publisher_id, prayer_name, sheikh_name, audio_url, file_size, duration, created_at')
          .eq('day_id', dayId)
          .order('prayer_name', ascending: true);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        final to = limit != null ? offset + limit - 1 : null;
        if (to != null) {
          query = query.range(offset, to);
        }
      }

      final response = await query;

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
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  }) async {
    final effectivePrayerName = prayer.resolvedName(customPrayerName);
    logger.i('Uploading recording for prayer: $effectivePrayerName');
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$effectivePrayerName.mp3';
      final storageKey = 'recordings/$mosqueId/$dayId/$fileName';

      final audioUrl = await r2StorageService.uploadFile(
        storageKey,
        file,
        onProgress: onProgress,
      );

      final response = await supabaseClient
          .from('recordings')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'prayer_name': effectivePrayerName,
            'sheikh_name': sheikhName,
            'audio_url': audioUrl,
            'file_size': fileSize,
            'duration': duration,
          })
          .select('id, mosque_id, day_id, publisher_id, prayer_name, sheikh_name, audio_url, file_size, duration, created_at')
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
      final recording = await supabaseClient
          .from('recordings')
          .select('audio_url')
          .eq('id', recordingId)
          .single();

      final audioUrl = recording['audio_url'] as String;

      final uri = Uri.parse(audioUrl);
      final storageKey = uri.path.startsWith('/')
          ? uri.path.substring(1)
          : uri.path;

      await r2StorageService.deleteFile(storageKey);

      await supabaseClient.from('recordings').delete().eq('id', recordingId);

      logger.i('Recording deleted successfully');
    } catch (e) {
      logger.e('Error deleting recording', e);
      throw ServerException();
    }
  }

  @override
  Future<RecordingModel> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  }) async {
    logger.i('Creating pending recording for: $prayerName');
    try {
      final response = await supabaseClient
          .from('recordings')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'prayer_name': prayerName,
            'sheikh_name': 'Pending',
            'audio_url': 'pending',
            'file_size': 0,
            'duration': 0,
          })
          .select('id, mosque_id, day_id, publisher_id, prayer_name, sheikh_name, audio_url, file_size, duration, created_at')
          .single();

      logger.i('Pending recording created successfully');
      return RecordingModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating pending recording', e);
      throw ServerException();
    }
  }
}
