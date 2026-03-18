import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/daily_video_providers.dart';
import '../widgets/daily_video_widget.dart';
import '../../../../core/theme/app_theme.dart';

class DailyVideoPage extends ConsumerWidget {
  final String dayId;

  const DailyVideoPage({super.key, required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsyncValue = ref.watch(dailyVideoListProvider(dayId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'فيديوهات اليوم',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: videosAsyncValue.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فيديوهات لهذا اليوم',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return DailyVideoWidget(video: video);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Text(
            'حدث خطأ في تحميل الفيديوهات',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
