import 'package:equatable/equatable.dart';
import 'recording.dart';

/// The 9 specific prayers for each Ramadan day
enum Prayer {
  fajr('Fajr', 'الفجر'),
  maghrib('Maghrib', 'المغرب'),
  isha('Isha', 'العشاء'),
  taraweeh1('Taraweeh 1', 'التراويح 1'),
  taraweeh2('Taraweeh 2', 'التراويح 2'),
  taraweeh3('Taraweeh 3', 'التراويح 3'),
  taraweeh4('Taraweeh 4', 'التراويح 4'),
  shaf('Shaf', 'الشفع'),
  witr('Witr', 'الوتر'),
  other('Other', 'أخرى');

  const Prayer(this.englishName, this.arabicName);
  final String englishName;
  final String arabicName;

  /// Returns the custom name if the prayer is 'other', otherwise returns the english name
  String resolvedName(String? customName) {
    return (this == Prayer.other && customName != null && customName.isNotEmpty)
        ? customName
        : englishName;
  }

  /// Returns the custom name if the prayer is 'other', otherwise returns the arabic name
  String resolvedArabicName(String? customName) {
    return (this == Prayer.other && customName != null && customName.isNotEmpty)
        ? customName
        : arabicName;
  }

  /// Get Prayer from database value
  static Prayer fromString(String value) {
    return Prayer.values.firstWhere(
      (p) => p.englishName == value,
      orElse: () => Prayer.other,
    );
  }

  /// Get all prayers in order
  static List<Prayer> get allPrayers => Prayer.values;
}

/// Represents a prayer with its recordings
class PrayerWithRecordings extends Equatable {

  const PrayerWithRecordings({required this.prayer, required this.recordings});
  final Prayer prayer;
  final List<Recording> recordings;

  bool get hasRecordings => recordings.isNotEmpty;
  int get recordingCount => recordings.length;

  @override
  List<Object> get props => [prayer, recordings];
}
