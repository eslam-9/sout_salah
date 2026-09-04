import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../home/presentation/providers/favorites_provider.dart';
import '../../../../../core/di/riverpod_providers.dart';
import '../../../domain/entities/recording.dart';

class DayRecordingFavoriteButton extends ConsumerWidget {
  final Recording recording;

  const DayRecordingFavoriteButton({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(recording.id));

    return isFavoriteAsync.when(
      data: (isFavorite) => InkWell(
        onTap: () async {
          final favoritesService = ref.read(favoritesServiceProvider);
          if (isFavorite) {
            await favoritesService.removeFavorite(recording.id);
            ref.invalidate(isFavoriteProvider(recording.id));
            ref.invalidate(allFavoritesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم إزالة التلاوة من المحفوظات'),
                  backgroundColor: Colors.grey.shade700,
                ),
              );
            }
          } else {
            try {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري تحميل التلاوة...'),
                    duration: Duration(seconds: 30),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
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
        child: Icon(
          LucideIcons.heart,
          color: isFavorite ? Colors.red.shade400 : Colors.grey.shade400,
          size: 20,
        ),
      ),
      loading: () => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey.shade400,
        ),
      ),
      error: (_, s) =>
          Icon(LucideIcons.heart, color: Colors.grey.shade400, size: 20),
    );
  }
}
