import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/mosque.dart';

class MosqueInfoLocationText extends StatelessWidget {
  final Mosque mosque;

  const MosqueInfoLocationText({super.key, required this.mosque});

  @override
  Widget build(BuildContext context) {
    if (mosque.location == null || mosque.location!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              mosque.location!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 24),
        ],
      ),
    );
  }
}
