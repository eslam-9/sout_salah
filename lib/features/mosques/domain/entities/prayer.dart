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
  witr('Witr', 'الوتر');

  final String englishName;
  final String arabicName;

  const Prayer(this.englishName, this.arabicName);

  /// Get Prayer from database value
  static Prayer fromString(String value) {
    switch (value) {
      case 'Fajr':
        return Prayer.fajr;
      case 'Maghrib':
        return Prayer.maghrib;
      case 'Isha':
        return Prayer.isha;
      case 'Taraweeh 1':
        return Prayer.taraweeh1;
      case 'Taraweeh 2':
        return Prayer.taraweeh2;
      case 'Taraweeh 3':
        return Prayer.taraweeh3;
      case 'Taraweeh 4':
        return Prayer.taraweeh4;
      case 'Shaf':
        return Prayer.shaf;
      case 'Witr':
        return Prayer.witr;
      default:
        throw ArgumentError('Unknown prayer: $value');
    }
  }

  /// Get all prayers in order
  static List<Prayer> get allPrayers => Prayer.values;
}

/// Represents a prayer with its recordings
class PrayerWithRecordings extends Equatable {
  final Prayer prayer;
  final List<Recording> recordings;

  const PrayerWithRecordings({required this.prayer, required this.recordings});

  bool get hasRecordings => recordings.isNotEmpty;
  int get recordingCount => recordings.length;

  @override
  List<Object> get props => [prayer, recordings];
}
