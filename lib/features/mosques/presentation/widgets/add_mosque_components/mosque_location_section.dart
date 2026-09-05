import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../domain/entities/mosque_location.dart';
import '../../providers/mosque_location_picker_provider.dart';
import '../../providers/mosque_location_picker_state.dart';
import 'mosque_location_map_preview.dart';
import 'mosque_location_actionable_error.dart';
import 'mosque_location_search_button.dart';

class MosqueLocationSection extends ConsumerStatefulWidget {
  final ValueChanged<MosqueLocation?> onLocationChanged;

  const MosqueLocationSection({
    super.key,
    required this.onLocationChanged,
  });

  @override
  ConsumerState<MosqueLocationSection> createState() => _MosqueLocationSectionState();
}

class _MosqueLocationSectionState extends ConsumerState<MosqueLocationSection> {
  @override
  Widget build(BuildContext context) {
    ref.listen(mosqueLocationPickerProvider, (previous, next) {
      if (next is AsyncData) {
        final state = next.value!;
        if (state.status == LocationPickerStatus.success) {
          GetIt.I<AppLogger>().i('Location acquired successfully in MosqueLocationSection');
          widget.onLocationChanged(state.mosqueLocation);
        } else if (state.status == LocationPickerStatus.idle || state.status == LocationPickerStatus.error || state.status == LocationPickerStatus.permissionDenied) {
          widget.onLocationChanged(null);
        }
      }
    });

    final stateAsync = ref.watch(mosqueLocationPickerProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'موقع المسجد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          stateAsync.when(
            data: (state) => _buildState(state),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              GetIt.I<AppLogger>().e('Error in MosqueLocationSection', err, stack);
              return _buildErrorState(err.toString());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildState(MosqueLocationPickerState state) {
    switch (state.status) {
      case LocationPickerStatus.idle:
        return MosqueLocationSearchButton(
          onPressed: () => ref.read(mosqueLocationPickerProvider.notifier).requestCurrentLocation(),
        );
      case LocationPickerStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      case LocationPickerStatus.success:
        return MosqueLocationMapPreview(
          location: state.mosqueLocation!,
          onChangeLocation: () => ref.read(mosqueLocationPickerProvider.notifier).requestCurrentLocation(),
        );
      case LocationPickerStatus.permissionDenied:
        return MosqueLocationActionableError(
          message: 'لم يتم منح إذن الوصول للموقع',
          buttonText: 'إعادة المحاولة',
          onPressed: () => ref.read(mosqueLocationPickerProvider.notifier).requestCurrentLocation(),
        );
      case LocationPickerStatus.permissionPermanentlyDenied:
        return MosqueLocationActionableError(
          message: 'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق',
          buttonText: 'فتح الإعدادات',
          onPressed: () => openAppSettings(),
        );
      case LocationPickerStatus.serviceDisabled:
        return MosqueLocationActionableError(
          message: 'خدمة الموقع معطلة. يرجى تفعيل GPS من إعدادات الجهاز',
          buttonText: 'إعادة المحاولة',
          onPressed: () => ref.read(mosqueLocationPickerProvider.notifier).requestCurrentLocation(),
        );
      case LocationPickerStatus.unavailable:
      case LocationPickerStatus.error:
        return _buildErrorState(state.errorMessage ?? 'حدث خطأ غير متوقع');
    }
  }

  Widget _buildErrorState(String message) {
    return MosqueLocationActionableError(
      message: message,
      buttonText: 'إعادة المحاولة',
      onPressed: () => ref.read(mosqueLocationPickerProvider.notifier).requestCurrentLocation(),
    );
  }
}
