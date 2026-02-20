import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Audio player service for playing recordings
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// Play audio from URL with metadata for notification
  Future<void> play(
    String url, {
    String? title,
    String? artist,
    String? artUri,
  }) async {
    try {
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          album: "Sout Salah",
          title: title ?? "Unknown Title",
          artist: artist ?? "Unknown Sheikh",
          artUri: artUri != null ? Uri.parse(artUri) : null,
        ),
      );
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Get current position stream
  Stream<Duration> get positionStream => _player.positionStream;

  /// Get duration stream
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Get player state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Check if playing
  bool get isPlaying => _player.playing;

  /// Dispose player
  void dispose() {
    _player.dispose();
  }
}
