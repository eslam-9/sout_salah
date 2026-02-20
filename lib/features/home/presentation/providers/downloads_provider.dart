import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/downloaded_recording.dart';
import '../../../../core/di/providers.dart';

/// Provider for checking if a recording is downloaded
final isDownloadedProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  recordingId,
) {
  final downloadsAsync = ref.watch(downloadsStreamProvider);
  return downloadsAsync.whenData(
    (downloads) => downloads.any((d) => d.recordingId == recordingId),
  );
});

/// Provider for all downloads
final allDownloadsProvider = downloadsStreamProvider;

/// Provider for downloads stream
final downloadsStreamProvider = StreamProvider<List<DownloadedRecording>>((
  ref,
) {
  final downloadsService = ref.watch(downloadsServiceProvider);
  return downloadsService.downloadsStream;
});
