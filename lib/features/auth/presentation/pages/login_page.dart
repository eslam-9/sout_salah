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
    // Track if we've done the initial loading check
    final hasDoneInitialCheck = ref.watch(initialCheckDoneProvider);

    // Listen to auth state changes for snackbar and navigation
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Only show snackbar/navigate if we've done the initial check
      if (hasDoneInitialCheck) {
        if (next is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateAndReplace(AppRoutes.home);
          });
        } else if (next is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.message)));
        }
      }

      // Mark that we've completed the initial loading check
      if (previous is AuthLoading) {
        ref.read(initialCheckDoneProvider.notifier).update((state) => true);
      }
    });

    final state = ref.watch(authProvider);

    // Show loading indicator during initial check
    if (!hasDoneInitialCheck && state is AuthLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Handle different states after initial check
    if (state is AuthLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (state is AuthError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Reset to initial state to allow retry
                    ref.read(authProvider.notifier).state = AuthInitial();
                    // Reset initial check flag
                    ref
                        .read(initialCheckDoneProvider.notifier)
                        .update((state) => false);
                  },
                  child: const Text('محاولة مرة أخرى'),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (state is AuthAuthenticated) {
      // Navigate to home if somehow we're authenticated on login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationService.navigateAndReplace(AppRoutes.home);
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show login form for initial/unauthenticated state
    return Scaffold(
      backgroundColor: Colors.white,
      body: const SingleChildScrollView(
        child: Column(children: [AuthHeader(), LoginForm()]),
      ),
    );
  }
}

// Provider to track if initial auth check has been completed
final initialCheckDoneProvider = StateProvider<bool>((ref) => false);
