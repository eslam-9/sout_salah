import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/day_schedule_table_widget.dart';
import '../widgets/daily_video_card.dart';
import '../widgets/upload_daily_video_sheet.dart';
import '../providers/daily_video_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../../core/services/notification_service.dart';

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

  Future<void> _showUploadVideoSheet(BuildContext context, WidgetRef ref) async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => UploadDailyVideoSheet(
        mosqueId: mosqueId,
        dayId: dayId,
        dayNumber: dayNumber,
      ),
    );

    if (uploaded == true) {
      ref.invalidate(dailyVideoProvider(dayId));
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
    final videoAsync = ref.watch(dailyVideoProvider(dayId));

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
                data: (video) {
                  if (video != null) {
                    return DailyVideoCard(video: video);
                  }

                  // No video found, show upload button if admin/publisher
                  return FutureBuilder<bool>(
                    future: ref.read(
                      permissionCheckerProvider.select(
                        (checker) => checker.canShowUploadButton(mosqueId),
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showUploadVideoSheet(context, ref),
                            icon: const Icon(LucideIcons.video, color: AppColors.primary),
                            label: const Text(
                              'إضافة فيديو اليوم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                      // Regular user, no video available
                      return const SizedBox.shrink();
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Text('فشل تحميل الفيديو', style: TextStyle(color: Colors.red)),
              ),
            ),

            // Schedule Matrix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DayScheduleTableWidget(
                dayId: dayId,
                mosqueId: mosqueId,
              ),
            ),
            
            // Notification Button
            FutureBuilder<bool>(
              future: ref.read(
                permissionCheckerProvider.select(
                  (checker) => checker.canShowUploadButton(mosqueId),
                ),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await NotificationService.sendNotification(
                            type: 'day_schedule',
                            data: {
                              'dayId': dayId,
                              'mosqueId': mosqueId,
                              'dayNumber': dayNumber,
                              'month': month,
                            },
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال الإشعار بنجاح', style: TextStyle()),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.send, color: Colors.white),
                        label: const Text(
                          'إرسال إشعار بالجدول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

