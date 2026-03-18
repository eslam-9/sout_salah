import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sout_salah/core/di/providers.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../providers/daily_video_providers.dart';

class UploadDailyVideoSheet extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;
  final int dayNumber;

  const UploadDailyVideoSheet({
    super.key,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
  });

  @override
  ConsumerState<UploadDailyVideoSheet> createState() =>
      _UploadDailyVideoSheetState();
}

class _UploadDailyVideoSheetState extends ConsumerState<UploadDailyVideoSheet> {
  File? _selectedFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  late final AppLogger _logger;

  @override
  void initState() {
    super.initState();
    _logger = ref.read(appLoggerProvider);
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: true,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _logger.e('Error picking video file', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل اختيار الفيديو')));
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final repository = ref.read(videoRepositoryProvider);
      await repository.uploadVideo(
        videoFile: _selectedFile!,
        mosqueId: widget.mosqueId,
        dayId: widget.dayId,
        dayNumber: widget.dayNumber,
        description: _descriptionController.text.trim(),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      _logger.e('Upload failed', e);
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الفيديو. يرجى المحاولة لاحقاً.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إضافة فيديو اليوم',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // File Picker Area
          InkWell(
            onTap: _isUploading ? null : _pickVideo,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile != null
                          ? LucideIcons.fileVideo2
                          : LucideIcons.upload,
                      size: 40,
                      color: _selectedFile != null
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? 'تم اختيار الفيديو'
                          : 'اختر ملف فيديو',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? AppColors.primary
                            : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description Input
          TextField(
            controller: _descriptionController,
            enabled: !_isUploading,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'وصف الفيديو (اختياري)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Upload Button / Progress
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جاري الرفع... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _selectedFile != null ? _uploadVideo : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'رفع الفيديو',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
