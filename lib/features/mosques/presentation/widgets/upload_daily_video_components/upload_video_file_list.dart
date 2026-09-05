import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';

class UploadVideoFileList extends StatelessWidget {
  final List<File> selectedFiles;
  final bool isUploading;
  final int currentUploadIndex;
  final double uploadProgress;
  final VoidCallback onPickVideos;
  final void Function(int) onRemoveFile;

  const UploadVideoFileList({
    super.key,
    required this.selectedFiles,
    required this.isUploading,
    required this.currentUploadIndex,
    required this.uploadProgress,
    required this.onPickVideos,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: selectedFiles.length + (isUploading ? 0 : 1),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          // Add more videos button at the end
          if (index == selectedFiles.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton.icon(
                onPressed: onPickVideos,
                icon: const Icon(
                  LucideIcons.plus,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'إضافة المزيد من الفيديوهات',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            );
          }

          final file = selectedFiles[index];
          final isCurrentUpload = isUploading && index == currentUploadIndex;
          final isFinishedUpload = isUploading && index < currentUploadIndex;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.fileVideo2,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.path.split('/').last.split('\\').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isUploading) ...[
                  if (isCurrentUpload)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: uploadProgress,
                        strokeWidth: 2,
                      ),
                    )
                  else if (isFinishedUpload)
                    const Icon(
                      LucideIcons.checkCircle2,
                      color: Colors.green,
                    )
                  else
                    const Icon(
                      LucideIcons.clock,
                      color: Colors.grey,
                    ),
                ] else
                  IconButton(
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => onRemoveFile(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
