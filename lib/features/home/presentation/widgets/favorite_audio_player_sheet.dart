import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/favorite_recording.dart';
import '../../../shared/widgets/base_audio_sheet.dart';

/// Audio player sheet for favorite recordings
class FavoriteAudioPlayerSheet extends ConsumerWidget {
  final FavoriteRecording favorite;

  const FavoriteAudioPlayerSheet({super.key, required this.favorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseAudioSheet(
      title: favorite.prayerName,
      subtitle: favorite.sheikhName,
      extraInfo: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.download, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(
              'محفوظ للتشغيل بدون إنترنت',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
