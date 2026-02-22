import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/recording.dart';
import '../../../home/presentation/providers/favorites_provider.dart';
import '../../../home/presentation/providers/downloads_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/base_audio_sheet.dart';

class AudioPlayerSheet extends ConsumerWidget {
  final Recording recording;

  const AudioPlayerSheet({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We don't need to watch audioService here as it's handled in BaseAudioSheet

    return BaseAudioSheet(
      title: recording.prayer.arabicName,
      subtitle: recording.sheikhName,
      leadingAction: Consumer(
        builder: (context, ref, child) {
          final isDownloadedAsync = ref.watch(
            isDownloadedProvider(recording.id),
          );

          return isDownloadedAsync.when(
            data: (isDownloaded) {
              final downloadsService = ref.read(downloadsServiceProvider);

              if (isDownloaded) {
                return IconButton(
                  onPressed: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'التسجيل محفوظ بالفعل',
                            style: TextStyle(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    LucideIcons.downloadCloud,
                    color: Colors.green,
                  ),
                );
              }

              return StreamBuilder<double>(
                stream: downloadsService.progressStream(recording.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Downloading
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
                              '${(snapshot.data! * 100).toInt()}%',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return IconButton(
                    onPressed: () async {
                      try {
                        await downloadsService.downloadRecording(recording);
                        ref.invalidate(isDownloadedProvider(recording.id));
                        ref.invalidate(allDownloadsProvider);

                        if (context.mounted) {
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'فشل التنزيل: $e',
                                style: TextStyle(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      LucideIcons.download,
                      color: Colors.grey.shade600,
                    ),
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
            error: (_, s) => const SizedBox(width: 48),
          );
        },
      ),
      trailingAction: Consumer(
        builder: (context, ref, _) {
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
                                style: TextStyle(),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 30),
                          backgroundColor: AppColors.primary,
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
                            style: TextStyle(),
                          ),
                          backgroundColor: AppColors.primary,
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
                            style: TextStyle(),
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
                color: isFavorite ? Colors.red.shade400 : Colors.grey.shade400,
              ),
              iconSize: 28,
            ),
            loading: () => const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, s) =>
                Icon(LucideIcons.heart, color: Colors.grey.shade400, size: 28),
          );
        },
      ),
    );
  }
}
