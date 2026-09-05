import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/mosque_controller.dart';
import '../providers/mosque_requests_provider.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:get_it/get_it.dart';

import '../widgets/add_mosque_components/add_mosque_form.dart';
import '../../domain/entities/mosque_location.dart';

class AddMosquePage extends ConsumerStatefulWidget {
  const AddMosquePage({super.key});

  @override
  ConsumerState<AddMosquePage> createState() => _AddMosquePageState();
}

class _AddMosquePageState extends ConsumerState<AddMosquePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSuperAdmin = false;
  MosqueLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    GetIt.I<AppLogger>().i('Opened AddMosquePage');
    _checkPermission();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final canAdd = await ref.read(permissionCheckerProvider).canAddMosque();
    if (!canAdd && mounted) {
      AppSnackBar.showError(context, 'عذراً، يجب تسجيل الدخول لإنشاء مسجد');
      NavigationService.goBack();
      return;
    }

    final isSuperAdmin = await ref
        .read(permissionCheckerProvider)
        .isSuperAdmin();
    if (mounted) {
      setState(() {
        _isSuperAdmin = isSuperAdmin;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      GetIt.I<AppLogger>().i('Submitting add mosque form');
      try {
        if (_isSuperAdmin) {
          await ref
              .read(mosqueProvider.notifier)
              .addMosque(
                name: _nameController.text.trim(),
                location: _locationController.text.trim(),
                latitude: _selectedLocation?.latitude,
                longitude: _selectedLocation?.longitude,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              );
        } else {
          await ref
              .read(mosqueRequestsProvider.notifier)
              .createRequest(
                name: _nameController.text.trim(),
                location: _locationController.text.trim(),
                latitude: _selectedLocation?.latitude,
                longitude: _selectedLocation?.longitude,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              );

          if (mounted) {
            AppSnackBar.showSuccess(
              context,
              "تم إرسال طلب إنشاء المسجد بنجاح. سيتم مراجعته من قبل الإدارة.",
            );
            NavigationService.goBack();
          }
        }
      } catch (e, stackTrace) {
        GetIt.I<AppLogger>().e('Failed to submit add mosque form', e, stackTrace);
        if (mounted) {
          AppSnackBar.showError(context, 'فشل في إرسال الطلب: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mosqueProvider, (previous, next) {
      if (next is AsyncData && previous is AsyncLoading) {
        AppSnackBar.showSuccess(context, 'تم إضافة المسجد بنجاح');
        NavigationService.goBack();
      } else if (next is AsyncError) {
        AppSnackBar.showError(
          context,
          'فشل في إضافة المسجد: ${next.error}\nتأكد من أن لديك الصلاحيات المطلوبة',
        );
      }
    });

    final state = ref.watch(mosqueProvider);
    final requestState = ref.watch(mosqueRequestsProvider);
    final isLoading = state is AsyncLoading || requestState is AsyncLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'إضافة مسجد جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
          onPressed: () => NavigationService.goBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AddMosqueForm(
          formKey: _formKey,
          nameController: _nameController,
          locationController: _locationController,
          descriptionController: _descriptionController,
          isLoading: isLoading,
          isSuperAdmin: _isSuperAdmin,
          onLocationChanged: (MosqueLocation? location) {
            setState(() {
              _selectedLocation = location;
            });
            if (location?.locationName != null && _locationController.text.isEmpty) {
              _locationController.text = location!.locationName!;
            }
          },
          onSubmit: _submitForm,
        ),
      ),
    );
  }
}
