import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UploadRecordingHeader extends StatelessWidget {
  const UploadRecordingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'رفع تلاوة جديدة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
