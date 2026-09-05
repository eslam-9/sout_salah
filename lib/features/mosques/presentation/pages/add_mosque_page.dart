import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/mosque_controller.dart';
import '../providers/mosque_requests_provider.dart';
import '../bloc/mosque_state_event.dart';
import '../../../../core/utils/permission_checker.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، يجب تسجيل الدخول لإنشاء مسجد'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final isSuperAdmin =
        await ref.read(permissionCheckerProvider).isSuperAdmin();
    if (mounted) {
      setState(() {
        _isSuperAdmin = isSuperAdmin;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isSuperAdmin) {
        ref.read(mosqueProvider.notifier).addMosque(
              name: _nameController.text.trim(),
              location: _locationController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );
      } else {
        ref.read(mosqueRequestsProvider.notifier).createRequest(
              name: _nameController.text.trim(),
              location: _locationController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MosqueState>(mosqueProvider, (previous, next) {
      if (next is MosqueLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المسجد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (next is MosqueError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في إضافة المسجد: ${next.message}\n'
              'تأكد من أن لديك الصلاحيات المطلوبة',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    ref.listen<MosqueRequestsState>(mosqueRequestsProvider, (previous, next) {
      if (next is MosqueRequestSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (next is MosqueRequestsError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في إرسال الطلب: ${next.message}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    final state = ref.watch(mosqueProvider);
    final requestState = ref.watch(mosqueRequestsProvider);
    final isLoading =
        state is MosqueLoading || requestState is MosqueRequestsLoading;

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
