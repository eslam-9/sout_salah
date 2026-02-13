import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/startup_service.dart';
import '../services/navigation_service.dart';

class StartupCheckWrapper extends StatefulWidget {
  final Widget child;

  const StartupCheckWrapper({super.key, required this.child});

  @override
  State<StartupCheckWrapper> createState() => _StartupCheckWrapperState();
}

class _StartupCheckWrapperState extends State<StartupCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkStartupData();
  }

  Future<void> _checkStartupData() async {
    // Small delay to ensure the widget tree is built and splash is gone
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final startupService = GetIt.I<StartupService>();
      final data = await startupService.checkStartupData();

      if (data != null && data.info.isNotEmpty) {
        if (!mounted) return;
        _showInfoDialog(data);
      }
    } catch (e) {
      GetIt.I<AppLogger>().e('Error in startup check wrapper', e);
    }
  }

  void _showInfoDialog(StartupData data) {
    // Use the navigator context, as this widget is above the Navigator in the tree
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      GetIt.I<AppLogger>().w('Navigator context is null, cannot show dialog');
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
        GetIt.I<AppLogger>().w('Could not launch $urlString');
      }
    } catch (e) {
      GetIt.I<AppLogger>().e('Error launching URL', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
