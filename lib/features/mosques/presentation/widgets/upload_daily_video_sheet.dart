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
  List<File> _selectedFiles = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _currentUploadIndex = 0;
  late final AppLogger _logger;

  @override
  void initState() {
    super.initState();
    _logger = ref.read(appLoggerProvider);
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: true,
        allowMultiple: true, // Allow multiple uploads
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.paths.where((p) => p != null).map((p) => File(p!)).toList();
        });
      }
    } catch (e) {
      _logger.e('Error picking video file(s)', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل اختيار الفيديو')));
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadVideos() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _currentUploadIndex = 0;
      _uploadProgress = 0.0;
    });

    try {
      final repository = ref.read(videoRepositoryProvider);
      final totalFiles = _selectedFiles.length;

      for (int i = 0; i < totalFiles; i++) {
        setState(() {
          _currentUploadIndex = i;
          _uploadProgress = 0.0; // Reset progress for the new file
        });

        // Use the title field directly. If uploading multiple videos at once, 
        // they will share the same title, which is acceptable or can be left blank.
        await repository.uploadVideo(
          videoFile: _selectedFiles[i],
          mosqueId: widget.mosqueId,
          dayId: widget.dayId,
          dayNumber: widget.dayNumber,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
        );
      }

      // Invalidate the list provider so it re-fetches
      ref.invalidate(dailyVideoListProvider(widget.dayId));

      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      _logger.e('Upload failed', e);
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الفيديو/الفيديوهات. يرجى المحاولة لاحقاً.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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
                'إضافة فيديوهات اليوم',
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
          if (_selectedFiles.isEmpty)
            InkWell(
              onTap: _isUploading ? null : _pickVideos,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.upload, size: 40, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'اختر ملف فيديو (أو أكثر)',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Selected Files List
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _selectedFiles.length + (_isUploading ? 0 : 1),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  // Add more videos button at the end
                  if (index == _selectedFiles.length) {
                    return TextButton.icon(
                      onPressed: _pickVideos,
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('إضافة المزيد'),
                    );
                  }

                  final file = _selectedFiles[index];
                  final isCurrentUpload = _isUploading && index == _currentUploadIndex;
                  final isFinishedUpload = _isUploading && index < _currentUploadIndex;
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileVideo2, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            file.path.split('/').last.split('\\').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_isUploading) ...[
                          if (isCurrentUpload)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                strokeWidth: 2,
                              ),
                            )
                          else if (isFinishedUpload)
                            const Icon(LucideIcons.checkCircle2, color: Colors.green)
                          else
                            const Icon(LucideIcons.clock, color: Colors.grey)
                        ] else
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                            onPressed: () => _removeFile(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
            
          const SizedBox(height: 24),

          // Title Input
          TextField(
            controller: _titleController,
            enabled: !_isUploading,
            decoration: InputDecoration(
              hintText: 'عنوان الفيديو (اختياري)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // Description Input
          TextField(
            controller: _descriptionController,
            enabled: !_isUploading,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'وصف إضافي (اختياري)',
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
              'جاري رفع الملف ${_currentUploadIndex + 1} من ${_selectedFiles.length}... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _selectedFiles.isNotEmpty ? _uploadVideos : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'رفع الفيديوهات',
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
