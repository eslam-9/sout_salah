import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../home/presentation/providers/downloads_provider.dart';
import '../../../../../core/di/providers.dart';
import '../../../domain/entities/recording.dart';

class DayRecordingDownloadButton extends ConsumerWidget {
  final Recording recording;

  const DayRecordingDownloadButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsService = ref.watch(downloadsServiceProvider);
    final isDownloadedAsync = ref.watch(isDownloadedProvider(recording.id));

    return isDownloadedAsync.when(
      data: (isDownloaded) {
        if (isDownloaded) {
          return const Icon(
            LucideIcons.cloud,
            color: AppColors.primary,
            size: 20,
          );
        }
        return StreamBuilder<double>(
          stream: downloadsService.progressStream(recording.id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: snapshot.data,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                    Text(
                      '${(snapshot.data! * 100).toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return InkWell(
              onTap: () async {
                try {
                  await downloadsService.downloadRecording(recording);
                  ref.invalidate(isDownloadedProvider(recording.id));
                  ref.invalidate(allDownloadsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل التنزيل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Icon(
                LucideIcons.download,
                color: Colors.grey.shade400,
                size: 20,
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, s) =>
          const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
    );
  }
}
