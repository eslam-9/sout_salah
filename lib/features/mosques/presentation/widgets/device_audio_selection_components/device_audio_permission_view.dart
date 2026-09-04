import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';

class DeviceAudioPermissionView extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const DeviceAudioPermissionView({
    super.key,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.lock, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'الرجاء منح صلاحية الوصول للملفات',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRequestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'منح الصلاحية',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
