import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';

class DeviceAudioSelectionPage extends ConsumerStatefulWidget {
  const DeviceAudioSelectionPage({super.key});

  @override
  ConsumerState<DeviceAudioSelectionPage> createState() =>
      _DeviceAudioSelectionPageState();
}

class _DeviceAudioSelectionPageState
    extends ConsumerState<DeviceAudioSelectionPage> {
  final _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // For Android 13+ (SDK 33+), we need READ_MEDIA_AUDIO
    // For older versions, we need READ_EXTERNAL_STORAGE

    // We can't easily check SDK version in pure Dart without a plugin,
    // but permission_handler handles this logic internally if we use the right permissions.
    // Ideally, we check the platform version or try both relevant permissions.

    // Attempt to request audio permission first (Android 13+)
    var audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) {
      setState(() => _hasPermission = true);
      return;
    }

    // Attempt to request storage permission (Android < 13)
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      setState(() => _hasPermission = true);
      return;
    }

    // If neither is granted, we need to request them.
    // Note: On Android 13+, requesting storage will be denied automatically/silently.
    // So we should try to determine which one to request or request both/smartly.

    // Strategy: Request audio first. If it's valid for this OS, system shows dialog.
    // If invalid (OS < 13), it might be denied or unrestricted.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    if (statuses[Permission.audio]!.isGranted ||
        statuses[Permission.storage]!.isGranted) {
      setState(() => _hasPermission = true);
    } else {
      // If execution reaches here, permissions are denied.
      // Check if permanently denied to show open settings option
      if (statuses[Permission.audio]!.isPermanentlyDenied ||
          statuses[Permission.storage]!.isPermanentlyDenied) {
        // Show dialog or snackbar to open settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يجب تفعيل الصلاحيات من الإعدادات',
                style: GoogleFonts.cairo(),
              ),
              action: SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
      setState(() => _hasPermission = false);
    }
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'اختر التلاوة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_hasPermission
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.lock, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'الرجاء منح صلاحية الوصول للملفات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'منح الصلاحية',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(
                sortType: null,
                orderType: OrderType.ASC_OR_SMALLER,
                uriType: UriType.EXTERNAL,
                ignoreCase: true,
              ),
              builder: (context, item) {
                if (item.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل الملفات',
                      style: GoogleFonts.cairo(),
                    ),
                  );
                }

                if (item.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (item.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد ملفات صوتية',
                      style: GoogleFonts.cairo(),
                    ),
                  );
                }

                // Filter out very short audios (e.g. < 5 seconds) to avoid system sounds
                final songs = item.data!
                    .where((song) => (song.duration ?? 0) > 5000)
                    .toList();

                if (songs.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد تلاوات مناسبة',
                      style: GoogleFonts.cairo(),
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
                          // Return the selected file path (and size/duration if needed)
                          // We return a map or a custom object, but for now just the path + metadata map
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
                            color: AppColors.primaryLight, // Light green
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
                          style: GoogleFonts.cairo(
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
                              style: GoogleFonts.cairo(
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
                                style: GoogleFonts.cairo(
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
            ),
    );
  }
}
