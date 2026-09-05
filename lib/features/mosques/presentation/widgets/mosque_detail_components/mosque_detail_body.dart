import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../domain/entities/ramadan_day.dart';
import 'mosque_detail_calendar_view.dart';

class MosqueDetailBody extends StatelessWidget {
  final AsyncValue<List<RamadanDay>> state;

  const MosqueDetailBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.hasValue) {
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
          Expanded(child: MosqueDetailCalendarView(days: state.value!)),
        ],
      );
    }
    
    if (state.hasError && !state.hasValue) {
      return Center(child: Text(state.error.toString()));
    }

    if (state.hasValue) {
      return MosqueDetailCalendarView(
        days: state.value!,
      );
    }
    
    return const Center(child: Text('لا توجد بيانات'));
  }
}

