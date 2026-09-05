import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/permission_checker.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/route_args.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../domain/entities/ramadan_day.dart';
import '../../providers/daily_video_providers.dart';
import '../daily_video_card.dart';

class DayDetailVideoSection extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailVideoSection({super.key, required this.day});

  void _showUploadVideoSheet(BuildContext context, WidgetRef ref) async {
    final uploaded = await NavigationService.navigateTo(
      AppRoutes.uploadDailyVideo,
      arguments: UploadDailyVideoArgs(
        mosqueId: day.mosqueId,
        dayId: day.id,
        dayNumber: day.dayNumber,
      ),
    );

    if (uploaded == true) {
      ref.invalidate(dailyVideoListProvider(day.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الفيديو بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(dailyVideoListProvider(day.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: videoAsync.when(
        data: (videos) {
          return Column(
            children: [
              if (videos.isNotEmpty) ...[
                DailyVideoCard(dayId: day.id),
                const SizedBox(height: 16),
              ],
              FutureBuilder<bool>(
                future: ref.read(
                  permissionCheckerProvider.select(
                    (checker) => checker.canShowUploadButton(day.mosqueId),
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showUploadVideoSheet(context, ref),
                        icon: const Icon(
                          LucideIcons.video,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'إضافة فيديوهات اليوم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Text(
          'فشل تحميل الفيديو',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
