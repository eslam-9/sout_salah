import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/services/navigation_service.dart';
import '../../../domain/entities/ramadan_day.dart';

class MosqueDetailDayCircle extends StatelessWidget {
  final RamadanDay day;
  final bool isToday;

  const MosqueDetailDayCircle({
    super.key,
    required this.day,
    required this.isToday,
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
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade200;
    Color text = Colors.grey.shade400;
    bool check = false;

    if (day.status == 'green') {
      bg = AppColors.primary;
      text = Colors.white;
      check = true;
    } else if (day.status == 'yellow') {
      bg = AppColors.accentYellow;
      text = AppColors.accentYellowDark;
    }

    return GestureDetector(
      onTap: () =>
          NavigationService.navigateTo(AppRoutes.dayDetail, arguments: day),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _toArabicNumerals(day.dayNumber),
                style: TextStyle(
                  fontFamily: 'Rubik',
                  color: text,
                  fontWeight: FontWeight.w700,
                  fontSize: isToday || check ? 16 : 18,
                ),
              ),
              if (isToday)
                Text(
                  'اليوم',
                  style: TextStyle(
                    color: text,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!isToday && check)
                const Icon(LucideIcons.check, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
