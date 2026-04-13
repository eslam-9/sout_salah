import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/ramadan_days_provider.dart';
import 'mosque_detail_calendar_view.dart';

class MosqueDetailBody extends StatelessWidget {
  final RamadanDaysState state;

  const MosqueDetailBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is RamadanDaysLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is RamadanDaysError) {
      final err = state as RamadanDaysError;
      if (err.previousData != null) {
        return Column(
          children: [
            Container(
              color: Colors.orange.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.wifiOff,
                    color: Colors.orange.shade800,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'لا يوجد اتصال. عرض البيانات المحفوظة.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: MosqueDetailCalendarView(days: err.previousData!)),
          ],
        );
      }
      return Center(child: Text(err.message));
    }
    if (state is RamadanDaysLoadedState) {
      return MosqueDetailCalendarView(
        days: (state as RamadanDaysLoadedState).days,
      );
    }
    return const Center(child: Text('لا توجد بيانات'));
  }
}
