import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/riverpod_providers.dart';
import '../../../domain/entities/recording.dart';
import '../../../../home/presentation/providers/favorites_provider.dart';

class AudioFavoriteButton extends ConsumerWidget {
  final Recording recording;

  const AudioFavoriteButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        onPressed: () async {
          final favoritesService = ref.read(favoritesServiceProvider);

          if (isFavorite) {
            await favoritesService.removeFavorite(recording.id);
            ref.invalidate(isFavoriteProvider(recording.id));
            ref.invalidate(allFavoritesProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم إزالة التلاوة من المحفوظات',
                  ),
                  backgroundColor: Colors.grey.shade700,
                ),
              );
            }
          } else {
            try {
              await favoritesService.addFavorite(recording);
              ref.invalidate(isFavoriteProvider(recording.id));
              ref.invalidate(allFavoritesProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❤️ تم حفظ التلاوة'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فشل حفظ التلاوة'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        icon: Icon(
          LucideIcons.heart,
          color: isFavorite ? Colors.red.shade400 : Colors.grey.shade400,
        ),
        iconSize: 28,
        tooltip: 'إضافة للمفضلة',
      ),
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) =>
          Icon(LucideIcons.heart, color: Colors.grey.shade400, size: 28),
    );
  }
}
