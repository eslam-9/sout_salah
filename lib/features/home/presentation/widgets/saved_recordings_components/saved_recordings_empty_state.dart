import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedRecordingsEmptyState extends StatelessWidget {
  const SavedRecordingsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bookmark,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تلاوات محفوظة',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على ❤️ لحفظ التلاوات المفضلة',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
