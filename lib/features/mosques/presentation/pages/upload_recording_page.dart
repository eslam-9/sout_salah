import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/upload_state.dart';
import '../providers/upload_recording_notifier.dart';
import '../widgets/upload_recording_components/upload_recording_form.dart';
import '../widgets/upload_recording_components/upload_recording_file_picker.dart';
import '../widgets/upload_recording_components/upload_recording_header.dart';
import '../widgets/upload_recording_components/upload_recording_button.dart';

class UploadRecordingPage extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;
  final int dayNumber;
  final int month;
  final String? pendingRecordingId;
  final Prayer? prayer;
  final String? customPrayerName;

  const UploadRecordingPage({
    super.key,
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
    required this.month,
    this.prayer,
    this.customPrayerName,
    this.pendingRecordingId,
  });

  @override
  ConsumerState<UploadRecordingPage> createState() =>
      _UploadRecordingPageState();
}

class _UploadRecordingPageState extends ConsumerState<UploadRecordingPage> {
  final _formKey = GlobalKey<FormState>();
  final _sheikhNameController = TextEditingController();
  final _customPrayerController = TextEditingController();
  Prayer? _selectedPrayer;
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    if (widget.prayer != null) {
      _selectedPrayer = widget.prayer;
    }
    if (widget.customPrayerName != null) {
      _customPrayerController.text = widget.customPrayerName!;
    }
  }

  @override
  void dispose() {
    _sheikhNameController.dispose();
    _customPrayerController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await NavigationService.navigateTo(
      AppRoutes.deviceAudioSelection,
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedFile = File(result['path']);
      });
    }
  }

  Future<void> _uploadRecording() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار ملف صوتي'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fileSize = await _selectedFile!.length();
    if (fileSize > 100 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حجم الملف يتجاوز 100 ميجابايت'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    ref.read(uploadRecordingNotifierProvider.notifier).startUpload(
          selectedFile: _selectedFile!,
          selectedPrayer: _selectedPrayer!,
          mosqueId: widget.mosqueId,
          dayId: widget.dayId,
          pendingRecordingId: widget.pendingRecordingId,
          customPrayerName: _customPrayerController.text.trim(),
          sheikhName: _sheikhNameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UploadState>(uploadRecordingNotifierProvider, (previous, next) {
      if (next is UploadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع التلاوة: ${next.failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is UploadSuccess) {
        NotificationService.sendNotification(
          type: 'new_recording',
          data: {
            'salah': _selectedPrayer!.resolvedArabicName(_customPrayerController.text.trim()),
            'shikh': _sheikhNameController.text.trim(),
            'dayId': widget.dayId,
            'mosqueId': widget.mosqueId,
            'dayNumber': widget.dayNumber,
            'month': widget.month,
          },
        );

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع التلاوة بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });

    final uploadState = ref.watch(uploadRecordingNotifierProvider);


    double progress = 0.0;
    if (uploadState is UploadProgress) {
      progress = uploadState.progress;
    }

    // A better way to check if uploading is if the state is not Initial, Success or Error.
    final bool uploading = !(uploadState is UploadInitial || uploadState is UploadSuccess || uploadState is UploadError);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const UploadRecordingHeader(),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UploadRecordingForm(
                        sheikhNameController: _sheikhNameController,
                        customPrayerController: _customPrayerController,
                        selectedPrayer: _selectedPrayer,
                        onPrayerSelected: (val) {
                          setState(() {
                            _selectedPrayer = val;
                          });
                        },
                        initialPrayer: widget.prayer,
                        pendingRecordingId: widget.pendingRecordingId,
                      ),
                      const SizedBox(height: 32),
                      UploadRecordingFilePicker(
                        selectedFile: _selectedFile,
                        isUploading: uploading,
                        uploadProgress: progress,
                        onPickFile: _pickFile,
                        onClearFile: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Upload button
            UploadRecordingButton(
              isUploading: uploading,
              onPressed: _uploadRecording,
            ),
          ],
        ),
      ),
    );
  }
}


