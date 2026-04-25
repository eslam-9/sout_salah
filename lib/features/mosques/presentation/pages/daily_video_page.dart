import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/daily_video_providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_args.dart';
import '../../../../core/services/navigation_service.dart';
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    NavigationService.navigateTo(
                      AppRoutes.videoPlayer,
                      arguments: VideoPlayerArgs(video: video),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.playCircle,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title?.isNotEmpty == true
                                    ? video.title!
                                    : 'فيديو ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (video.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  video.description!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.chevronLeft, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: const Text(
            'حدث خطأ في تحميل الفيديوهات',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
