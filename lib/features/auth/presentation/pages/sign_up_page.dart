import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_controller.dart';
import '../bloc/auth_state.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';

import '../widgets/sign_up_components/sign_up_header.dart';
import '../widgets/sign_up_components/sign_up_form.dart';
import '../widgets/sign_up_components/sign_up_footer.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationService.navigateAndReplace(AppRoutes.home);
        });
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SignUpHeader(),
              SignUpForm(
                isLoading: state is AuthLoading,
                onSignUp: (email, password, username) {
                  ref.read(authProvider.notifier).signUp(
                        email: email,
                        password: password,
                        username: username,
                      );
                },
              ),
              const SizedBox(height: 16),
              const SignUpFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
