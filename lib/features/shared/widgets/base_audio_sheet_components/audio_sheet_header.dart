import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AudioSheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final Widget? extraInfo;

  const AudioSheetHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAction,
    this.trailingAction,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Leading Action (or placeholder for balance)
        if (leadingAction != null)
          leadingAction!
        else if (trailingAction != null)
          const SizedBox(width: 48), // Approximate size of IconButton

        const Spacer(),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (extraInfo != null) ...[
                const SizedBox(height: 8),
                extraInfo!,
              ],
            ],
          ),
        ),
        const Spacer(),

        // Trailing Action (or placeholder for balance)
        if (trailingAction != null)
          trailingAction!
        else if (leadingAction != null)
          const SizedBox(width: 48),
      ],
    );
  }
}
