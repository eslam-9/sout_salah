import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/downloaded_recording.dart';
import '../../../../core/di/providers.dart';

/// Provider for checking if a recording is downloaded
final isDownloadedProvider = FutureProvider.family<bool, String>((
  ref,
  recordingId,
) async {
  final downloadsService = ref.watch(downloadsServiceProvider);
  return await downloadsService.isDownloaded(recordingId);
});

/// Provider for all downloads
final allDownloadsProvider = FutureProvider<List<DownloadedRecording>>((
  ref,
) async {
  final downloadsService = ref.watch(downloadsServiceProvider);
  return await downloadsService.getDownloads();
});

/// Provider for downloads stream
final downloadsStreamProvider = StreamProvider<List<DownloadedRecording>>((
  ref,
) {
  final downloadsService = ref.watch(downloadsServiceProvider);
  return downloadsService.downloadsStream();
});
