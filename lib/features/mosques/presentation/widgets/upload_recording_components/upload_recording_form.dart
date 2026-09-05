import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/prayer.dart';

class UploadRecordingForm extends StatelessWidget {
  final TextEditingController sheikhNameController;
  final TextEditingController customPrayerController;
  final Prayer? selectedPrayer;
  final ValueChanged<Prayer?> onPrayerSelected;
  final Prayer? initialPrayer;
  final String? pendingRecordingId;

  const UploadRecordingForm({
    super.key,
    required this.sheikhNameController,
    required this.customPrayerController,
    required this.selectedPrayer,
    required this.onPrayerSelected,
    this.initialPrayer,
    this.pendingRecordingId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sheikh name input
        Text(
          'اسم القارئ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        TextFormField(
          textDirection: TextDirection.rtl,
          controller: sheikhNameController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'أدخل اسم الشيخ',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(
              LucideIcons.user,
              color: AppColors.primary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال اسم القارئ';
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // Prayer selection
        Text(
          'عنوان التلاوة',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Prayer>(
          // ignore: deprecated_member_use
          value: selectedPrayer,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'اختر الصلاة',
            filled: true,
            fillColor: initialPrayer != null
                ? Colors.grey.shade200
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: initialPrayer != null ? null : onPrayerSelected,
          items: Prayer.allPrayers.map((prayer) {
            return DropdownMenuItem(
              value: prayer,
              alignment: Alignment.centerRight,
              child: Text(
                prayer.arabicName,
                textAlign: TextAlign.right,
              ),
            );
          }).toList(),
          validator: (value) => value == null ? 'الرجاء اختيار الصلاة' : null,
        ),

        if (selectedPrayer == Prayer.other) ...[
          const SizedBox(height: 16),
          Text(
            'اسم التلاوة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          TextFormField(
            textDirection: TextDirection.rtl,
            controller: customPrayerController,
            textAlign: TextAlign.right,
            readOnly: pendingRecordingId != null,
            decoration: InputDecoration(
              hintText: 'مثال: تهجد',
              filled: true,
              fillColor: pendingRecordingId != null
                  ? Colors.grey.shade200
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (selectedPrayer == Prayer.other &&
                  (value == null || value.trim().isEmpty)) {
                return 'الرجاء إدخال اسم التلاوة';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
