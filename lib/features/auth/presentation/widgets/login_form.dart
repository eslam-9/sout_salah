import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../pages/sign_up_page.dart';
import 'login_fields.dart';
import 'login_actions.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});
  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _vis = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            LoginFields(
              email: _email,
              pass: _pass,
              vis: _vis,
              toggle: () => setState(() => _vis = !_vis),
              emailValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'الرجاء إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
              passwordValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            LoginActions(
              onSignIn: () {
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(authProvider.notifier)
                      .signIn(_email.text.trim(), _pass.text);
                }
              },
              onSignUp: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpPage()),
              ),
              onGuest: () =>
                  ref.read(authProvider.notifier).signInAnonymously(),
            ),
          ],
        ),
      ),
    );
  }
}
