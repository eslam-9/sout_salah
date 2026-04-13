import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/usecases/create_pending_recording_params.dart';
import '../../providers/mosque_data_providers.dart';

class AddPrayerDialog extends ConsumerStatefulWidget {
  final String mosqueId;
  final String dayId;

  const AddPrayerDialog({
    super.key,
    required this.mosqueId,
    required this.dayId,
  });

  @override
  ConsumerState<AddPrayerDialog> createState() => _AddPrayerDialogState();
}

class _AddPrayerDialogState extends ConsumerState<AddPrayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _prayerNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _prayerNameController.dispose();
    super.dispose();
  }

  Future<void> _addPrayer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final params = CreatePendingRecordingParams(
        mosqueId: widget.mosqueId,
        dayId: widget.dayId,
        prayerName: _prayerNameController.text.trim(),
      );
      final result = await ref
          .read(createPendingRecordingUseCaseProvider)
          .call(params);

      if (mounted) {
        result.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إضافة التلاوة: $failure'),
              backgroundColor: Colors.red,
            ),
          ),
          (_) {
            Navigator.pop(context, _prayerNameController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إضافة التلاوة بنجاح'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ غير متوقع'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إضافة تلاوة جديدة',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _prayerNameController,
              textAlign: TextAlign.right,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم التلاوة (مثل: تهجد)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'الرجاء إدخال اسم التلاوة'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPrayer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
