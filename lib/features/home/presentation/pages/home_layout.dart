import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import 'mosques_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'saved_recordings_page.dart';

class HomeLayout extends ConsumerStatefulWidget {
  const HomeLayout({super.key});

  @override
  ConsumerState<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends ConsumerState<HomeLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MosquesPage(),
    const DownloadsPage(),
    const SavedRecordingsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Check authentication status on startup if not already checked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState is AuthInitial) {
        ref.read(authProvider.notifier).checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated) {
        NavigationService.navigateAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    });
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed, // Required for 4+ items
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.download),
              label: 'التنزيلات',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.heart),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
