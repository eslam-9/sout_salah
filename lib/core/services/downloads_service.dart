import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_recording.dart';
import '../../features/mosques/domain/entities/recording.dart';
import '../utils/app_logger.dart';
import '../constants/app_constants.dart';

/// Service to manage downloaded recordings with reactive updates
class DownloadsService {
  static const String _downloadsKey = 'downloaded_recordings';
  final SharedPreferences _prefs;
  final Dio _dio;
  final AppLogger _logger;

  // Stream controller for the list of downloaded recordings
  late final StreamController<List<DownloadedRecording>> _downloadsController;

  // Stream controllers for individual download progress
  final Map<String, StreamController<double>> _progressControllers = {};

  // Cancel tokens for active downloads
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadsService(this._prefs, this._dio, this._logger) {
    _downloadsController =
        StreamController<List<DownloadedRecording>>.broadcast(
          onListen: () {
            _emitDownloads();
          },
        );
  }

  /// Get stream of downloads for reactive updates
  Stream<List<DownloadedRecording>> get downloadsStream =>
      _downloadsController.stream;

  /// Get progress stream for a specific recording
  Stream<double> progressStream(String recordingId) {
    _progressControllers.putIfAbsent(
      recordingId,
      () => StreamController<double>.broadcast(),
    );
    return _progressControllers[recordingId]!.stream;
  }

  /// Emit current downloads to the stream
  Future<void> _emitDownloads() async {
    try {
      final downloads = await getDownloads();
      _downloadsController.add(downloads);
    } catch (e) {
      _logger.e('❌ Error emitting downloads: $e');
    }
  }

  /// Download a recording and save metadata
  Future<void> downloadRecording(Recording recording) async {
    final recordingId = recording.id;
    String? localFilePath;

    try {
      // Check if already downloaded
      if (await isDownloaded(recordingId)) {
        _logger.i('Recording $recordingId is already downloaded');
        return;
      }

      // Check if already downloading (prevent duplicate downloads)
      if (_cancelTokens.containsKey(recordingId)) {
        _logger.w('Recording $recordingId is already downloading');
        return;
      }

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Prepare file path and cancel token
      final fileName = '$recordingId.mp3';
      final filePath = '${downloadsDir.path}/$fileName';
      localFilePath = filePath;
      final cancelToken = CancelToken();
      _cancelTokens[recordingId] = cancelToken;

      // Initialize progress controller
      if (!_progressControllers.containsKey(recordingId)) {
        _progressControllers[recordingId] =
            StreamController<double>.broadcast();
      }
      _progressControllers[recordingId]!.add(0.0);

      _logger.i('📥 Downloading audio from: ${recording.audioUrl}');

      await _dio.download(
        recording.audioUrl,
        filePath,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: NetworkConfig.audioTimeout),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _progressControllers[recordingId]?.add(progress);
          }
        },
      );

      _logger.i('✅ Audio file saved to: $filePath');

      // Save metadata
      final file = File(filePath);
      final fileSize = await file.length();

      final download = DownloadedRecording(
        recordingId: recordingId,
        localAudioPath: filePath,
        prayerName: recording.prayer.arabicName,
        sheikhName: recording.sheikhName,
        mosqueId: recording.mosqueId,
        dayId: recording.dayId,
        fileSize: fileSize,
        downloadedAt: DateTime.now(),
      );

      await _saveDownload(download);
      _logger.i('✅ Recording downloaded successfully');

      // Update stream
      await _emitDownloads();
    } catch (e) {
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          _logger.i('ℹ️ Download canceled for $recordingId');
        } else {
          _logger.e('❌ Network error downloading recording: $e');
        }

        // Clean up partial file on failure or manual cancellation
        if (localFilePath != null) {
          final file = File(localFilePath);
          if (await file.exists()) {
            await file.delete();
            _logger.i('🗑️ Cleaned up partial download: $localFilePath');
          }
        }

        if (!CancelToken.isCancel(e)) {
          rethrow;
        }
      } else {
        _logger.e('❌ Error downloading recording: $e');

        if (localFilePath != null) {
          final file = File(localFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        rethrow;
      }
    } finally {
      _cancelTokens.remove(recordingId);
      _progressControllers[recordingId]?.close();
      _progressControllers.remove(recordingId);
    }
  }

  /// Cancel a download
  void cancelDownload(String recordingId) {
    if (_cancelTokens.containsKey(recordingId)) {
      _cancelTokens[recordingId]?.cancel();
      _cancelTokens.remove(recordingId);
    }
  }

  /// Remove a download and delete the local file
  Future<void> removeDownload(String recordingId) async {
    try {
      // If currently downloading, cancel it first
      if (_cancelTokens.containsKey(recordingId)) {
        cancelDownload(recordingId);
        return;
      }

      final downloads = await getDownloads();
      final download = downloads.firstWhere(
        (d) => d.recordingId == recordingId,
        orElse: () => throw Exception('Download not found'),
      );

      // Delete the local file
      final file = File(download.localAudioPath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('🗑️ Deleted audio file: ${download.localAudioPath}');
      }

      // Remove from metadata
      final updatedDownloads = downloads
          .where((d) => d.recordingId != recordingId)
          .toList();
      await _saveAllDownloads(updatedDownloads);
      _logger.i('✅ Download removed successfully');

      // Update stream
      await _emitDownloads();
    } catch (e) {
      _logger.e('❌ Error removing download: $e');
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
    try {
      final jsonString = _prefs.getString(_downloadsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (json) =>
                DownloadedRecording.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      _logger.e('❌ Error loading downloads: $e');
      return [];
    }
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

  /// Dispose the stream controller
  void dispose() {
    _downloadsController.close();
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
  }
}
