import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ramadan_day.dart';
import '../widgets/day_detail_components/day_detail_app_bar.dart';
import '../widgets/day_detail_components/day_detail_body.dart';

class DayDetailPage extends StatelessWidget {

  const DayDetailPage({super.key, required this.day});
  final RamadanDay day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyMedium,
      appBar: DayDetailAppBar(day: day),
      body: DayDetailBody(day: day),
    );
  }
}
