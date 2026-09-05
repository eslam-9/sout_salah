import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/ramadan_days_provider.dart';
import '../../providers/month_year.dart';

class MosqueDetailMonthNavigator extends ConsumerWidget {
  final String mosqueId;
  final MonthYear? selectedMonth;
  final ValueChanged<MonthYear> onMonthSelected;

  const MosqueDetailMonthNavigator({
    super.key,
    required this.mosqueId,
    required this.selectedMonth,
    required this.onMonthSelected,
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
    final monthsAsync = ref.watch(availableMonthsProvider(mosqueId));

    return monthsAsync.when(
      data: (months) {
        if (months.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final m = months[index];
              final isSelected = selectedMonth == m;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    '${m.arabicMonthName} ${_toArabicNumerals(m.year)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      onMonthSelected(m);
                      ref.read(ramadanDaysProvider.notifier).loadDays(
                            mosqueId,
                            month: m.month,
                            year: m.year,
                          );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: LinearProgressIndicator(minHeight: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
