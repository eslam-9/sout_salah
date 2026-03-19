import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class MosqueDetailLegend extends StatelessWidget {
  const MosqueDetailLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('فارغ', Colors.grey.shade300),
        const SizedBox(width: 16),
        _buildLegendItem('جزئي', AppColors.accentYellow),
        const SizedBox(width: 16),
        _buildLegendItem('مكتمل', AppColors.primary),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
