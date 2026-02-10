import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/favorite_recording.dart';
import '../../../../core/services/audio_player_service.dart';

/// Audio player sheet for favorite recordings
class FavoriteAudioPlayerSheet extends ConsumerWidget {
  final FavoriteRecording favorite;

  const FavoriteAudioPlayerSheet({super.key, required this.favorite});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            favorite.prayerName,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            favorite.sheikhName,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Offline indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.download,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'محفوظ للتشغيل بدون إنترنت',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Slider and times layout
          StreamBuilder<Duration>(
            stream: audioService.player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = audioService.player.duration ?? Duration.zero;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF2E7D32),
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: const Color(0xFF2E7D32),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      value: position.inSeconds
                          .toDouble()
                          .clamp(
                            0.0,
                            duration.inSeconds > 0
                                ? duration.inSeconds.toDouble()
                                : 1.0,
                          )
                          .toDouble(),
                      max: duration.inSeconds > 0
                          ? duration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: (value) {
                        // Only allow seeking if duration is valid
                        if (duration.inSeconds > 0) {
                          audioService.seek(Duration(seconds: value.toInt()));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 15s backward
              IconButton(
                onPressed: () async {
                  final position = audioService.player.position;
                  await audioService.seek(
                    position - const Duration(seconds: 15),
                  );
                },
                icon: const Icon(LucideIcons.rotateCcw),
                color: Colors.grey.shade600,
                iconSize: 28,
              ),
              const SizedBox(width: 32),

              // Play/Pause
              StreamBuilder<PlayerState>(
                stream: audioService.player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () async {
                      if (playing == true) {
                        await audioService.pause();
                      } else {
                        await audioService.resume();
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        playing == true ? LucideIcons.pause : LucideIcons.play,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 32),

              // 15s forward
              IconButton(
                onPressed: () async {
                  final position = audioService.player.position;
                  await audioService.seek(
                    position + const Duration(seconds: 15),
                  );
                },
                icon: const Icon(LucideIcons.rotateCw),
                color: Colors.grey.shade600,
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
