import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated) {
        NavigationService.navigateAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isGuest = authState is AuthGuest;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          if (!isGuest)
            _buildSettingsItem(
              icon: LucideIcons.user,
              title: 'الملف الشخصي',
              onTap: (context) {
                NavigationService.navigateTo(AppRoutes.profile);
              },
              isContextRequired: true,
            ),
          if (!isGuest) const SizedBox(height: 16),
          _buildSettingsItem(
            icon: LucideIcons.logOut,
            title: isGuest ? 'خروج من وضع الزائر' : 'تسجيل الخروج',
            color: Colors.red,
            textColor: Colors.red,
            onTap: (BuildContext context) {
              ref.read(authProvider.notifier).signOut();
            },
            isContextRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Color color = Colors.black87,
    Color textColor = Colors.black87,
    required Function onTap,
    bool isContextRequired = false,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => isContextRequired ? onTap(context) : onTap(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronLeft, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }
}
