import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../domain/entities/mosque_location.dart';
import 'mosque_location_section.dart';
import 'add_mosque_text_fields.dart';
import 'add_mosque_submit_button.dart';

class AddMosqueForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final bool isLoading;
  final bool isSuperAdmin;
  final ValueChanged<MosqueLocation?> onLocationChanged;
  final VoidCallback onSubmit;

  const AddMosqueForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.locationController,
    required this.descriptionController,
    required this.isLoading,
    required this.isSuperAdmin,
    required this.onLocationChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddMosqueTextField(
            controller: nameController,
            label: 'اسم المسجد',
            icon: LucideIcons.landmark,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم المسجد';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          MosqueLocationSection(
            onLocationChanged: onLocationChanged,
          ),
          const SizedBox(height: 16),
          AddMosqueTextField(
            controller: locationController,
            label: 'عنوان المسجد (اختياري / يُضاف تلقائياً)',
            icon: LucideIcons.mapPin,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال الموقع أو استخدامه من الخريطة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AddMosqueTextField(
            controller: descriptionController,
            label: 'الوصف (اختياري)',
            icon: LucideIcons.fileText,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          AddMosqueSubmitButton(
            isLoading: isLoading,
            isSuperAdmin: isSuperAdmin,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}
