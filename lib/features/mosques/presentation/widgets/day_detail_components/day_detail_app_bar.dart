import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/ramadan_day.dart';

class DayDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final RamadanDay day;

  const DayDetailAppBar({super.key, required this.day});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
    return AppBar(
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
    );
  }
}
