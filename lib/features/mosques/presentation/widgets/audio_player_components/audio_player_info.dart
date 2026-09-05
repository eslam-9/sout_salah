import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/recording.dart';

class AudioPlayerInfo extends StatelessWidget {
  final Recording recording;

  const AudioPlayerInfo({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Artwork
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            LucideIcons.bookOpen,
            size: 100,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 48),

        // Title and Sheikh name
        Text(
          recording.prayer.arabicName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          recording.sheikhName,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
