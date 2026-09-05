import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_controller.dart';
import '../../bloc/auth_state.dart';

class EditProfileDialog {
  static void show(BuildContext context, WidgetRef ref) {
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
