import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sout_salah/core/di/riverpod_providers.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../providers/daily_video_providers.dart';
import '../widgets/upload_daily_video_components/upload_video_empty_state.dart';
import '../widgets/upload_daily_video_components/upload_video_file_list.dart';
import '../widgets/upload_daily_video_components/upload_video_details_form.dart';

class UploadDailyVideoPage extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;
  final int dayNumber;

  const UploadDailyVideoPage({
    super.key,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
  });

  @override
  ConsumerState<UploadDailyVideoPage> createState() =>
      _UploadDailyVideoPageState();
}

class _UploadDailyVideoPageState extends ConsumerState<UploadDailyVideoPage> {
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
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.paths
              .where((p) => p != null)
              .map((p) => File(p!))
              .toList();
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
          _uploadProgress = 0.0;
        });

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إضافة فيديوهات اليوم',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Picker Area
              if (_selectedFiles.isEmpty)
                UploadVideoEmptyState(
                  isUploading: _isUploading,
                  onPickVideos: _pickVideos,
                )
              else
                UploadVideoFileList(
                  selectedFiles: _selectedFiles,
                  isUploading: _isUploading,
                  currentUploadIndex: _currentUploadIndex,
                  uploadProgress: _uploadProgress,
                  onPickVideos: _pickVideos,
                  onRemoveFile: _removeFile,
                ),

              const SizedBox(height: 32),
              UploadVideoDetailsForm(
                titleController: _titleController,
                descriptionController: _descriptionController,
                isUploading: _isUploading,
              ),
              const SizedBox(height: 32),

              // Upload Button / Progress
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                Text(
                  'جاري رفع الملف ${_currentUploadIndex + 1} من ${_selectedFiles.length}... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _selectedFiles.isNotEmpty ? _uploadVideos : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'رفع الفيديوهات الآن',
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
        ),
      ),
    );
  }
}
