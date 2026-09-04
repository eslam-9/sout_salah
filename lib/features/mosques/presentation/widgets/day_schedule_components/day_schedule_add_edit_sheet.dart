import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/day_schedule_entry.dart';
import '../../providers/day_schedule_provider.dart';

class DayScheduleAddEditSheet extends ConsumerStatefulWidget {
  final String dayId;
  final String mosqueId;
  final DayScheduleEntry? entry;

  const DayScheduleAddEditSheet({
    super.key,
    required this.dayId,
    required this.mosqueId,
    this.entry,
  });

  @override
  ConsumerState<DayScheduleAddEditSheet> createState() =>
      _DayScheduleAddEditSheetState();
}

class _DayScheduleAddEditSheetState extends ConsumerState<DayScheduleAddEditSheet> {
  late TextEditingController _salahController;
  late TextEditingController _shikhController;
  late TextEditingController _commentsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _salahController = TextEditingController(text: widget.entry?.salah ?? '');
    _shikhController = TextEditingController(text: widget.entry?.shikh ?? '');
    _commentsController = TextEditingController(
      text: widget.entry?.comments ?? '',
    );
  }

  @override
  void dispose() {
    _salahController.dispose();
    _shikhController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final salah = _salahController.text.trim();
    final shikh = _shikhController.text.trim();

    if (salah.isEmpty || shikh.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الصلاة واسم الشيخ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(
      dayScheduleNotifierProvider((
        dayId: widget.dayId,
        mosqueId: widget.mosqueId,
      )).notifier,
    );

    bool success;
    if (widget.entry == null) {
      success = await notifier.addEntry(
        salah: salah,
        shikh: _shikhController.text.trim(),
        comments: _commentsController.text.trim(),
      );
    } else {
      success = await notifier.updateEntry(
        entryId: widget.entry!.id,
        salah: salah,
        shikh: _shikhController.text.trim(),
        comments: _commentsController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(dayScheduleProvider(widget.dayId));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.entry == null ? 'إضافة صف جديد' : 'تعديل الصف',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _salahController,
            decoration: const InputDecoration(
              labelText: 'الصلاة (مثال: الفجر، التراويح)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shikhController,
            decoration: const InputDecoration(
              labelText: 'اسم الشيخ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentsController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('حفظ', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
