import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Greens
  static const Color primary = Color(0xFF2E7D32); // Dark Green
  static const Color primaryLight = Color(0xFFE8F5E9); // Light Green
  static const Color primaryDark = Color(0xFF1B5E20);

  // Accents
  static const Color accentOrange = Color(0xFFEF6C00); // Dark Orange
  static const Color accentOrangeLight = Color(0xFFFFF3E0); // Light Orange
  static const Color accentYellow = Color(0xFFFFF3CD); // Light Yellow
  static const Color accentYellowDark = Color(0xFF856404); // Dark Yellow

  // Neutrals
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color grey = Colors.grey;
  static const Color greyLight = Color(
    0xFFF9FAFB,
  ); // Very light grey background
  static const Color greyMedium = Color(0xFFF5F5F5);

  // Status
  static const Color error = Colors.red;
  static const Color success = Colors.green;
}

class AppTextStyles {
  static TextTheme get textTheme => GoogleFonts.cairoTextTheme();
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accentOrange,
        surface: AppColors.greyLight,
        onSurface: AppColors.black,
        error: AppColors.error,
      ),
      useMaterial3: true,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: AppColors.greyLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.black),
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.grey.withAlpha(50),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withAlpha(30),
      ),
    );
  }
}
