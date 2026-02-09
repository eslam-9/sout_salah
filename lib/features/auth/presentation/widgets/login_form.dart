import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'login_fields.dart';
import 'login_actions.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
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
            onSignIn: () => context.read<AuthBloc>().add(
              SignInRequested(email: _email.text, password: _pass.text),
            ),
            onSignUp: () => context.read<AuthBloc>().add(
              SignUpRequested(email: _email.text, password: _pass.text),
            ),
            onGuest: () => context.read<AuthBloc>().add(GuestLoginRequested()),
          ),
        ],
      ),
    );
  }
}
