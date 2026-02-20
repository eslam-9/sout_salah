import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_recording.dart';
import '../../features/mosques/domain/entities/recording.dart';
import '../utils/app_logger.dart';

/// Service to manage favorite recordings with reactive updates
class FavoritesService {
  static const String _favoritesKey = 'favorite_recordings';
  final SharedPreferences _prefs;
  final AppLogger _logger;
  late final StreamController<List<FavoriteRecording>> _favoritesController;

  FavoritesService(this._prefs, this._logger) {
    _favoritesController = StreamController<List<FavoriteRecording>>.broadcast(
      onListen: () {
        _emitFavorites();
      },
    );
  }

  /// Get stream of favorites for reactive updates
  Stream<List<FavoriteRecording>> get favoritesStream =>
      _favoritesController.stream;

  /// Emit current favorites to the stream
  Future<void> _emitFavorites() async {
    try {
      final favorites = await getFavorites();
      _favoritesController.add(favorites);
    } catch (e) {
      _logger.e('❌ Error emitting favorites: $e');
    }
  }

  /// Add a recording to favorites and download the audio file
  Future<void> addFavorite(Recording recording) async {
    try {
      // Check if already favorited
      if (await isFavorite(recording.id)) {
        _logger.i('Recording ${recording.id} is already favorited');
        return;
      }

      String localPath = '';
      int? fileSize;

      // Check if recording is already downloaded
      // We'll check if file exists in downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      final possiblePath = '${downloadsDir.path}/${recording.id}.mp3';
      final downloadedFile = File(possiblePath);

      if (await downloadedFile.exists()) {
        // File is already downloaded, use existing file
        localPath = possiblePath;
        fileSize = await downloadedFile.length();
        _logger.i('✅ Using existing downloaded file for favorite');
      } else {
        // File not downloaded, just save metadata with streaming URL
        localPath = '';
        _logger.i('✅ Adding favorite without local file (will stream)');
      }

      // Create favorite recording object
      final favorite = FavoriteRecording(
        recordingId: recording.id,
        localAudioPath: localPath,
        audioUrl: recording.audioUrl,
        prayerName: recording.prayer.arabicName,
        sheikhName: recording.sheikhName,
        mosqueId: recording.mosqueId,
        dayId: recording.dayId,
        fileSize: fileSize,
        savedAt: DateTime.now(),
      );

      // Save to shared preferences
      final favorites = await getFavorites();
      favorites.add(favorite);
      await _saveFavorites(favorites);

      // Notify listeners
      _favoritesController.add(favorites);

      _logger.i('✅ Added recording ${recording.id} to favorites');
    } catch (e, stackTrace) {
      _logger.e('❌ Error adding favorite: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Remove a recording from favorites (keeps downloaded file)
  Future<void> removeFavorite(String recordingId) async {
    try {
      final favorites = await getFavorites();
      // Verify existence but we filter anyway
      final exists = favorites.any((f) => f.recordingId == recordingId);
      if (!exists) {
        throw Exception('Recording not found in favorites');
      }

      // NOTE: We no longer delete the local file here
      // The file is managed by DownloadsService if it was a download
      // If it was only a favorite, we technically leave it?
      // The previous logic didn't delete because of "downloaded file sharing".
      // But if it was downloaded specifically for favorites (into `favorites` dir), it might be orphan.
      // However, keeping it simple as per original logic.

      // Remove from favorites list
      favorites.removeWhere((f) => f.recordingId == recordingId);
      await _saveFavorites(favorites);

      // Notify listeners
      _favoritesController.add(favorites);

      _logger.i('✅ Removed recording $recordingId from favorites (file kept)');
    } catch (e, stackTrace) {
      _logger.e('❌ Error removing favorite: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Check if a recording is favorited
  Future<bool> isFavorite(String recordingId) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.recordingId == recordingId);
  }

  /// Get all favorite recordings
  Future<List<FavoriteRecording>> getFavorites() async {
    try {
      final String? favoritesJson = _prefs.getString(_favoritesKey);
      if (favoritesJson == null) {
        return [];
      }

      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList
          .map((json) => FavoriteRecording.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('❌ Error loading favorites: $e');
      return [];
    }
  }

  /// Save favorites list to shared preferences
  Future<void> _saveFavorites(List<FavoriteRecording> favorites) async {
    final favoritesJson = jsonEncode(favorites.map((f) => f.toJson()).toList());
    await _prefs.setString(_favoritesKey, favoritesJson);
  }

  /// Dispose the stream controller
  void dispose() {
    _favoritesController.close();
  }
}
