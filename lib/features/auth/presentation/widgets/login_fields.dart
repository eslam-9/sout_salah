import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class LoginFields extends StatelessWidget {
  final TextEditingController email, pass;
  final bool vis;
  final VoidCallback toggle;
  const LoginFields({
    super.key,
    required this.email,
    required this.pass,
    required this.vis,
    required this.toggle,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CustomTextField(
        label: 'البريد الإلكتروني',
        hint: 'example@mail.com',
        ctrl: email,
        suf: const Icon(Icons.email_outlined, color: Colors.grey),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'كلمة المرور',
        hint: '........',
        ctrl: pass,
        pass: !vis,
        suf: IconButton(
          icon: Icon(
            vis ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
      ),
    ],
  );
}
