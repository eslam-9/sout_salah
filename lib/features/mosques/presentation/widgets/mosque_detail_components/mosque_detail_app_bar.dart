import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/mosque.dart';
import '../../../../auth/presentation/providers/auth_controller.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../pages/add_publisher_page.dart';
import '../../pages/mosque_info_page.dart';

class MosqueDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Mosque mosque;

  const MosqueDetailAppBar({super.key, required this.mosque});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.calendar, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            mosque.name,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (authState is AuthAuthenticated &&
            (authState.user.role == 'admin' ||
                authState.user.id == mosque.adminId))
          IconButton(
            icon: const Icon(LucideIcons.userPlus, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => AddPublisherPage(mosqueId: mosque.id),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(LucideIcons.info, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MosqueInfoPage(mosque: mosque),
              ),
            );
          },
        ),
      ],
    );
  }
}
