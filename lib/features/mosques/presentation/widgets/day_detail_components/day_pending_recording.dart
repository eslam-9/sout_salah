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
import '../../../domain/entities/recording.dart';
import '../../../domain/usecases/delete_recording_usecase.dart';

class DayPendingRecordingContent extends ConsumerWidget {
  final Recording recording;

  const DayPendingRecordingContent({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildUploadButton(ref),
        const SizedBox(width: 12),
        _buildDeleteButton(context, ref),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                recording.prayer == Prayer.other
                    ? (recording.customPrayerName ?? 'أخرى')
                    : recording.prayer.arabicName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'في انتظار الرفع...',
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
      future: permissionChecker.canShowUploadButton(recording.mosqueId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () async {
            final result = await NavigationService.navigateTo(
              AppRoutes.uploadRecording,
              arguments: UploadRecordingArgs(
                mosqueId: recording.mosqueId,
                dayId: recording.dayId,
                prayer: recording.prayer,
                customPrayerName: recording.customPrayerName,
                pendingRecordingId: recording.id,
              ),
            );
            if (result == true) {
              ref.invalidate(dayRecordingsProvider(recording.dayId));
            }
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

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    final permissionChecker = ref.read(permissionCheckerProvider);
    return FutureBuilder<bool>(
      future: permissionChecker.canShowDeleteButton(
        recording.id,
        recording.mosqueId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                  'حذف التلاوة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text('هل أنت متأكد من حذف هذه التلاوة؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'حذف',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final result = await ref
                  .read(deleteRecordingUseCaseProvider)
                  .call(
                    DeleteRecordingParams(
                      recordingId: recording.id,
                      mosqueId: recording.mosqueId,
                    ),
                  );
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('فشل حذف التلاوة'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                (_) {
                  ref.invalidate(dayRecordingsProvider(recording.dayId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف التلاوة بنجاح'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              );
            }
          },
          child: Icon(LucideIcons.trash2, color: Colors.red.shade300, size: 20),
        );
      },
    );
  }
}
