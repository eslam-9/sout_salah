import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../../core/theme/app_theme.dart';

class DeviceAudioList extends StatelessWidget {
  final OnAudioQuery audioQuery;
  final String searchQuery;

  const DeviceAudioList({
    super.key,
    required this.audioQuery,
    required this.searchQuery,
  });

  String _formatDuration(int? duration) {
    if (duration == null) return '--:--';
    final d = Duration(milliseconds: duration);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongModel>>(
      future: audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, item) {
        if (item.hasError) {
          return const Center(
            child: Text('حدث خطأ في تحميل الملفات'),
          );
        }

        if (item.data == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (item.data!.isEmpty) {
          return const Center(
            child: Text('لا توجد ملفات صوتية'),
          );
        }

        // Filter out very short audios (e.g. < 5 seconds)
        // And filter by search query
        final songs = item.data!.where((song) {
          final isLongEnough = (song.duration ?? 0) > 5000;
          if (!isLongEnough) return false;

          if (searchQuery.isEmpty) return true;
          return song.displayNameWOExt.toLowerCase().contains(
            searchQuery,
          );
        }).toList();

        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد تلاوات تطابق بحثك',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context, {
                    'path': song.data,
                    'name': song.displayNameWOExt,
                    'size': song.size,
                    'duration': song.duration,
                  });
                },
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.music,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  song.displayNameWOExt,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Text(
                      _formatDuration(song.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${(song.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
