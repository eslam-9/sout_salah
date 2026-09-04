import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/route_args.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../domain/entities/prayer.dart';
import '../../../domain/entities/recording.dart';
import '../../../../../core/di/riverpod_providers.dart';

class DayRecordingPlayButton extends ConsumerWidget {
  final Recording recording;

  const DayRecordingPlayButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
    final isCurrentlyPlaying = currentPlayingId == recording.id;

    return StreamBuilder<bool>(
      stream: audioService.player.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final showPlayButton = !isCurrentlyPlaying || !isPlaying;
        return GestureDetector(
          onTap: () async {
            if (isCurrentlyPlaying) {
              NavigationService.navigateTo(
                AppRoutes.audioPlayer,
                arguments: AudioPlayerArgs(recording: recording),
              );
            } else {
              ref.read(currentPlayingRecordingProvider.notifier).state =
                  recording.id;
              audioService.play(
                recording.audioUrl,
                title: recording.prayer == Prayer.other
                    ? (recording.customPrayerName ?? 'أخرى')
                    : recording.prayer.arabicName,
                artist: recording.sheikhName,
              );
              if (context.mounted) {
                NavigationService.navigateTo(
                  AppRoutes.audioPlayer,
                  arguments: AudioPlayerArgs(recording: recording),
                );
              }
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              showPlayButton ? LucideIcons.play : LucideIcons.barChart2,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
