import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ramadan_day.dart';
import '../../providers/mosque_data_providers.dart';
import 'day_prayer_list.dart';
import 'day_detail_video_section.dart';
import 'package:sout_salah/core/presentation/widgets/app_error_view.dart';
import 'package:sout_salah/core/presentation/widgets/app_loading_indicator.dart';
import '../../providers/daily_video_providers.dart';

class DayDetailBody extends ConsumerWidget {
  final RamadanDay day;

  const DayDetailBody({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(dayRecordingsProvider(day.id));
    final videoAsync = ref.watch(dailyVideoListProvider(day.id));

    if (recordingsAsync.hasError || videoAsync.hasError) {
      return AppErrorView(
        title: 'فشل تحميل الصفحة',
        message: 'حدث خطأ أثناء تحميل البيانات. تأكد من اتصالك بالإنترنت.',
        onRetry: () {
          ref.invalidate(dayRecordingsProvider(day.id));
          ref.invalidate(dailyVideoListProvider(day.id));
        },
      );
    }

    if (recordingsAsync.isLoading || videoAsync.isLoading) {
      return const AppLoadingIndicator();
    }

    return Column(
      children: [
        DayDetailVideoSection(day: day),
        Expanded(
          child: recordingsAsync.maybeWhen(
            data: (recordings) => DayPrayerList(day: day, recordings: recordings),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
