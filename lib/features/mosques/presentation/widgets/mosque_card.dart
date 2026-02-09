import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                // Heart Icon
                Icon(LucideIcons.heart, color: Colors.grey[300], size: 24),
                const Spacer(),
                // Mosque Info (RTL)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mosque.name,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mosque.location ?? 'Unknown Location',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                const SizedBox(width: 16),
                // Mosque Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light Green
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.landmark, // Closest to Mosque
                    color: Color(0xFF2E7D32), // Dark Green
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
                  text: '120 تسجيل', // Placeholder stats for now
                  color: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  icon: LucideIcons.moon,
                  text: '30 ليلة', // Placeholder stats
                  color: const Color(0xFFFFF3E0), // Light Orange
                  textColor: const Color(0xFFEF6C00), // Dark Orange
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
            style: GoogleFonts.cairo(
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
