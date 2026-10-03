import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/startup_service.dart';
import '../di/riverpod_providers.dart';
import '../services/navigation_service.dart';
import '../../../features/auth/presentation/providers/auth_controller.dart';

class StartupCheckWrapper extends ConsumerStatefulWidget {
  const StartupCheckWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StartupCheckWrapper> createState() =>
      _StartupCheckWrapperState();
}

class _StartupCheckWrapperState extends ConsumerState<StartupCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkStartupData();
  }

  Future<void> _checkStartupData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        // Check auth status first
        await _checkAuthStatus();

        // Then check startup data
        final startupService = ref.read(startupServiceProvider);
        final data = await startupService.checkStartupData();

        if (data != null && data.info.isNotEmpty) {
          if (!mounted) return;
          _showInfoDialog(data);
        }
      } catch (e) {
        ref.read(appLoggerProvider).e('Error in startup check wrapper', e);
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.checkAuthStatus();
    } catch (e) {
      ref.read(appLoggerProvider).e('Error checking auth status', e);
      // Continue anyway - don't block app startup on auth errors
    }
  }

  void _showInfoDialog(StartupData data) {
    // Use the navigator context, as this widget is above the Navigator in the tree
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      ref
          .read(appLoggerProvider)
          .w('Navigator context is null, cannot show dialog');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Prevent back button from closing dialog
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.system_update_rounded,
            size: 50,
            color: Color(0xFF2E7D32), // App primary color
          ),
          title: const Text(
            'تحديث إجباري',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.info,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (data.link.isNotEmpty)
              ElevatedButton(
                onPressed: () => _launchUrl(data.link),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تحديث الآن', // Update Now
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ref.read(appLoggerProvider).w('Could not launch $urlString');
      }
    } catch (e) {
      ref.read(appLoggerProvider).e('Error launching URL', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
