import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'mosques_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'saved_recordings_page.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MosquesPage(),
    const DownloadsPage(),
    const SavedRecordingsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
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
          selectedItemColor: const Color(0xFF2E7D32),
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
