import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  final bool centered;
  final double? size;
  final Color color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.centered = true,
    this.size,
    this.color = AppColors.primary,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = CircularProgressIndicator(
      color: color,
      strokeWidth: strokeWidth,
    );

    if (size != null) {
      indicator = SizedBox(
        width: size,
        height: size,
        child: indicator,
      );
    }

    if (centered) {
      return Center(child: indicator);
    }

    return indicator;
  }
}
