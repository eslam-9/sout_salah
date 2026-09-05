import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../domain/entities/mosque.dart';
import '../../providers/mosque_data_providers.dart';
import '../../../domain/usecases/open_mosque_in_maps_usecase.dart';

class MosqueInfoMapsButton extends ConsumerWidget {
  final Mosque mosque;

  const MosqueInfoMapsButton({super.key, required this.mosque});

  Future<void> _openMaps(BuildContext context, WidgetRef ref) async {
    if (mosque.latitude == null || mosque.longitude == null) return;
    
    GetIt.I<AppLogger>().i('Opening maps for ${mosque.name} at ${mosque.latitude}, ${mosque.longitude}');
    
    final openMosqueInMapsUseCase = ref.read(openMosqueInMapsUseCaseProvider);
    final result = await openMosqueInMapsUseCase(
      OpenMapsParams(
        latitude: mosque.latitude!,
        longitude: mosque.longitude!,
      ),
    );

    result.fold(
      (failure) {
        GetIt.I<AppLogger>().e('Failed to open maps: ${failure.message}');
        if (context.mounted) {
          AppSnackBar.showError(context, failure.message);
        }
      },
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mosque.latitude == null || mosque.longitude == null) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _openMaps(context, ref),
      icon: const Icon(LucideIcons.externalLink, size: 18),
      label: const Text(
        'فتح في خرائط جوجل',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
