import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/downloads_provider.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/models/downloaded_recording.dart';
import '../../../../core/models/favorite_recording.dart';
import '../../../../core/di/providers.dart';
import '../widgets/favorite_audio_player_sheet.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(allDownloadsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'التنزيلات',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.download,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Downloads list
            Expanded(
              child: downloadsAsync.when(
                data: (downloads) {
                  if (downloads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.downloadCloud,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تنزيلات',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بتنزيل التسجيلات للاستماع بدون إنترنت',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final download = downloads[index];
                      return _buildDownloadCard(context, ref, download);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'حدث خطأ في تحميل التنزيلات',
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadCard(
    BuildContext context,
    WidgetRef ref,
    DownloadedRecording download,
  ) {
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
                  title: Text(
                    'حذف التنزيل',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  content: Text(
                    'هل تريد حذف هذا التنزيل؟ سيتم حذف الملف من جهازك.',
                    style: GoogleFonts.cairo(),
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('إلغاء', style: GoogleFonts.cairo()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(
                        'حذف',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
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
                      SnackBar(
                        content: Text(
                          'تم حذف التنزيل',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل حذف التنزيل',
                          style: GoogleFonts.cairo(),
                        ),
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
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  download.sheikhName,
                  style: GoogleFonts.cairo(
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
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
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
                  if (isCurrentlyPlaying && isPlaying) {
                    // If already playing, show the player sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => FavoriteAudioPlayerSheet(
                        favorite: _convertToFavoriteRecording(download),
                      ),
                    );
                  } else if (isCurrentlyPlaying && !isPlaying) {
                    await audioService.resume();
                    // Show player sheet after resuming
                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FavoriteAudioPlayerSheet(
                          favorite: _convertToFavoriteRecording(download),
                        ),
                      );
                    }
                  } else {
                    ref.read(currentPlayingRecordingProvider.notifier).state =
                        download.recordingId;
                    // Play from local file
                    await audioService.play(
                      download.localAudioPath,
                      title: download.prayerName,
                      artist: download.sheikhName,
                    );

                    // Show player sheet after starting playback
                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FavoriteAudioPlayerSheet(
                          favorite: _convertToFavoriteRecording(download),
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

  // Helper to convert DownloadedRecording to FavoriteRecording for the player sheet
  dynamic _convertToFavoriteRecording(DownloadedRecording download) {
    // We're using FavoriteAudioPlayerSheet which expects FavoriteRecording
    // Since they have the same structure, we can create a compatible object
    return FavoriteRecording(
      recordingId: download.recordingId,
      localAudioPath: download.localAudioPath,
      audioUrl:
          '', // Downloads don't store audioUrl, but it's not needed for local playback
      prayerName: download.prayerName,
      sheikhName: download.sheikhName,
      mosqueId: download.mosqueId,
      dayId: download.dayId,
      fileSize: download.fileSize,
      savedAt: download.downloadedAt,
    );
  }
}
