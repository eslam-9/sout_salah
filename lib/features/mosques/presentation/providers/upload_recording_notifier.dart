import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/upload_state.dart';
import '../../domain/usecases/upload_recording_params.dart';
import 'mosque_data_providers.dart';

class UploadRecordingNotifier extends Notifier<UploadState> {
  @override
  UploadState build() {
    return const UploadInitial();
  }

  void startUpload({
    required File selectedFile,
    required Prayer selectedPrayer,
    required String mosqueId,
    required String dayId,
    required String? pendingRecordingId,
    required String customPrayerName,
    required String sheikhName,
  }) async {
    final fileSize = await selectedFile.length();
    
    final params = UploadRecordingParams(
      mosqueId: mosqueId,
      dayId: dayId,
      prayer: selectedPrayer,
      customPrayerName: selectedPrayer.resolvedName(customPrayerName) == selectedPrayer.englishName ? null : customPrayerName,
      sheikhName: sheikhName,
      filePath: selectedFile.path,
      fileSize: fileSize,
      pendingRecordingId: pendingRecordingId,
    );

    final stream = ref.read(uploadRecordingUseCaseProvider).call(params);
    
    await for (final streamState in stream) {
      state = streamState;
    }
  }
}

final uploadRecordingNotifierProvider = NotifierProvider<UploadRecordingNotifier, UploadState>(() {
  return UploadRecordingNotifier();
});
