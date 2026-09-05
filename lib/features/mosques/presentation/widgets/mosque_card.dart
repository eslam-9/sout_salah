import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../mosques/domain/entities/mosque.dart';

class MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback onTap;

  const MosqueCard({super.key, required this.mosque, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        mosque.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              mosque.location ?? 'غير معروف',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Mosque Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight, // Light Green
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.landmark, // Closest to Mosque
                    color: AppColors.primary, // Dark Green
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStatBadge(
                  icon: LucideIcons.mic,
                  text: '${mosque.recordingCount} تسجيل',
                  color: AppColors.primaryLight,
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  icon: LucideIcons.moon,
                  text: '30 ليلة', // Placeholder stats
                  color: AppColors.accentOrangeLight, // Light Orange
                  textColor: AppColors.accentOrange, // Dark Orange
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: textColor),
        ],
      ),
    );
  }
}
