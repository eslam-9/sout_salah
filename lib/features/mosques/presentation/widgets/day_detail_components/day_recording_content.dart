import 'package:flutter/material.dart';
import '../../../domain/entities/recording.dart';
import 'day_recording_download_button.dart';
import 'day_recording_favorite_button.dart';
import 'day_recording_delete_button.dart';
import 'day_recording_play_button.dart';

class DayRecordingContent extends StatelessWidget {
  final Recording recording;

  const DayRecordingContent({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            DayRecordingDownloadButton(recording: recording),
            const SizedBox(height: 12),
            DayRecordingFavoriteButton(recording: recording),
            const SizedBox(height: 12),
            DayRecordingDeleteButton(recording: recording),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                recording.prayer.resolvedArabicName(recording.customPrayerName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recording.sheikhName,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        DayRecordingPlayButton(recording: recording),
      ],
    );
  }
}
