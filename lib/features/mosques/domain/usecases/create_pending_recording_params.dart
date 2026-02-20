import 'package:equatable/equatable.dart';

class CreatePendingRecordingParams extends Equatable {
  final String mosqueId;
  final String dayId;
  final String prayerName;

  const CreatePendingRecordingParams({
    required this.mosqueId,
    required this.dayId,
    required this.prayerName,
  });

  @override
  List<Object?> get props => [mosqueId, dayId, prayerName];
}
