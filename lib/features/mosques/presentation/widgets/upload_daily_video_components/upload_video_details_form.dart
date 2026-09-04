import 'package:flutter/material.dart';

class UploadVideoDetailsForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isUploading;

  const UploadVideoDetailsForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'معلومات إضافية (اختياري)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Title Input
        TextField(
          controller: titleController,
          enabled: !isUploading,
          decoration: InputDecoration(
            hintText: 'عنوان الفيديو',
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
          controller: descriptionController,
          enabled: !isUploading,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'وصف إضافي للفيديو',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
