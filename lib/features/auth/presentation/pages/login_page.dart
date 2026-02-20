import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../bloc/auth_state.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated || next is AuthGuest) {
        if (next is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
          );
        }
        NavigationService.navigateAndReplace(AppRoutes.home);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: state is AuthLoading
          ? const Center(child: CircularProgressIndicator())
          : const SingleChildScrollView(
              child: Column(children: [AuthHeader(), LoginForm()]),
            ),
    );
  }
}
