import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/route_args.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../../../core/utils/permission_checker.dart';
import '../../providers/mosque_data_providers.dart';
import '../../../domain/entities/prayer.dart';

class DayEmptyPrayerContent extends ConsumerWidget {
  final Prayer prayer;
  final String mosqueId;
  final String dayId;
  final int dayNumber;
  final int month;

  const DayEmptyPrayerContent({
    super.key,
    required this.prayer,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildUploadButton(ref),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                prayer.arabicName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'قارئ ضيف',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.volume,
            color: Colors.grey.shade300,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(WidgetRef ref) {
    final permissionChecker = ref.read(permissionCheckerProvider);
    return FutureBuilder<bool>(
      future: permissionChecker.canShowUploadButton(mosqueId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          return Icon(LucideIcons.cloud, color: Colors.grey.shade300, size: 20);
        }
        return InkWell(
          onTap: () async {
            final result = await NavigationService.navigateTo(
              AppRoutes.uploadRecording,
              arguments: UploadRecordingArgs(
                mosqueId: mosqueId,
                dayId: dayId,
                dayNumber: dayNumber,
                month: month,
                prayer: prayer,
              ),
            );
            if (result == true) ref.invalidate(dayRecordingsProvider(dayId));
          },
          child: const Icon(
            LucideIcons.uploadCloud,
            color: AppColors.primary,
            size: 20,
          ),
        );
      },
    );
  }
}
