import 'package:equatable/equatable.dart';

class CreatePendingRecordingParams extends Equatable {

  const CreatePendingRecordingParams({
    required this.mosqueId,
    required this.dayId,
    required this.prayerName,
  });
  final String mosqueId;
  final String dayId;
  final String prayerName;

  @override
  List<Object?> get props => [mosqueId, dayId, prayerName];
}
