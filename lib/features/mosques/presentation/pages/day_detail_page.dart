import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/ramadan_day.dart';
import '../providers/mosque_data_providers.dart';
import '../widgets/day_detail_components/day_prayer_list.dart';

class DayDetailPage extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailPage({super.key, required this.day});

  String _toArabicNumerals(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabic[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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
            const Text(
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
                  const TextSpan(
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
        data: (recordings) => DayPrayerList(day: day, recordings: recordings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('خطأ: $error')),
      ),
    );

    if (uploaded == true) {
      ref.invalidate(dailyVideoListProvider(day.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الفيديو بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(dayRecordingsProvider(day.id));
    final videoAsync = ref.watch(dailyVideoListProvider(day.id));

    return Column(
      children: [
        // Daily Video Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: videoAsync.when(
            data: (videos) {
              // Render both the card (if videos exist) and the upload button (if admin)
              return Column(
                children: [
                  if (videos.isNotEmpty) ...[
                    DailyVideoCard(dayId: day.id),
                    const SizedBox(height: 16),
                  ],
                  FutureBuilder<bool>(
                    future: ref.read(
                      permissionCheckerProvider.select(
                        (checker) => checker.canShowUploadButton(day.mosqueId),
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showUploadVideoSheet(context, ref),
                            icon: const Icon(LucideIcons.video, color: AppColors.primary),
                            label: const Text(
                              'إضافة فيديوهات اليوم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text('فشل تحميل الفيديو', style: TextStyle(color: Colors.red)),
          ),
        ),
        
        Expanded(
          child: recordingsAsync.when(
            data: (recordings) => _buildPrayersList(recordings),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('خطأ: $error')),
          ),
        ),
      ],
    );
  }
}
