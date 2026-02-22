import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/ramadan_day.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/prayer.dart';
import '../providers/mosque_data_providers.dart';
import '../../domain/usecases/delete_recording_usecase.dart';
import '../../domain/usecases/create_pending_recording_params.dart';

import '../../../../core/utils/permission_checker.dart';
import 'package:sout_salah/features/home/presentation/providers/favorites_provider.dart';
import 'package:sout_salah/features/home/presentation/providers/downloads_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/route_args.dart';
import '../../../../core/services/navigation_service.dart';

class DayDetailPage extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailPage({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(dayRecordingsProvider(day.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'رمضان 1447',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'اليوم ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: _toArabicNumerals(day.dayNumber),
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: recordingsAsync.when(
        data: (recordings) => _buildPrayersList(recordings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildPrayersList(List<Recording> recordings) {
    // Group recordings by prayer
    final prayerGroups = <Prayer, List<Recording>>{};
    final customRecordings = <Recording>[];

    for (var recording in recordings) {
      if (recording.prayer == Prayer.other) {
        customRecordings.add(recording);
      } else {
        prayerGroups.putIfAbsent(recording.prayer, () => []).add(recording);
      }
    }

    // Standard prayers (excluding 'other')
    final standardPrayers = Prayer.allPrayers
        .where((p) => p != Prayer.other)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...standardPrayers.map((prayer) {
          final prayerRecordings = prayerGroups[prayer] ?? [];
          return _buildPrayerCard(prayer, prayerRecordings);
        }),

        ...customRecordings.map((recording) {
          return _buildPrayerCard(Prayer.other, [recording]);
        }),

        // Add Prayer Button (for admins)
        Consumer(
          builder: (context, ref, child) {
            final permissionChecker = ref.read(permissionCheckerProvider);
            return FutureBuilder<bool>(
              future: permissionChecker.canShowUploadButton(day.mosqueId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prayerName = await showDialog<String>(
                        context: context,
                        builder: (context) => _AddPrayerDialog(
                          mosqueId: day.mosqueId,
                          dayId: day.id,
                        ),
                      );

                      if (prayerName != null) {
                        ref.invalidate(dayRecordingsProvider(day.id));
                      }
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: Text(
                      'إضافة تلاوة جديدة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrayerCard(Prayer prayer, List<Recording> recordings) {
    final hasRecording = recordings.isNotEmpty;
    final recording = hasRecording ? recordings.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              0,
              0,
              0,
              0.05,
            ), // Fixed deprecated withOpacity
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasRecording
            ? null
            : Border.all(
                color: Colors.grey.shade200,
                width: 2,
                style: BorderStyle.solid,
              ),
      ),
      child: hasRecording
          ? (recording!.audioUrl == 'pending'
                ? _buildPendingRecordingContent(recording)
                : _buildRecordingContent(recording))
          : _buildEmptyPrayerContent(prayer),
    );
  }

  Widget _buildPendingRecordingContent(Recording recording) {
    return Row(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final permissionChecker = ref.read(permissionCheckerProvider);
            return FutureBuilder<bool>(
              future: permissionChecker.canShowUploadButton(recording.mosqueId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  onTap: () async {
                    final result = await NavigationService.navigateTo(
                      AppRoutes.uploadRecording,
                      arguments: UploadRecordingArgs(
                        mosqueId: recording.mosqueId,
                        dayId: recording.dayId,
                        prayer: recording.prayer,
                        customPrayerName: recording.customPrayerName,
                        pendingRecordingId: recording.id,
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(dayRecordingsProvider(recording.dayId));
                    }
                  },
                  child: Icon(
                    LucideIcons.uploadCloud,
                    color: AppColors.primary,
                    size: 20,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 12),
        // Delete button for pending recording
        Consumer(
          builder: (context, ref, child) {
            final permissionChecker = ref.read(permissionCheckerProvider);
            return FutureBuilder<bool>(
              future: permissionChecker.canShowDeleteButton(
                recording.id,
                recording.mosqueId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'حذف التلاوة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        content: Text(
                          'هل أنت متأكد من حذف هذه التلاوة؟',
                          style: TextStyle(),
                          textAlign: TextAlign.right,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'حذف',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final params = DeleteRecordingParams(
                        recordingId: recording.id,
                        mosqueId: recording.mosqueId,
                      );
                      final result = await ref
                          .read(deleteRecordingUseCaseProvider)
                          .call(params);
                      result.fold(
                        (failure) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'فشل حذف التلاوة',
                                  style: TextStyle(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        (_) {
                          ref.invalidate(
                            dayRecordingsProvider(recording.dayId),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم حذف التلاوة بنجاح',
                                  style: TextStyle(),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                  child: Icon(
                    LucideIcons.trash2,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                recording.prayer == Prayer.other
                    ? (recording.customPrayerName ?? 'أخرى')
                    : recording.prayer.arabicName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'في انتظار الرفع...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.volume,
            color: Colors.grey.shade300,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingContent(Recording recording) {
    return Consumer(
      builder: (context, ref, child) {
        final audioService = ref.watch(audioPlayerServiceProvider);
        final currentPlayingId = ref.watch(currentPlayingRecordingProvider);
        final isCurrentlyPlaying = currentPlayingId == recording.id;
        final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

        return Row(
          children: [
            Column(
              children: [
                // Download button
                Consumer(
                  builder: (context, ref, child) {
                    final downloadsService = ref.watch(
                      downloadsServiceProvider,
                    );
                    final isDownloadedAsync = ref.watch(
                      isDownloadedProvider(recording.id),
                    );
                    return isDownloadedAsync.when(
                      data: (isDownloaded) {
                        if (isDownloaded) {
                          return Icon(
                            LucideIcons.cloud,
                            color: AppColors.primary,
                            size: 20,
                          );
                        }
                        return StreamBuilder<double>(
                          stream: downloadsService.progressStream(recording.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return SizedBox(
                                width: 32,
                                height: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: snapshot.data,
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                    Text(
                                      '${(snapshot.data! * 100).toInt()}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return InkWell(
                              onTap: () async {
                                try {
                                  await downloadsService.downloadRecording(
                                    recording,
                                  );
                                  ref.invalidate(
                                    isDownloadedProvider(recording.id),
                                  );
                                  ref.invalidate(allDownloadsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل التنزيل: $e',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Icon(
                                LucideIcons.download,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            );
                          },
                        );
                      },
                      loading: () => SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, s) => Icon(
                        LucideIcons.alertCircle,
                        color: Colors.red,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Favorite button
                isFavoriteAsync.when(
                  data: (isFavorite) => InkWell(
                    onTap: () async {
                      final favoritesService = ref.read(
                        favoritesServiceProvider,
                      );
                      if (isFavorite) {
                        await favoritesService.removeFavorite(recording.id);
                        ref.invalidate(isFavoriteProvider(recording.id));
                        ref.invalidate(allFavoritesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم إزالة التلاوة من المحفوظات',
                                style: TextStyle(),
                              ),
                              backgroundColor: Colors.grey.shade700,
                            ),
                          );
                        }
                      } else {
                        try {
                          if (context.mounted) {
                            // Fixed braces
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'جاري تحميل التلاوة...',
                                      style: TextStyle(),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 30),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                          await favoritesService.addFavorite(recording);
                          ref.invalidate(isFavoriteProvider(recording.id));
                          ref.invalidate(allFavoritesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❤️ تم حفظ التلاوة',
                                  style: TextStyle(),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'فشل حفظ التلاوة',
                                  style: TextStyle(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Icon(
                      LucideIcons.heart,
                      color: isFavorite
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  loading: () => SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  error: (_, s) => Icon(
                    LucideIcons.heart,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Delete button
                Consumer(
                  builder: (context, ref, child) {
                    final permissionChecker = ref.read(
                      permissionCheckerProvider,
                    );
                    return FutureBuilder<bool>(
                      future: permissionChecker.canShowDeleteButton(
                        recording.id,
                        recording.mosqueId,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == false) {
                          return const SizedBox.shrink();
                        }
                        return InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'حذف التلاوة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                content: Text(
                                  'هل أنت متأكد من حذف هذه التلاوة؟',
                                  style: TextStyle(),
                                  textAlign: TextAlign.right,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'حذف',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final params = DeleteRecordingParams(
                                recordingId: recording.id,
                                mosqueId: recording.mosqueId,
                              );
                              final result = await ref
                                  .read(deleteRecordingUseCaseProvider)
                                  .call(params);
                              result.fold(
                                (failure) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل حذف التلاوة',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                (_) {
                                  ref.invalidate(dayRecordingsProvider(day.id));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم حذف التلاوة بنجاح',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                },
                              );
                            }
                          },
                          child: Icon(
                            LucideIcons.trash2,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recording.prayer == Prayer.other
                        ? (recording.customPrayerName ?? 'أخرى')
                        : recording.prayer.arabicName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recording.sheikhName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            StreamBuilder<bool>(
              stream: audioService.player.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                final showPlayButton = !isCurrentlyPlaying || !isPlaying;
                return GestureDetector(
                  onTap: () async {
                    if (isCurrentlyPlaying) {
                      NavigationService.navigateTo(
                        AppRoutes.audioPlayer,
                        arguments: AudioPlayerArgs(recording: recording),
                      );
                    } else {
                      ref.read(currentPlayingRecordingProvider.notifier).state =
                          recording.id;
                      audioService.play(
                        recording.audioUrl,
                        title: recording.prayer == Prayer.other
                            ? (recording.customPrayerName ?? 'أخرى')
                            : recording.prayer.arabicName,
                        artist: recording.sheikhName,
                      );
                      if (context.mounted) {
                        NavigationService.navigateTo(
                          AppRoutes.audioPlayer,
                          arguments: AudioPlayerArgs(recording: recording),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      showPlayButton ? LucideIcons.play : LucideIcons.barChart2,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyPrayerContent(Prayer prayer) {
    return Row(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final permissionChecker = ref.read(permissionCheckerProvider);
            return FutureBuilder<bool>(
              future: permissionChecker.canShowUploadButton(day.mosqueId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false) {
                  return Icon(
                    LucideIcons.cloud,
                    color: Colors.grey.shade300,
                    size: 20,
                  );
                }
                return InkWell(
                  onTap: () async {
                    final result = await NavigationService.navigateTo(
                      AppRoutes.uploadRecording,
                      arguments: UploadRecordingArgs(
                        mosqueId: day.mosqueId,
                        dayId: day.id,
                        prayer: prayer, // Pass the prayer
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(dayRecordingsProvider(day.id));
                    }
                  },
                  child: Icon(
                    LucideIcons.uploadCloud,
                    color: AppColors.primary,
                    size: 20,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                prayer.arabicName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'قارئ ضيف',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.volume,
            color: Colors.grey.shade300,
            size: 24,
          ),
        ),
      ],
    );
  }

  String _toArabicNumerals(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabic[i]);
    }
    return result;
  }
}

class _AddPrayerDialog extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;

  const _AddPrayerDialog({required this.mosqueId, required this.dayId});

  @override
  ConsumerState<_AddPrayerDialog> createState() => _AddPrayerDialogState();
}

class _AddPrayerDialogState extends ConsumerState<_AddPrayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _prayerNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _prayerNameController.dispose();
    super.dispose();
  }

  Future<void> _addPrayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final params = CreatePendingRecordingParams(
        mosqueId: widget.mosqueId,
        dayId: widget.dayId,
        prayerName: _prayerNameController.text.trim(),
      );

      final result = await ref
          .read(createPendingRecordingUseCaseProvider)
          .call(params);

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'فشل إضافة التلاوة: ${failure.toString()}',
                  style: TextStyle(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          (_) {
            Navigator.pop(context, _prayerNameController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إضافة التلاوة بنجاح',
                  style: TextStyle(),
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع', style: TextStyle()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'إضافة تلاوة جديدة',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _prayerNameController,
              textAlign: TextAlign.right,
              style: TextStyle(),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم التلاوة (مثل: تهجد)',
                labelStyle: TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم التلاوة';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPrayer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
