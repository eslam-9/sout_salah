import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sout_salah/features/mosques/presentation/providers/daily_video_providers.dart';
import '../widgets/day_schedule_table_widget.dart';
import '../widgets/daily_video_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_args.dart';

import '../widgets/day_schedule_components/day_schedule_upload_button.dart';
import '../widgets/day_schedule_components/day_schedule_notification_button.dart';

class DaySchedulePage extends ConsumerWidget {
  final String dayId;
  final String mosqueId;
  final int dayNumber;
  final int month;

  const DaySchedulePage({
    super.key,
    required this.dayId,
    required this.mosqueId,
    required this.dayNumber,
    required this.month,
  });

  String _toArabicNumerals(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabic[i]);
    }
    return result;
  }

  Future<void> _showUploadVideoSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final uploaded = await NavigationService.navigateTo(
      AppRoutes.uploadDailyVideo,
      arguments: UploadDailyVideoArgs(
        mosqueId: mosqueId,
        dayId: dayId,
        dayNumber: dayNumber,
      ),
    );

    if (uploaded == true) {
      ref.invalidate(dailyVideoListProvider(dayId));
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
    final videoAsync = ref.watch(dailyVideoListProvider(dayId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'جدول شيوخ اليوم ${_toArabicNumerals(dayNumber)}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Daily Video Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: videoAsync.when(
                data: (videos) {
                  return Column(
                    children: [
                      if (videos.isNotEmpty) ...[
                        DailyVideoCard(dayId: dayId),
                        const SizedBox(height: 16),
                      ],
                      DayScheduleUploadButton(
                        mosqueId: mosqueId,
                        onUploadPressed: () =>
                            _showUploadVideoSheet(context, ref),
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
            ),

            // Schedule Matrix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DayScheduleTableWidget(dayId: dayId, mosqueId: mosqueId),
            ),

            // Notification Button
            DayScheduleNotificationButton(
              mosqueId: mosqueId,
              dayId: dayId,
              dayNumber: dayNumber,
              month: month,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
