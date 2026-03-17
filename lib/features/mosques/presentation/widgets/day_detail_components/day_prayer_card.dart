import 'package:flutter/material.dart';
import '../../../domain/entities/prayer.dart';
import '../../../domain/entities/recording.dart';
import 'day_recording_content.dart';
import 'day_pending_recording.dart';
import 'day_empty_prayer.dart';

class DayPrayerCard extends StatelessWidget {
  final Prayer prayer;
  final List<Recording> recordings;
  final String mosqueId;
  final String dayId;

  const DayPrayerCard({
    super.key,
    required this.prayer,
    required this.recordings,
    required this.mosqueId,
    required this.dayId,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecording = recordings.isNotEmpty;
    final recording = hasRecording ? recordings.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: hasRecording
            ? null
            : Border.all(
                color: Colors.grey.shade200,
                width: 2,
                style: BorderStyle.solid,
              ),
      ),
      child: hasRecording
          ? (recording!.audioUrl == 'pending'
                ? DayPendingRecordingContent(recording: recording)
                : DayRecordingContent(recording: recording))
          : DayEmptyPrayerContent(
              prayer: prayer,
              mosqueId: mosqueId,
              dayId: dayId,
            ),
    );
  }
}
