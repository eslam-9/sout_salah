import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_recording.dart';
import '../../features/mosques/domain/entities/recording.dart';

/// Service to manage downloaded recordings
class DownloadsService {
  static const String _downloadsKey = 'downloaded_recordings';
  final SharedPreferences _prefs;

  DownloadsService(this._prefs);

  /// Download a recording and save metadata
  Future<void> downloadRecording(Recording recording) async {
    try {
      // Check if already downloaded
      if (await isDownloaded(recording.id)) {
        debugPrint('Recording ${recording.id} is already downloaded');
        return;
      }

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Download the audio file
      final fileName = '${recording.id}.mp3';
      final filePath = '${downloadsDir.path}/$fileName';

      debugPrint('📥 Downloading audio from: ${recording.audioUrl}');
      final response = await http.get(Uri.parse(recording.audioUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ Audio file saved to: $filePath');

        // Save metadata
        final download = DownloadedRecording(
          recordingId: recording.id,
          localAudioPath: filePath,
          prayerName: recording.prayer.arabicName,
          sheikhName: recording.sheikhName,
          mosqueId: recording.mosqueId,
          dayId: recording.dayId,
          fileSize: response.bodyBytes.length,
          downloadedAt: DateTime.now(),
        );

        await _saveDownload(download);
        debugPrint('✅ Recording downloaded successfully');
      } else {
        throw Exception('Failed to download audio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error downloading recording: $e');
      rethrow;
    }
  }

  /// Remove a download and delete the local file
  Future<void> removeDownload(String recordingId) async {
    try {
      final downloads = await getDownloads();
      final download = downloads.firstWhere(
        (d) => d.recordingId == recordingId,
        orElse: () => throw Exception('Download not found'),
      );

      // Delete the local file
      final file = File(download.localAudioPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted audio file: ${download.localAudioPath}');
      }

      // Remove from metadata
      final updatedDownloads = downloads
          .where((d) => d.recordingId != recordingId)
          .toList();
      await _saveAllDownloads(updatedDownloads);
      debugPrint('✅ Download removed successfully');
    } catch (e) {
      debugPrint('❌ Error removing download: $e');
      rethrow;
    }
  }

  /// Check if a recording is downloaded
  Future<bool> isDownloaded(String recordingId) async {
    final downloads = await getDownloads();
    return downloads.any((d) => d.recordingId == recordingId);
  }

  /// Get all downloaded recordings
  Future<List<DownloadedRecording>> getDownloads() async {
    final jsonString = _prefs.getString(_downloadsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map(
          (json) => DownloadedRecording.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get a specific download by recording ID
  Future<DownloadedRecording?> getDownload(String recordingId) async {
    final downloads = await getDownloads();
    try {
      return downloads.firstWhere((d) => d.recordingId == recordingId);
    } catch (e) {
      return null;
    }
  }

  /// Stream of downloads for reactive updates
  Stream<List<DownloadedRecording>> downloadsStream() async* {
    while (true) {
      yield await getDownloads();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Save a single download
  Future<void> _saveDownload(DownloadedRecording download) async {
    final downloads = await getDownloads();
    downloads.add(download);
    await _saveAllDownloads(downloads);
  }

  /// Save all downloads
  Future<void> _saveAllDownloads(List<DownloadedRecording> downloads) async {
    final jsonList = downloads.map((d) => d.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs.setString(_downloadsKey, jsonString);
  }
}
