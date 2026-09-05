import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/mosque_controller.dart';
import '../providers/mosque_requests_provider.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../../core/utils/app_snackbar.dart';

import '../widgets/add_mosque_components/add_mosque_form.dart';

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

  @override
  void initState() {
    super.initState();
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
      Navigator.of(context).pop();
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
      try {
        if (_isSuperAdmin) {
          await ref
              .read(mosqueProvider.notifier)
              .addMosque(
                name: _nameController.text.trim(),
                location: _locationController.text.trim(),
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
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              );

          if (mounted) {
            AppSnackBar.showSuccess(
              context,
              "تم إرسال طلب إنشاء المسجد بنجاح. سيتم مراجعته من قبل الإدارة.",
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
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
        Navigator.of(context).pop();
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
          onPressed: () => Navigator.pop(context),
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
          onSubmit: _submitForm,
        ),
      ),
    );
  }
}
