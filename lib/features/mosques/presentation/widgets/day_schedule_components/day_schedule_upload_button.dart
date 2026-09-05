import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/permission_checker.dart';

class DayScheduleUploadButton extends ConsumerWidget {
  final String mosqueId;
  final VoidCallback onUploadPressed;

  const DayScheduleUploadButton({
    super.key,
    required this.mosqueId,
    required this.onUploadPressed,
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
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUploadPressed,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
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
    );
  }
}
