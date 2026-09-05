import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_controller.dart';
import '../bloc/auth_state.dart';
import '../../../mosques/presentation/pages/mosque_requests_page.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';

import '../widgets/profile_components/profile_item.dart';
import '../widgets/profile_components/edit_profile_dialog.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _translateRole(String? role) {
    if (role == null) return 'مستخدم';
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'mosque_admin':
        return 'مدير مسجد';
      case 'publisher':
        return 'ناشر';
      case 'listener':
        return 'مستمع';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(
                        LucideIcons.user,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ProfileItem(
                    icon: LucideIcons.mail,
                    label: 'البريد الإلكتروني',
                    value: user.email,
                  ),
                  const SizedBox(height: 16),
                  ProfileItem(
                    icon: LucideIcons.user,
                    label: 'اسم المستخدم',
                    value: user.username ?? 'غير محدد',
                  ),
                  const SizedBox(height: 16),
                  ProfileItem(
                    icon: LucideIcons.shield,
                    label: 'الدور',
                    value: _translateRole(user.role),
                  ),
                  const SizedBox(height: 16),
                  if (user.mosqueId != null)
                    ProfileItem(
                      icon: LucideIcons.landmark,
                      label: 'المسجد التابع له',
                      value: 'معرف المسجد: ${user.mosqueId}',
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => EditProfileDialog.show(context, ref),
                      icon: const Icon(LucideIcons.edit),
                      label: const Text(
                        'تعديل الملف الشخصي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (user.role == 'admin') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MosqueRequestsPage(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.inbox),
                        label: const Text(
                          'إدارة طلبات المساجد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          } else if (state is AuthLoading) {
            return const AppLoadingIndicator();
          } else {
            return const Center(child: Text('الرجاء تسجيل الدخول مرة أخرى'));
          }
        },
      ),
    );
  }
}
