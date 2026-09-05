import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/prayer.dart';
import '../widgets/upload_recording_components/upload_recording_form.dart';
import '../widgets/upload_recording_components/upload_recording_file_picker.dart';
import '../widgets/upload_recording_components/upload_recording_header.dart';
import '../widgets/upload_recording_components/upload_recording_button.dart';
import 'upload_recording_controller.dart';

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
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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

  void _uploadRecording() {
    UploadRecordingController.uploadRecording(
      context: context,
      ref: ref,
      formKey: _formKey,
      selectedFile: _selectedFile,
      selectedPrayer: _selectedPrayer,
      mosqueId: widget.mosqueId,
      dayId: widget.dayId,
      dayNumber: widget.dayNumber,
      month: widget.month,
      pendingRecordingId: widget.pendingRecordingId,
      customPrayerName: _customPrayerController.text.trim(),
      sheikhName: _sheikhNameController.text.trim(),
      setUploading: (val) {
        if (mounted) setState(() => _isUploading = val);
      },
      setUploadProgress: (val) {
        if (mounted) setState(() => _uploadProgress = val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        isUploading: _isUploading,
                        uploadProgress: _uploadProgress,
                        onPickFile: _pickFile,
                        onClearFile: () {
                          setState(() {
                            _selectedFile = null;
                            _uploadProgress = 0.0;
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
              isUploading: _isUploading,
              onPressed: _uploadRecording,
            ),
          ],
        ),
      ),
    );
  }
}

