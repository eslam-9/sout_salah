import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/favorites_provider.dart';
import '../../../../../core/di/riverpod_providers.dart';
import '../../../../../core/models/favorite_recording.dart';

import '../../../../mosques/domain/entities/prayer.dart';
import '../../../../mosques/domain/entities/recording.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/route_args.dart';
import '../../../../../core/services/navigation_service.dart';

class SavedRecordingCard extends ConsumerWidget {
  final FavoriteRecording favorite;

  const SavedRecordingCard({
    super.key,
    required this.favorite,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Helper to convert FavoriteRecording to Recording for the player page
  Recording _convertToRecording(FavoriteRecording favorite) {
    // Try to find matching prayer, default to Fajr if not found
    final prayer = Prayer.values.firstWhere(
      (p) =>
          p.englishName == favorite.prayerName ||
          p.arabicName == favorite.prayerName,
      orElse: () => Prayer.fajr,
    );

    return Recording(
      id: favorite.recordingId,
      mosqueId: favorite.mosqueId,
      dayId: favorite.dayId,
      prayer: prayer,
      sheikhName: favorite.sheikhName,
      audioUrl: favorite.localAudioPath.isNotEmpty
          ? favorite.localAudioPath
          : favorite.audioUrl,
      fileSize: favorite.fileSize,
      createdAt: favorite.savedAt,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
    final isCurrentlyPlaying = currentPlayingId == favorite.recordingId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Remove from favorites button
          InkWell(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'إزالة من المحفوظات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  content: const Text(
                    'هل تريد إزالة هذه التلاوة من المحفوظات؟',
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('إزالة', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(favoritesServiceProvider)
                      .removeFavorite(favorite.recordingId);

                  // Refresh the list
                  ref.invalidate(allFavoritesProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم إزالة التلاوة من المحفوظات',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('فشل إزالة التلاوة'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Icon(
              LucideIcons.heart,
              color: Colors.red.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Recording info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  favorite.prayerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  favorite.sheikhName,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (favorite.fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(favorite.fileSize!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Play button
          StreamBuilder<bool>(
            stream: audioService.player.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              final showPlayButton = !isCurrentlyPlaying || !isPlaying;

              return GestureDetector(
                onTap: () async {
                  if (isCurrentlyPlaying) {
                    // Navigate to player page
                    NavigationService.navigateTo(
                      AppRoutes.audioPlayer,
                      arguments: AudioPlayerArgs(
                        recording: _convertToRecording(favorite),
                      ),
                    );
                  } else {
                    ref.read(currentPlayingRecordingProvider.notifier).state =
                        favorite.recordingId;
                    // Play from local file if available, otherwise stream
                    // Start playing (don't await to avoid UI delay)
                    final path = favorite.localAudioPath.isNotEmpty
                        ? favorite.localAudioPath
                        : favorite.audioUrl;

                    audioService.play(
                      path,
                      title: favorite.prayerName,
                      artist: favorite.sheikhName,
                    );

                    // Navigate immediately
                    if (context.mounted) {
                      NavigationService.navigateTo(
                        AppRoutes.audioPlayer,
                        arguments: AudioPlayerArgs(
                          recording: _convertToRecording(favorite),
                        ),
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
                    showPlayButton ? LucideIcons.play : LucideIcons.pause,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
