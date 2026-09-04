import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/riverpod_providers.dart';

class AudioPlayerControls extends ConsumerWidget {
  const AudioPlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 15s backward
        IconButton(
          onPressed: () async {
            final position = audioService.player.position;
            await audioService.seek(
              position + const Duration(seconds: 15),
            );
          },
          icon: const Icon(LucideIcons.rotateCcw),
          color: Colors.grey.shade600,
          iconSize: 32,
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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(22),
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  playing == true ? LucideIcons.pause : LucideIcons.play,
                  color: Colors.white,
                  size: 40,
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
              position - const Duration(seconds: 15),
            );
          },
          icon: const Icon(LucideIcons.rotateCw),
          color: Colors.grey.shade600,
          iconSize: 32,
        ),
      ],
    );
  }
}
