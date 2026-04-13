import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_controller.dart';
import '../bloc/auth_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
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
                  _buildProfileItem(
                    icon: LucideIcons.mail,
                    label: 'البريد الإلكتروني',
                    value: user.email,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileItem(
                    icon: LucideIcons.user,
                    label: 'اسم المستخدم',
                    value: user.username ?? 'غير محدد',
                  ),
                  const SizedBox(height: 16),
                  _buildProfileItem(
                    icon: LucideIcons.shield,
                    label: 'الدور',
                    value: _translateRole(user.role),
                  ),
                  const SizedBox(height: 16),
                  if (user.mosqueId != null)
                    _buildProfileItem(
                      icon: LucideIcons.landmark,
                      label: 'المسجد التابع له',
                      value:
                          'معرف المسجد: ${user.mosqueId}', // We would need to fetch mosque name ideally
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, ref),
                      icon: const Icon(LucideIcons.edit),
                      label: Text(
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
                ],
              ),
            );
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('الرجاء تسجيل الدخول مرة أخرى'));
          }
        },
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(authProvider);
    if (state is! AuthAuthenticated) return;

    final controller = TextEditingController(text: state.user.username ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم المستخدم',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) return;

              Navigator.pop(context);
              final success = await ref
                  .read(authProvider.notifier)
                  .updateUsername(newUsername);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم التحديث بنجاح' : 'فشل التحديث'),
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
