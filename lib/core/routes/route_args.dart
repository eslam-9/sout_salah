import '../../features/mosques/domain/entities/mosque.dart';
import '../../features/mosques/domain/entities/ramadan_day.dart';
import '../../features/mosques/domain/entities/recording.dart';
import '../../features/mosques/domain/entities/prayer.dart';

/// Route arguments for upload recording page
class UploadRecordingArgs {
  final String mosqueId;
  final String dayId;
  final Prayer? prayer;
  final String? customPrayerName;
  final String? pendingRecordingId;

  UploadRecordingArgs({
    required this.mosqueId,
    required this.dayId,
    this.prayer,
    this.customPrayerName,
    this.pendingRecordingId,
  });

  /// Validate that the arguments are not empty
  bool validate() {
    return mosqueId.isNotEmpty && dayId.isNotEmpty;
  }
}

/// Route arguments for audio player page
class AudioPlayerArgs {
  final Recording recording;

  AudioPlayerArgs({required this.recording});
}

/// Route arguments for mosque detail page
class MosqueDetailArgs {
  final Mosque mosque;

  MosqueDetailArgs({required this.mosque});
}

/// Route arguments for day detail page
class DayDetailArgs {
  final RamadanDay day;

  DayDetailArgs({required this.day});
}

/// Route arguments for day schedule page
class DayScheduleArgs {
  final String dayId;
  final String mosqueId;
  final int dayNumber;

  DayScheduleArgs({
    required this.dayId,
    required this.mosqueId,
    required this.dayNumber,
  });
}
