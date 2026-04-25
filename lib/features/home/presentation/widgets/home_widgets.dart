import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;

  const HomeAppBar({super.key, this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'المساجد',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          TextField(
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '...ابحث عن مسجد',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              suffixIcon: const Icon(
                LucideIcons.search,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        reverse: true, // RTL List
        children: [
          _buildChip('الكل', true),
          _buildChip('الأقرب إليك', false),
          _buildChip('الأكثر استماعاً', false),
          _buildChip('الجديد', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
