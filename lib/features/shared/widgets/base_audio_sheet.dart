import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';

/// A reusable bottom sheet for audio playback.
/// Handles the UI for title, subtitle, sliders, and playback controls.
/// Supports optional leading and trailing actions (e.g., download, favorite) and extra info.
class BaseAudioSheet extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final Widget? extraInfo;

  const BaseAudioSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAction,
    this.trailingAction,
    this.extraInfo,
  });

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

          // Header Row (Title, Subtitle, Actions)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Leading Action (or placeholder for balance)
              if (leadingAction != null)
                leadingAction!
              else if (trailingAction != null)
                const SizedBox(width: 48), // Approximate size of IconButton

              const Spacer(),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (extraInfo != null) ...[
                      const SizedBox(height: 8),
                      extraInfo!,
                    ],
                  ],
                ),
              ),
              const Spacer(),

              // Trailing Action (or placeholder for balance)
              if (trailingAction != null)
                trailingAction!
              else if (leadingAction != null)
                const SizedBox(width: 48),
            ],
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
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: AppColors.primary,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble().clamp(
                        0.0,
                        duration.inSeconds > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0,
                      ),
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
                        color: AppColors.primary,
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
