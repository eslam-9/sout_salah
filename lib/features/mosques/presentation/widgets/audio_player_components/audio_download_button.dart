import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/riverpod_providers.dart';
import '../../../domain/entities/recording.dart';
import '../../../../home/presentation/providers/downloads_provider.dart';

class AudioDownloadButton extends ConsumerWidget {
  final Recording recording;

  const AudioDownloadButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  await downloadsService.removeDownload(recording.id);
                  ref.invalidate(isDownloadedProvider(recording.id));
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
                            style: const TextStyle(
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
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('جاري التنزيل...'),
                            ],
                          ),
                          duration: Duration(seconds: 30),
                          backgroundColor: AppColors.primary,
                        ),
                      );

                      await downloadsService.downloadRecording(recording);
                      ref.invalidate(isDownloadedProvider(recording.id));
                      ref.invalidate(allDownloadsProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم التنزيل بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('فشل التنزيل'),
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
}
