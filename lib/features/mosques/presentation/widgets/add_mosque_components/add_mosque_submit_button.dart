import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class AddMosqueSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isSuperAdmin;
  final VoidCallback onSubmit;

  const AddMosqueSubmitButton({
    super.key,
    required this.isLoading,
    required this.isSuperAdmin,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              isSuperAdmin ? 'إضافة المسجد' : 'إرسال طلب إضافة',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
