import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/day_schedule_table_widget.dart';

class DaySchedulePage extends ConsumerWidget {
  final String dayId;
  final String mosqueId;
  final int dayNumber;

  const DaySchedulePage({
    super.key,
    required this.dayId,
    required this.mosqueId,
    required this.dayNumber,
  });

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
        title: Text(
          'جدول شيوخ اليوم ${_toArabicNumerals(dayNumber)}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: DayScheduleTableWidget(
            dayId: dayId,
            mosqueId: mosqueId,
          ),
        ),
      ),
    );
  }
}
