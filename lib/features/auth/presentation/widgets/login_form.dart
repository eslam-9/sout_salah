import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import 'login_fields.dart';
import 'login_actions.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});
  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _vis = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LoginFields(
            email: _email,
            pass: _pass,
            vis: _vis,
            toggle: () => setState(() => _vis = !_vis),
          ),
          LoginActions(
            onSignIn: () =>
                ref.read(authProvider.notifier).signIn(_email.text, _pass.text),
            onSignUp: () =>
                ref.read(authProvider.notifier).signUp(_email.text, _pass.text),
            onGuest: () => ref.read(authProvider.notifier).signInAnonymously(),
          ),
        ],
      ),
    );
  }
}
