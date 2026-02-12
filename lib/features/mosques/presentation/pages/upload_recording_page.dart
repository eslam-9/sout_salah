import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/usecases/upload_recording_params.dart';
import '../providers/mosque_data_providers.dart';

class UploadRecordingPage extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;

  const UploadRecordingPage({
    super.key,
    required this.mosqueId,
    required this.dayId,
  });

  @override
  ConsumerState<UploadRecordingPage> createState() =>
      _UploadRecordingPageState();
}

class _UploadRecordingPageState extends ConsumerState<UploadRecordingPage> {
  final _formKey = GlobalKey<FormState>();
  final _sheikhNameController = TextEditingController();
  Prayer? _selectedPrayer;
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _sheikhNameController.dispose();
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
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final fileSize = await _selectedFile!.length();

      final params = UploadRecordingParams(
        mosqueId: widget.mosqueId,
        dayId: widget.dayId,
        prayer: _selectedPrayer!,
        sheikhName: _sheikhNameController.text.trim(),
        filePath: _selectedFile!.path,
        fileSize: fileSize,
      );

      // Call upload use case
      final result = await ref
          .read(uploadRecordingUseCaseProvider)
          .call(
            params.copyWith(
              onProgress: (progress) {
                if (mounted) {
                  setState(() {
                    _uploadProgress = progress;
                  });
                }
              },
            ),
          );

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'فشل رفع التلاوة: ${failure.toString()}',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          (recording) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم رفع التلاوة بنجاح',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفع التلاوة بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e, stackTrace) {
      GetIt.I<AppLogger>().e('Upload Error: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع التلاوة: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'رفع تلاوة جديدة',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sheikh name input
                      Text(
                        'اسم القارئ',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sheikhNameController,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(),
                        decoration: InputDecoration(
                          hintText: 'أدخل اسم الشيخ',
                          hintStyle: GoogleFonts.cairo(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            LucideIcons.user,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال اسم القارئ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Prayer selection
                      Text(
                        'عنوان التلاوة (اختياري)',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Prayer>(
                        initialValue: _selectedPrayer,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'مثال: سورة الكهف - صلاة العشاء',
                          hintStyle: GoogleFonts.cairo(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            LucideIcons.fileText,
                            color: AppColors.primary,
                          ),
                        ),
                        items: Prayer.allPrayers.map((prayer) {
                          return DropdownMenuItem(
                            value: prayer,
                            alignment: Alignment.centerRight,
                            child: Text(
                              prayer.arabicName,
                              style: GoogleFonts.cairo(),
                              textAlign: TextAlign.right,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPrayer = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'الرجاء اختيار الصلاة';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // File picker buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerButton(
                              icon: LucideIcons.folder,
                              label: 'اختر ملف',
                              onTap: _pickFile,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Selected file display
                      if (_selectedFile != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (_isUploading)
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.x,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                      _uploadProgress = 0.0;
                                    });
                                  },
                                )
                              else
                                const Icon(
                                  LucideIcons.fileAudio,
                                  color: AppColors.primary,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFile!.path.split('/').last,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_isUploading) ...[
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: _uploadProgress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(_uploadProgress * 100).toInt()}%',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Upload button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'مشاركة التلاوة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
