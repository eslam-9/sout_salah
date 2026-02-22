import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/di/providers.dart';
import '../../mosques/domain/entities/recording.dart';

/// Audio player widget for a recording
class AudioPlayerWidget extends ConsumerStatefulWidget {
  final Recording recording;

  const AudioPlayerWidget({super.key, required this.recording});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
    final isCurrentlyPlaying = currentPlayingId == widget.recording.id;

    return StreamBuilder<bool>(
      stream: audioService.player.playingStream,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;
        final showPlayButton = !isCurrentlyPlaying || !isPlaying;

        return Row(
          children: [
            // Play/Pause button
            IconButton(
              onPressed: () async {
                if (isCurrentlyPlaying) {
                  if (isPlaying) {
                    await audioService.pause();
                  } else {
                    await audioService.resume();
                  }
                } else {
                  ref.read(currentPlayingRecordingProvider.notifier).state =
                      widget.recording.id;
                  await audioService.play(
                    widget.recording.audioUrl,
                    title: widget.recording.prayer.arabicName,
                    artist: widget.recording.sheikhName,
                  );
                }
              },
              icon: Icon(
                showPlayButton ? LucideIcons.play : LucideIcons.pause,
                color: AppColors.primary,
              ),
            ),

            // Progress bar (only show if currently playing)
            if (isCurrentlyPlaying)
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioService.durationStream,
                      builder: (context, durationSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = durationSnapshot.data ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  final newPosition = Duration(
                                    milliseconds:
                                        (value * duration.inMilliseconds)
                                            .toInt(),
                                  );
                                  audioService.seek(newPosition);
                                },
                                activeColor: AppColors.primary,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

            // Stop button (only show if currently playing)
            if (isCurrentlyPlaying)
              IconButton(
                onPressed: () async {
                  await audioService.stop();
                  ref.read(currentPlayingRecordingProvider.notifier).state =
                      null;
                },
                icon: const Icon(LucideIcons.square, color: Colors.red),
              ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
