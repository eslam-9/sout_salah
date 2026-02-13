import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late AnimationController _floatController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _floatAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Use postFrameCallback to ensure widget is built before calling auth check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNavigationTimer();
    });
  }

  void _setupAnimations() {
    // 1. Appearance Animation (Fade & Scale)
    // Removed fade-in and scale-up to match native splash screen state
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0), // Instant
      value: 1.0, // Start at end state
    );

    _fadeAnimation = ConstantTween(1.0).animate(_appearController);

    _scaleAnimation = ConstantTween(1.0).animate(_appearController);

    // 2. Anti-Gravity Float Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: const Offset(0.0, -0.05),
        ).animate(
          CurvedAnimation(
            parent: _floatController,
            curve: Curves.easeInOutSine,
          ),
        );

    // 3. Pulse/Glow Animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start appearance animation immediately
    _appearController.forward();
    _floatController.forward(); // Ensure float starts
    _glowController.forward(); // Ensure glow starts
  }

  Future<void> _startNavigationTimer() async {
    GetIt.I<AppLogger>().i(
      '🚀 Splash timer started. Checking auth and waiting...',
    );

    // Start auth check and timer concurrently
    final authFuture = ref.read(authProvider.notifier).checkAuthStatus();
    final timerFuture = Future.delayed(const Duration(seconds: 5));

    // Wait for both to complete
    await Future.wait([authFuture, timerFuture]);

    GetIt.I<AppLogger>().i('🚀 Splash timer and auth check finished.');

    if (!mounted) return;

    _navigateToNext();
  }

  void _navigateToNext() {
    final authState = ref.read(authProvider);

    // Determine route based on auth state
    String nextRoute;
    if (authState is AuthAuthenticated || authState is AuthGuest) {
      nextRoute = AppRoutes.home;
    } else {
      nextRoute = AppRoutes.login;
    }

    GetIt.I<AppLogger>().i(
      '🚀 SplashView: Navigating to $nextRoute (Auth state: ${authState.runtimeType})',
    );
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(nextRoute);
    }
  }

  @override
  void dispose() {
    _appearController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32), // Professional Green
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _appearController,
            _floatController,
            _glowController,
          ]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SlideTransition(
                  position: _floatAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow Effect behind logo
                      Opacity(
                        opacity: _glowAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Logo Image
                      Image.asset(
                        'assets/splash_screen.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
