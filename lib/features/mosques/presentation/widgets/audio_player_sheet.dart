import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/recording.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../home/presentation/providers/favorites_provider.dart';
import '../../../home/presentation/providers/downloads_provider.dart';
import '../../../../core/di/providers.dart';

class AudioPlayerSheet extends ConsumerWidget {
  final Recording recording;

  const AudioPlayerSheet({super.key, required this.recording});

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
    final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

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

          // Title with favorite and download buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Download button (left)
              Consumer(
                builder: (context, ref, child) {
                  final isDownloadedAsync = ref.watch(
                    isDownloadedProvider(recording.id),
                  );

                  return isDownloadedAsync.when(
                    data: (isDownloaded) => IconButton(
                      onPressed: () async {
                        final downloadsService = ref.read(
                          downloadsServiceProvider,
                        );

                        if (isDownloaded) {
                          // Already downloaded, show message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'التسجيل محفوظ بالفعل',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          // Download
                          try {
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
                                      const SizedBox(width: 16),
                                      Text(
                                        'جاري التنزيل...',
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 30),
                                ),
                              );
                            }

                            await downloadsService.downloadRecording(recording);
                            ref.invalidate(isDownloadedProvider(recording.id));
                            ref.invalidate(allDownloadsProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم التنزيل بنجاح',
                                    style: GoogleFonts.cairo(),
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
                                  content: Text(
                                    'فشل التنزيل',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: Icon(
                        isDownloaded
                            ? LucideIcons.downloadCloud
                            : LucideIcons.download,
                        color: isDownloaded
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
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
                    error: (_, __) => const SizedBox(width: 48),
                  );
                },
              ),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text(
                      recording.prayer.arabicName,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recording.sheikhName,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Favorite button (right)
              isFavoriteAsync.when(
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
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: Colors.grey.shade700,
                          ),
                        );
                      }
                    } else {
                      try {
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                  icon: Icon(
                    LucideIcons.heart,
                    color: isFavorite
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                  ),
                  iconSize: 28,
                ),
                loading: () => const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Icon(
                  LucideIcons.heart,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ),
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
                icon: const Icon(
                  LucideIcons.rotateCcw,
                ), // Using rotateCcw as backward 15 equivalent
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
