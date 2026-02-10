import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_recording.dart';
import '../../features/mosques/domain/entities/recording.dart';

/// Service to manage favorite recordings with local audio file storage
class FavoritesService {
  static const String _favoritesKey = 'favorite_recordings';
  final SharedPreferences _prefs;
  final StreamController<List<FavoriteRecording>> _favoritesController =
      StreamController<List<FavoriteRecording>>.broadcast();

  FavoritesService(this._prefs);

  /// Get stream of favorites for reactive updates
  Stream<List<FavoriteRecording>> get favoritesStream =>
      _favoritesController.stream;

  /// Add a recording to favorites and download the audio file
  Future<void> addFavorite(Recording recording) async {
    try {
      // Check if already favorited
      if (await isFavorite(recording.id)) {
        debugPrint('Recording ${recording.id} is already favorited');
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
        debugPrint('✅ Using existing downloaded file for favorite');
      } else {
        // File not downloaded, download it now
        localPath = await _downloadAudioFile(recording.audioUrl, recording.id);
        final file = File(localPath);
        fileSize = await file.length();
        debugPrint('✅ Downloaded file for favorite');
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

      debugPrint('✅ Added recording ${recording.id} to favorites');
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove a recording from favorites (keeps downloaded file)
  Future<void> removeFavorite(String recordingId) async {
    try {
      final favorites = await getFavorites();
      final favorite = favorites.firstWhere(
        (f) => f.recordingId == recordingId,
        orElse: () => throw Exception('Recording not found in favorites'),
      );

      // NOTE: We no longer delete the local file here
      // The file is managed by DownloadsService
      // This allows users to keep downloaded files even after unfavoriting

      // Remove from favorites list
      favorites.removeWhere((f) => f.recordingId == recordingId);
      await _saveFavorites(favorites);

      // Notify listeners
      _favoritesController.add(favorites);

      debugPrint('✅ Removed recording $recordingId from favorites (file kept)');
    } catch (e, stackTrace) {
      debugPrint('❌ Error removing favorite: $e');
      debugPrint('Stack trace: $stackTrace');
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
      debugPrint('❌ Error loading favorites: $e');
      return [];
    }
  }

  /// Download audio file from URL and save locally
  Future<String> _downloadAudioFile(String url, String recordingId) async {
    try {
      debugPrint('📥 Downloading audio file for recording $recordingId...');

      // Get app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final favoritesDir = Directory('${directory.path}/favorites');

      // Create favorites directory if it doesn't exist
      if (!await favoritesDir.exists()) {
        await favoritesDir.create(recursive: true);
      }

      // Create file path
      final filePath = '${favoritesDir.path}/$recordingId.mp3';

      // Download the file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ Downloaded audio file to: $filePath');
        return filePath;
      } else {
        throw Exception(
          'Failed to download audio file: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error downloading audio file: $e');
      rethrow;
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
