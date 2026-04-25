import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recording.dart';
import '../../../home/presentation/providers/downloads_provider.dart';
import '../../../home/presentation/providers/favorites_provider.dart';

class AudioPlayerPage extends ConsumerWidget {
  final Recording recording;

  const AudioPlayerPage({super.key, required this.recording});

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تشغيل التلاوة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Artwork
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.bookOpen,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),

              // Title and Sheikh name
              Text(
                recording.prayer.arabicName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                recording.sheikhName,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action Buttons (Download, Favorite)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Download Button
                  _buildDownloadButton(context, ref),
                  const SizedBox(width: 32),
                  // Favorite Button
                  _buildFavoriteButton(context, ref),
                ],
              ),
              const SizedBox(height: 48),

              // Slider and Times
              StreamBuilder<Duration>(
                stream: audioService.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration =
                      audioService.player.duration ?? Duration.zero;

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
                            if (duration.inSeconds > 0) {
                              audioService.seek(
                                Duration(seconds: value.toInt()),
                              );
                            }
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Playback Controls
              Row(
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
                            playing == true
                                ? LucideIcons.pause
                                : LucideIcons.play,
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
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, WidgetRef ref) {
    final isDownloadedAsync = ref.watch(isDownloadedProvider(recording.id));

    return isDownloadedAsync.when(
      data: (isDownloaded) {
        if (isDownloaded) {
          return IconButton(
            onPressed: () async {
              final downloadsService = ref.read(downloadsServiceProvider);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'حذف التنزيل',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  content: Text(
                    'هل تريد حذف هذا التنزيل؟ سيتم حذف الملف من جهازك.',
                    style: TextStyle(),
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('إلغاء', style: TextStyle()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(
                        'حذف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await downloadsService.removeDownload(recording.id);
                  ref.invalidate(isDownloadedProvider(recording.id));
                  ref.invalidate(allDownloadsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حذف التنزيل', style: TextStyle()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل حذف التنزيل', style: TextStyle()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(LucideIcons.downloadCloud, color: Colors.green),
            iconSize: 28,
            tooltip: 'حذف التنزيل',
          );
        }

        return Consumer(
          builder: (context, ref, child) {
            final downloadsService = ref.watch(downloadsServiceProvider);
            return StreamBuilder<double>(
              stream: downloadsService.progressStream(recording.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: snapshot.data,
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                          Text(
                            '${(snapshot.data! * 100).toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return IconButton(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text('جاري التنزيل...', style: TextStyle()),
                            ],
                          ),
                          duration: const Duration(seconds: 30),
                          backgroundColor: AppColors.primary,
                        ),
                      );

                      await downloadsService.downloadRecording(recording);
                      ref.invalidate(isDownloadedProvider(recording.id));
                      ref.invalidate(allDownloadsProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم التنزيل بنجاح',
                              style: TextStyle(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل التنزيل', style: TextStyle()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(LucideIcons.download, color: Colors.grey.shade600),
                  iconSize: 28,
                  tooltip: 'تنزيل',
                );
              },
            );
          },
        );
      },
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox(width: 48),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        onPressed: () async {
          final favoritesService = ref.read(favoritesServiceProvider);

          if (isFavorite) {
            await favoritesService.removeFavorite(recording.id);
            ref.invalidate(isFavoriteProvider(recording.id));
            ref.invalidate(allFavoritesProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم إزالة التلاوة من المحفوظات',
                    style: TextStyle(),
                  ),
                  backgroundColor: Colors.grey.shade700,
                ),
              );
            }
          } else {
            try {
              await favoritesService.addFavorite(recording);
              ref.invalidate(isFavoriteProvider(recording.id));
              ref.invalidate(allFavoritesProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❤️ تم حفظ التلاوة', style: TextStyle()),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل حفظ التلاوة', style: TextStyle()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        icon: Icon(
          LucideIcons.heart,
          color: isFavorite ? Colors.red.shade400 : Colors.grey.shade400,
        ),
        iconSize: 28,
        tooltip: 'إضافة للمفضلة',
      ),
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) =>
          Icon(LucideIcons.heart, color: Colors.grey.shade400, size: 28),
    );
  }
}
