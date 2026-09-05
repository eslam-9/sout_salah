import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/device_audio_selection_components/device_audio_permission_view.dart';
import '../widgets/device_audio_selection_components/device_audio_list.dart';

class DeviceAudioSelectionPage extends ConsumerStatefulWidget {
  const DeviceAudioSelectionPage({super.key});

  @override
  ConsumerState<DeviceAudioSelectionPage> createState() =>
      _DeviceAudioSelectionPageState();
}

class _DeviceAudioSelectionPageState
    extends ConsumerState<DeviceAudioSelectionPage> {
  final _audioQuery = OnAudioQuery();
  final _searchController = TextEditingController();
  bool _hasPermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    // For Android 13+ (SDK 33+), we need READ_MEDIA_AUDIO
    // For older versions, we need READ_EXTERNAL_STORAGE

    // Attempt to request audio permission first (Android 13+)
    var audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) {
      setState(() => _hasPermission = true);
      return;
    }

    // Attempt to request storage permission (Android < 13)
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      setState(() => _hasPermission = true);
      return;
    }

    // Strategy: Request audio first.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    if (statuses[Permission.audio]!.isGranted ||
        statuses[Permission.storage]!.isGranted) {
      setState(() => _hasPermission = true);
    } else {
      if (statuses[Permission.audio]!.isPermanentlyDenied ||
          statuses[Permission.storage]!.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('يجب تفعيل الصلاحيات من الإعدادات'),
              action: SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
      setState(() => _hasPermission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'اختر التلاوة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              textDirection: TextDirection.ltr,
              controller: _searchController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'بحث عن تلاوة...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: !_hasPermission
          ? DeviceAudioPermissionView(
              onRequestPermission: _checkPermission,
            )
          : DeviceAudioList(
              audioQuery: _audioQuery,
              searchQuery: _searchQuery,
            ),
    );
  }
}
