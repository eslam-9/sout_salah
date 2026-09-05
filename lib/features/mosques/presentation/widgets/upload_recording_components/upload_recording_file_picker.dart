import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';

class UploadRecordingFilePicker extends StatelessWidget {
  final File? selectedFile;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const UploadRecordingFilePicker({
    super.key,
    required this.selectedFile,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPickFile,
    required this.onClearFile,
  });

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
              style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPickerButton(
                icon: LucideIcons.folder,
                label: 'اختر ملف',
                onTap: onPickFile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (selectedFile != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (isUploading)
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.red,
                    ),
                    onPressed: onClearFile,
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
                        selectedFile!.path.split('/').last,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isUploading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(uploadProgress * 100).toInt()}%',
                          style: TextStyle(
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
    );
  }
}
