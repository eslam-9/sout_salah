import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/ramadan_days_provider.dart';
import '../../providers/month_year.dart';

class MosqueDetailAddMonthDialog extends ConsumerStatefulWidget {
  final String mosqueId;
  final ValueChanged<MonthYear> onMonthAdded;

  const MosqueDetailAddMonthDialog({
    super.key,
    required this.mosqueId,
    required this.onMonthAdded,
  });

  @override
  ConsumerState<MosqueDetailAddMonthDialog> createState() =>
      _MosqueDetailAddMonthDialogState();
}

class _MosqueDetailAddMonthDialogState
    extends ConsumerState<MosqueDetailAddMonthDialog> {
  int selectedMonthIdx = 9; // Default to Ramadan
  int selectedYear = 1446; // Default to next year approx

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إضافة شهر جديد',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text('اختر الشهر الهجري:'),
          DropdownButton<int>(
            value: selectedMonthIdx,
            isExpanded: true,
            items: List.generate(12, (index) {
              final monthNum = index + 1;
              return DropdownMenuItem(
                value: monthNum,
                child: Text(
                  MonthYear(month: monthNum, year: 0).arabicMonthName,
                ),
              );
            }),
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedMonthIdx = val);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('السنة الهجرية:'),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'مثلاً 1446'),
            onChanged: (val) {
              final year = int.tryParse(val);
              if (year != null) selectedYear = year;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(ramadanDaysProvider.notifier)
                  .addMonth(widget.mosqueId, selectedMonthIdx, selectedYear);

              if (!context.mounted) return;

              if (success) {
                Navigator.pop(context);
                ref.invalidate(availableMonthsProvider(widget.mosqueId));
                widget.onMonthAdded(
                  MonthYear(month: selectedMonthIdx, year: selectedYear),
                );
                ref.read(ramadanDaysProvider.notifier).loadDays(
                      widget.mosqueId,
                      month: selectedMonthIdx,
                      year: selectedYear,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة الشهر بنجاح')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فشل إضافة الشهر. ربما هو موجود بالفعل؟'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إضافة',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
