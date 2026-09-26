import '../../features/mosques/domain/entities/mosque.dart';
import '../../features/mosques/domain/entities/ramadan_day.dart';
import '../../features/mosques/domain/entities/recording.dart';
import '../../features/mosques/domain/entities/prayer.dart';
import '../../features/mosques/data/models/daily_video_model.dart';

/// Route arguments for upload recording page
class UploadRecordingArgs {

  UploadRecordingArgs({
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
    required this.month,
    this.prayer,
    this.customPrayerName,
    this.pendingRecordingId,
  });
  final String mosqueId;
  final String dayId;
  final int dayNumber;
  final int month;
  final Prayer? prayer;
  final String? customPrayerName;
  final String? pendingRecordingId;

  /// Validate that the arguments are not empty
  bool validate() {
    return mosqueId.isNotEmpty && dayId.isNotEmpty;
  }
}

/// Route arguments for audio player page
class AudioPlayerArgs {

  AudioPlayerArgs({required this.recording});
  final Recording recording;
}

/// Route arguments for daily video page
class DailyVideoArgs {

  DailyVideoArgs({required this.dayId});
  final String dayId;
}

/// Route arguments for video player page
class VideoPlayerArgs {

  VideoPlayerArgs({required this.video});
  final DailyVideoModel video;
}

/// Route arguments for upload daily video page
class UploadDailyVideoArgs {

  UploadDailyVideoArgs({
    required this.mosqueId,
    required this.dayId,
    required this.dayNumber,
  });
  final String mosqueId;
  final String dayId;
  final int dayNumber;
}

/// Route arguments for mosque detail page
class MosqueDetailArgs {

  MosqueDetailArgs({required this.mosque});
  final Mosque mosque;
}

/// Route arguments for day detail page
class DayDetailArgs {

  DayDetailArgs({required this.day});
  final RamadanDay day;
}

/// Route arguments for day schedule page
class DayScheduleArgs {

  DayScheduleArgs({
    required this.dayId,
    required this.mosqueId,
    required this.dayNumber,
    required this.month,
  });
  final String dayId;
  final String mosqueId;
  final int dayNumber;
  final int month;
}
