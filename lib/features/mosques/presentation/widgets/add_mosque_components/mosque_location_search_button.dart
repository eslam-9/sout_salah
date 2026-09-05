import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';

class MosqueLocationSearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MosqueLocationSearchButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.navigation),
      label: const Text('استخدام موقعي الحالي'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
    );
  }
}
