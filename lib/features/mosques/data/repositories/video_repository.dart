import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/daily_video_model.dart';

class VideoRepository {
  final SupabaseClient supabaseClient;
  final R2StorageService r2StorageService;
  final AppLogger _logger;
  
  VideoRepository({
    required this.supabaseClient,
    required this.r2StorageService,
    required AppLogger logger,
  }) : _logger = logger;

  Future<DailyVideoModel?> getVideoForDay(String dayId) async {
    try {
      final response = await supabaseClient
          .from('daily_videos')
          .select()
          .eq('day_id', dayId)
          .maybeSingle();

      if (response == null) return null;

      return DailyVideoModel.fromJson(response);
    } catch (e) {
      _logger.e('Error fetching daily video for day $dayId', e);
      rethrow;
    }
  }

  Future<DailyVideoModel> uploadVideo({
    required File videoFile,
    required String mosqueId,
    required String dayId,
    required int dayNumber,
    String? description,
    void Function(double)? onProgress,
  }) async {
    try {
      // 1. Upload to Cloudflare R2
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_video_day_$dayNumber.mp4';
      final r2Path = '$mosqueId/day_$dayNumber/videos/$fileName';

      final publicUrl = await r2StorageService.uploadFile(
        r2Path,
        videoFile,
        onProgress: onProgress,
        contentType: 'video/mp4',
      );

      // 2. Insert into Supabase
      final response = await supabaseClient
          .from('daily_videos')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'publisher_id': supabaseClient.auth.currentUser?.id,
            'video_url': publicUrl,
            'description': description,
          })
          .select()
          .single();

      return DailyVideoModel.fromJson(response);
    } catch (e) {
      _logger.e('Error uploading daily video', e);
      rethrow;
    }
  }

  Future<void> deleteVideo(DailyVideoModel video) async {
    try {
      // 1. Delete from R2
      // We extract the exact path from the CDN URL
      final urlParts = video.videoUrl.split('.dev/');
      if (urlParts.length == 2) {
        final r2Path = Uri.decodeComponent(urlParts[1]);
        await r2StorageService.deleteFile(r2Path);
      }

      // 2. Delete from Supabase
      await supabaseClient
          .from('daily_videos')
          .delete()
          .eq('id', video.id);
    } catch (e) {
      _logger.e('Error deleting daily video', e);
      rethrow;
    }
  }
}
