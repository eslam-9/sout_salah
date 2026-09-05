import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/usecases/upload_recording_params.dart';
import '../providers/mosque_data_providers.dart';
import '../../../../core/services/notification_service.dart';

class UploadRecordingController {
  static Future<void> uploadRecording({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey<FormState> formKey,
    required File? selectedFile,
    required Prayer? selectedPrayer,
    required String mosqueId,
    required String dayId,
    required int dayNumber,
    required int month,
    required String? pendingRecordingId,
    required String customPrayerName,
    required String sheikhName,
    required Function(bool) setUploading,
    required Function(double) setUploadProgress,
  }) async {
    if (!formKey.currentState!.validate() || selectedFile == null) {
      if (selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار ملف صوتي'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fileSize = await selectedFile.length();
    if (fileSize > 100 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حجم الملف يتجاوز 100 ميجابايت'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setUploading(true);
    setUploadProgress(0.0);

    try {
      final params = UploadRecordingParams(
        mosqueId: mosqueId,
        dayId: dayId,
        prayer: selectedPrayer!,
        customPrayerName:
            selectedPrayer == Prayer.other ? customPrayerName : null,
        sheikhName: sheikhName,
        filePath: selectedFile.path,
        fileSize: fileSize,
        pendingRecordingId: pendingRecordingId,
      );

      final result = await ref.read(uploadRecordingUseCaseProvider).call(
            params.copyWith(
              onProgress: (progress) {
                setUploadProgress(progress);
              },
            ),
          );

      if (context.mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'فشل رفع التلاوة: ${failure.toString()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          (recording) {
            NotificationService.sendNotification(
              type: 'new_recording',
              data: {
                'salah': selectedPrayer == Prayer.other
                    ? customPrayerName
                    : selectedPrayer.arabicName,
                'shikh': sheikhName,
                'dayId': dayId,
                'mosqueId': mosqueId,
                'dayNumber': dayNumber,
                'month': month,
              },
            );

            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفع التلاوة بنجاح'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );
      }
    } catch (e, stackTrace) {
      GetIt.I<AppLogger>().e('Upload Error: $e', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع التلاوة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setUploading(false);
    }
  }
}
