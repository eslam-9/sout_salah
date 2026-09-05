import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/downloads_provider.dart';

import '../widgets/downloads_components/downloads_header.dart';
import '../widgets/downloads_components/downloads_empty_state.dart';
import '../widgets/downloads_components/download_card.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';

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
            const DownloadsHeader(),

            // Downloads list
            Expanded(
              child: downloadsAsync.when(
                data: (downloads) {
                  if (downloads.isEmpty) {
                    return const DownloadsEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final download = downloads[index];
                      return DownloadCard(download: download);
                    },
                  );
                },
                loading: () => const AppLoadingIndicator(),
                error: (error, stack) => AppErrorView(
                  title: 'حدث خطأ',
                  message: 'حدث خطأ في تحميل التنزيلات',
                  onRetry: () => ref.invalidate(allDownloadsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
