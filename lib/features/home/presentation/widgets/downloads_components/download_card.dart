import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/downloads_provider.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/models/downloaded_recording.dart';

import '../../../../mosques/domain/entities/prayer.dart';
import '../../../../mosques/domain/entities/recording.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/route_args.dart';
import '../../../../../core/services/navigation_service.dart';

class DownloadCard extends ConsumerWidget {
  final DownloadedRecording download;

  const DownloadCard({
    super.key,
    required this.download,
  });

  // Helper to convert DownloadedRecording to Recording for the player page
  Recording _convertToRecording(DownloadedRecording download) {
    // Try to find matching prayer, default to Fajr if not found
    final prayer = Prayer.values.firstWhere(
      (p) =>
          p.englishName == download.prayerName ||
          p.arabicName == download.prayerName,
      orElse: () => Prayer.fajr,
    );

    return Recording(
      id: download.recordingId,
      mosqueId: download.mosqueId,
      dayId: download.dayId,
      prayer: prayer,
      sheikhName: download.sheikhName,
      audioUrl: download.localAudioPath, // Use local path
      fileSize: download.fileSize,
      createdAt: download.downloadedAt,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
    final isCurrentlyPlaying = currentPlayingId == download.recordingId;

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
          // Delete button
          InkWell(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'حذف التنزيل',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  content: const Text(
                    'هل تريد حذف هذا التنزيل؟ سيتم حذف الملف من جهازك.',
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text(
                        'حذف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(downloadsServiceProvider)
                      .removeDownload(download.recordingId);
                  // Refresh the list
                  ref.invalidate(allDownloadsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف التنزيل'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('فشل حذف التنزيل'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Icon(
              LucideIcons.trash2,
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
                  download.prayerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  download.sheikhName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
                if (download.fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(download.fileSize! / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.right,
                  ),
                ],
                // Progress indicator during active download (if any)
                StreamBuilder<double>(
                  stream: ref
                      .watch(downloadsServiceProvider)
                      .progressStream(download.recordingId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: snapshot.data,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.primary,
                          minHeight: 4,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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
                        recording: _convertToRecording(download),
                      ),
                    );
                  } else {
                    ref.read(currentPlayingRecordingProvider.notifier).state =
                        download.recordingId;
                    // Play from local file (don't await to avoid UI delay)
                    audioService.play(
                      download.localAudioPath,
                      title: download.prayerName,
                      artist: download.sheikhName,
                    );

                    // Navigate immediately
                    if (context.mounted) {
                      NavigationService.navigateTo(
                        AppRoutes.audioPlayer,
                        arguments: AudioPlayerArgs(
                          recording: _convertToRecording(download),
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
