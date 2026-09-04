import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ramadan_day.dart';
import '../../providers/mosque_data_providers.dart';
import 'day_prayer_list.dart';
import 'day_detail_video_section.dart';

class DayDetailBody extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailBody({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(dayRecordingsProvider(day.id));

    return Column(
      children: [
        DayDetailVideoSection(day: day),
        Expanded(
          child: recordingsAsync.when(
            data: (recordings) => DayPrayerList(day: day, recordings: recordings),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('خطأ: $error')),
          ),
        ),
      ],
    );
  }
}
