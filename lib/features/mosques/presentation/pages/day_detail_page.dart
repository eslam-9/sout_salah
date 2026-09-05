import 'package:flutter/material.dart';
import '../../domain/entities/ramadan_day.dart';
import '../widgets/day_detail_components/day_detail_app_bar.dart';
import '../widgets/day_detail_components/day_detail_body.dart';

class DayDetailPage extends StatelessWidget {
  final RamadanDay day;

  const DayDetailPage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: DayDetailAppBar(day: day),
      body: DayDetailBody(day: day),
    );
  }
}
