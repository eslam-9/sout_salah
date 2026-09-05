import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/permission_checker.dart';
import '../../../../../core/services/notification_service.dart';

class DayScheduleNotificationButton extends ConsumerWidget {
  final String mosqueId;
  final String dayId;
  final int dayNumber;
  final int month;

  const DayScheduleNotificationButton({
    super.key,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
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
                        content: Text(
                          'تم إرسال الإشعار بنجاح',
                          style: TextStyle(),
                        ),
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
    );
  }
}
