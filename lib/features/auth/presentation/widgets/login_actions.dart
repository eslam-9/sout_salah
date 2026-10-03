import 'package:flutter/material.dart';
import 'custom_button.dart';

class LoginActions extends StatelessWidget {
  const LoginActions({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
    required this.onGuest,
  });
  final VoidCallback onSignIn, onSignUp, onGuest;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 24),
      CustomButton(
        text: 'تسجيل الدخول',
        icon: const Icon(Icons.login),
        onPressed: onSignIn,
      ),
      const SizedBox(height: 24),
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('أو', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 24),
      CustomButton(text: 'إنشاء حساب جديد', outline: true, onPressed: onSignUp),
      const SizedBox(height: 16),
      CustomButton(
        text: 'المتابعة كضيف',
        outline: true,
        icon: const Icon(Icons.person),
        onPressed: onGuest,
      ),
    ],
  );
}
