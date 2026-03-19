import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/permission_checker.dart';
import '../../../domain/usecases/delete_recording_usecase.dart';
import '../../../domain/entities/recording.dart';
import '../../providers/mosque_data_providers.dart';

class DayRecordingDeleteButton extends ConsumerWidget {
  final Recording recording;

  const DayRecordingDeleteButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  textAlign: TextAlign.right,
                ),
                content: const Text(
                  'هل أنت متأكد من حذف هذه التلاوة؟',
                  textAlign: TextAlign.right,
                ),
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
