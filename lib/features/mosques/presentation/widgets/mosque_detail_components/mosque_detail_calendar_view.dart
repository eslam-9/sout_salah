import 'package:flutter/material.dart';
import '../../../domain/entities/ramadan_day.dart';
import 'mosque_detail_progress.dart';
import 'mosque_detail_grid.dart';
import 'mosque_detail_legend.dart';

class MosqueDetailCalendarView extends StatelessWidget {
  final List<RamadanDay> days;

  const MosqueDetailCalendarView({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final completedDays = days.where((d) => d.status == 'green').length;
    final partialDays = days.where((d) => d.status == 'yellow').length;
    final totalDays = days.length;
    final progress = (completedDays + (partialDays * 0.5)) / totalDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosqueDetailProgress(
            completedDays: completedDays,
            totalDays: totalDays,
            progress: progress,
          ),
          const SizedBox(height: 32),
          MosqueDetailGrid(days: days),
          const SizedBox(height: 32),
          const MosqueDetailLegend(),
        ],
      ),
    );
  }
}
