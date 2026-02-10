import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/ramadan_day.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';
import '../providers/mosque_data_providers.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../domain/usecases/delete_recording_usecase.dart';
import '../widgets/audio_player_sheet.dart';
import 'upload_recording_page.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../home/presentation/providers/favorites_provider.dart';
import '../../../../core/di/providers.dart';

class DayDetailPage extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailPage({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(dayRecordingsProvider(day.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'RAMADAN 1445',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2E7D32),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Day ${day.dayNumber}',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: recordingsAsync.when(
        data: (recordings) => _buildPrayersList(recordings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPrayersList(List<Recording> recordings) {
    // Group recordings by prayer
    final prayerGroups = <Prayer, List<Recording>>{};
    for (var recording in recordings) {
      prayerGroups.putIfAbsent(recording.prayer, () => []).add(recording);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: Prayer.allPrayers.length,
      itemBuilder: (context, index) {
        final prayer = Prayer.allPrayers[index];
        final prayerRecordings = prayerGroups[prayer] ?? [];

        return _buildPrayerCard(prayer, prayerRecordings);
      },
    );
  }

  Widget _buildPrayerCard(Prayer prayer, List<Recording> recordings) {
    final hasRecording = recordings.isNotEmpty;
    final recording = hasRecording ? recordings.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasRecording
            ? null
            : Border.all(
                color: Colors.grey.shade200,
                width: 2,
                style: BorderStyle.solid,
              ),
      ),
      child: hasRecording
          ? _buildRecordingContent(recording!)
          : _buildEmptyPrayerContent(prayer),
    );
  }

  Widget _buildRecordingContent(Recording recording) {
    return Consumer(
      builder: (context, ref, child) {
        final audioService = ref.watch(audioPlayerServiceProvider);
        final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
        final isCurrentlyPlaying = currentPlayingId == recording.id;
        final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

        return Row(
          children: [
            // Upload/Download/Favorite icons (left side)
            Column(
              children: [
                Icon(LucideIcons.cloud, color: Colors.grey.shade400, size: 20),
                const SizedBox(height: 12),
                // Favorite button
                isFavoriteAsync.when(
                  data: (isFavorite) => InkWell(
                    onTap: () async {
                      final favoritesService = ref.read(
                        favoritesServiceProvider,
                      );

                      if (isFavorite) {
                        // Remove from favorites
                        await favoritesService.removeFavorite(recording.id);
                        ref.invalidate(isFavoriteProvider(recording.id));
                        ref.invalidate(allFavoritesProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم إزالة التلاوة من المحفوظات',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.grey.shade700,
                            ),
                          );
                        }
                      } else {
                        // Add to favorites with download
                        try {
                          // Show loading snackbar
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'جاري تحميل التلاوة...',
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 30),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          }

                          await favoritesService.addFavorite(recording);
                          ref.invalidate(isFavoriteProvider(recording.id));
                          ref.invalidate(allFavoritesProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❤️ تم حفظ التلاوة',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'فشل حفظ التلاوة',
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
                      LucideIcons.heart,
                      color: isFavorite
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  loading: () => SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  error: (_, __) => Icon(
                    LucideIcons.heart,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Delete button with permission check
                Consumer(
                  builder: (context, ref, child) {
                    final permissionChecker = ref.read(
                      permissionCheckerProvider,
                    );

                    return FutureBuilder<bool>(
                      future: permissionChecker.canShowDeleteButton(
                        recording.id,
                        recording.mosqueId,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == false) {
                          return const SizedBox.shrink();
                        }

                        return InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'حذف التلاوة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                content: Text(
                                  'هل أنت متأكد من حذف هذه التلاوة؟',
                                  style: GoogleFonts.cairo(),
                                  textAlign: TextAlign.right,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'إلغاء',
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'حذف',
                                      style: GoogleFonts.cairo(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final params = DeleteRecordingParams(
                                recordingId: recording.id,
                                mosqueId: recording.mosqueId,
                              );

                              final result = await ref
                                  .read(deleteRecordingUseCaseProvider)
                                  .call(params);

                              result.fold(
                                (failure) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل حذف التلاوة',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                (_) {
                                  // Refresh recordings
                                  ref.invalidate(dayRecordingsProvider(day.id));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم حذف التلاوة بنجاح',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }
                          },
                          child: Icon(
                            LucideIcons.trash2,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Prayer info (center)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recording.prayer.arabicName,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recording.sheikhName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Play button (right side)
            StreamBuilder<bool>(
              stream: audioService.player.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                final showPlayButton = !isCurrentlyPlaying || !isPlaying;

                return GestureDetector(
                  onTap: () async {
                    if (isCurrentlyPlaying) {
                      // If already playing, show the player sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            AudioPlayerSheet(recording: recording),
                      );
                    } else {
                      // Start playing
                      ref.read(currentPlayingRecordingProvider.notifier).state =
                          recording.id;
                      await audioService.play(
                        recording.audioUrl,
                        title: recording.prayer.arabicName,
                        artist: recording.sheikhName,
                      );

                      // Show player sheet after starting playback
                      if (context.mounted) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              AudioPlayerSheet(recording: recording),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showPlayButton ? LucideIcons.play : LucideIcons.barChart2,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyPrayerContent(Prayer prayer) {
    return Row(
      children: [
        // Upload icon
        Consumer(
          builder: (context, ref, child) {
            final permissionChecker = ref.read(permissionCheckerProvider);

            return FutureBuilder<bool>(
              future: permissionChecker.canShowUploadButton(day.mosqueId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false) {
                  return Icon(
                    LucideIcons.cloud,
                    color: Colors.grey.shade300,
                    size: 20,
                  );
                }

                return InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadRecordingPage(
                          mosqueId: day.mosqueId,
                          dayId: day.id,
                        ),
                      ),
                    );

                    if (result == true) {
                      ref.invalidate(dayRecordingsProvider(day.id));
                    }
                  },
                  child: Icon(
                    LucideIcons.uploadCloud,
                    color: const Color(0xFF2E7D32),
                    size: 20,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 16),

        // Prayer info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                prayer.arabicName,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Guest Reciter',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Disabled/muted icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.volume,
            color: Colors.grey.shade300,
            size: 24,
          ),
        ),
      ],
    );
  }
}
