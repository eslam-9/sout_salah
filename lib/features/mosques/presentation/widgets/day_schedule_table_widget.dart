import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../domain/entities/day_schedule_entry.dart';
import '../providers/day_schedule_provider.dart';

class DayScheduleTableWidget extends ConsumerWidget {
  final String dayId;
  final String mosqueId;

  const DayScheduleTableWidget({
    super.key,
    required this.dayId,
    required this.mosqueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(dayScheduleProvider(dayId));
    final canManageAsync = ref.watch(
      permissionCheckerProvider.select(
        (checker) => checker.canShowUploadButton(mosqueId),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'جدول الشيوخ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              FutureBuilder<bool>(
                future: canManageAsync,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return IconButton(
                      icon: const Icon(
                        LucideIcons.plusCircle,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _showAddOrEditSheet(context, ref, null),
                      tooltip: 'إضافة صف جديد',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          scheduleAsync.when(
            data: (schedule) {
              if (schedule.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'لا يوجد جدول مضاف حتى الآن',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return FutureBuilder<bool>(
                future: canManageAsync,
                builder: (context, snapshot) {
                  final canManage = snapshot.data ?? false;
                  return _buildTable(context, ref, schedule, canManage);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('خطأ: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    List<DayScheduleEntry> schedule,
    bool canManage,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: const [
          DataColumn(
            label: Text(
              'الصلاة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('الشيخ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'ملاحظات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(label: Text('')), // Actions column
        ],
        rows: schedule.map((entry) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  entry.salah,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              DataCell(Text(entry.shikh)),
              DataCell(Text(entry.comments ?? '-')),
              DataCell(
                canManage
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              LucideIcons.edit2,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                _showAddOrEditSheet(context, ref, entry),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, ref, entry),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAddOrEditSheet(
    BuildContext context,
    WidgetRef ref,
    DayScheduleEntry? entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AddOrEditScheduleRowSheet(
            dayId: dayId,
            mosqueId: mosqueId,
            entry: entry,
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DayScheduleEntry entry,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصف', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من حذف هذا الصف من الجدول؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(
                dayScheduleNotifierProvider((
                  dayId: dayId,
                  mosqueId: mosqueId,
                )).notifier,
              );
              final success = await notifier.deleteEntry(entry.id);
              if (success) {
                ref.invalidate(dayScheduleProvider(dayId));
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddOrEditScheduleRowSheet extends ConsumerStatefulWidget {
  final String dayId;
  final String mosqueId;
  final DayScheduleEntry? entry;

  const _AddOrEditScheduleRowSheet({
    required this.dayId,
    required this.mosqueId,
    this.entry,
  });

  @override
  ConsumerState<_AddOrEditScheduleRowSheet> createState() =>
      _AddOrEditScheduleRowSheetState();
}

class _AddOrEditScheduleRowSheetState
    extends ConsumerState<_AddOrEditScheduleRowSheet> {
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
