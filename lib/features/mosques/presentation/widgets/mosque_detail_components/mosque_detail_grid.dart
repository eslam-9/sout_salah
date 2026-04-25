import 'package:flutter/material.dart';
import '../../../domain/entities/ramadan_day.dart';
import '../../../../../core/constants/app_constants.dart';
import 'mosque_detail_day_circle.dart';

class MosqueDetailGrid extends StatelessWidget {
  final List<RamadanDay> days;

  const MosqueDetailGrid({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final ramadanStart = AppConstants.ramadanStartDate;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final currentRamadanDay = today.difference(ramadanStart).inDays + 1;
        return MosqueDetailDayCircle(
          day: day,
          isToday: day.dayNumber == currentRamadanDay,
        );
      },
    );
  }
}
