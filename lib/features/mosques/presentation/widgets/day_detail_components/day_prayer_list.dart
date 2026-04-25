import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/permission_checker.dart';
import '../../providers/mosque_data_providers.dart';
import '../../../domain/entities/prayer.dart';
import '../../../domain/entities/recording.dart';
import '../../../domain/entities/ramadan_day.dart';
import 'day_prayer_card.dart';
import 'add_prayer_dialog.dart';

class DayPrayerList extends StatelessWidget {
  final RamadanDay day;
  final List<Recording> recordings;

  const DayPrayerList({super.key, required this.day, required this.recordings});

  @override
  Widget build(BuildContext context) {
    final prayerGroups = <Prayer, List<Recording>>{};
    final customRecordings = <Recording>[];

    for (var recording in recordings) {
      if (recording.prayer == Prayer.other) {
        customRecordings.add(recording);
      } else {
        prayerGroups.putIfAbsent(recording.prayer, () => []).add(recording);
      }
    }

    final defaultPrayers = [
      Prayer.fajr,
      Prayer.isha,
      Prayer.taraweeh1,
      Prayer.taraweeh2,
      Prayer.taraweeh3,
      Prayer.taraweeh4,
    ];
    final standardPrayers = Prayer.allPrayers
        .where(
          (p) =>
              p != Prayer.other &&
              (defaultPrayers.contains(p) || prayerGroups.containsKey(p)),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...standardPrayers.map(
          (prayer) => DayPrayerCard(
            prayer: prayer,
            recordings: prayerGroups[prayer] ?? [],
            mosqueId: day.mosqueId,
            dayId: day.id,
            dayNumber: day.dayNumber,
            month: day.month,
          ),
        ),
        ...customRecordings.map(
          (recording) => DayPrayerCard(
            prayer: Prayer.other,
            recordings: [recording],
            mosqueId: day.mosqueId,
            dayId: day.id,
            dayNumber: day.dayNumber,
            month: day.month,
          ),
        ),
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
                        builder: (context) => AddPrayerDialog(
                          mosqueId: day.mosqueId,
                          dayId: day.id,
                        ),
                      );
                      if (prayerName != null) {
                        ref.invalidate(dayRecordingsProvider(day.id));
                      }
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text(
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
}
