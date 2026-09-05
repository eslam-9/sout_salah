import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSnackBar {
  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.success,
      duration: duration,
    );
  }

  static void showError(BuildContext context, String message, {Duration duration = const Duration(seconds: 5)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.error,
      duration: duration,
    );
  }

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blueGrey, // Standard info color
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Duration duration,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
