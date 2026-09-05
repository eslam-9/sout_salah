import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/mosque.dart';

class MosqueInfoHeader extends StatelessWidget {
  final Mosque mosque;

  const MosqueInfoHeader({super.key, required this.mosque});

  @override
  Widget build(BuildContext context) {
    return Text(
      mosque.name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
      textAlign: TextAlign.center,
    );
  }
}
