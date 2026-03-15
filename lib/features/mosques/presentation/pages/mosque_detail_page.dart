import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/entities/ramadan_day.dart';
import '../providers/ramadan_days_provider.dart';
import '../providers/month_year.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import 'add_publisher_page.dart';
import 'dart:ui';

class MosqueDetailPage extends ConsumerStatefulWidget {
  final Mosque mosque;

  const MosqueDetailPage({super.key, required this.mosque});

  @override
  ConsumerState<MosqueDetailPage> createState() => _MosqueDetailPageState();
}

class _MosqueDetailPageState extends ConsumerState<MosqueDetailPage> {
  MonthYear? selectedMonth;

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // 1. Fetch available months
    final months = await ref.read(
      availableMonthsProvider(widget.mosque.id).future,
    );

    if (months.isNotEmpty) {
      // Pick the last month as default (most recent)
      setState(() {
        selectedMonth = months.last;
      });
      // 2. Load days for that month
      ref
          .read(ramadanDaysProvider.notifier)
          .loadDays(
            widget.mosque.id,
            month: selectedMonth!.month,
            year: selectedMonth!.year,
          );
    } else {
      // Fallback if no months exist (default to Ramadan 1445 for backward compatibility)
      ref.read(ramadanDaysProvider.notifier).loadDays(widget.mosque.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ramadanDaysProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.calendar,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.mosque.name,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Show add publisher button only for admins
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              if (authState is AuthAuthenticated &&
                  authState.user.role == 'admin') {
                return IconButton(
                  icon: const Icon(LucideIcons.userPlus, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddPublisherPage(mosqueId: widget.mosque.id),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          if (authState is AuthAuthenticated &&
              authState.user.role == 'admin') {
            return FloatingActionButton(
              onPressed: () => _showAddMonthDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: Column(
        children: [
          _buildMonthNavigator(),
          Expanded(
            child: state is RamadanDaysLoading
                ? const Center(child: CircularProgressIndicator())
                : state is RamadanDaysError
                ? Center(child: Text(state.message))
                : state is RamadanDaysLoadedState
                ? _buildCalendarView(context, state.days)
                : const Center(child: Text('لا توجد بيانات')),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final monthsAsync = ref.watch(availableMonthsProvider(widget.mosque.id));

    return monthsAsync.when(
      data: (months) {
        if (months.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final m = months[index];
              final isSelected = selectedMonth == m;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    '${m.arabicMonthName} ${_toArabicNumerals(m.year)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedMonth = m;
                      });
                      ref
                          .read(ramadanDaysProvider.notifier)
                          .loadDays(
                            widget.mosque.id,
                            month: m.month,
                            year: m.year,
                          );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: LinearProgressIndicator(minHeight: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddMonthDialog(BuildContext context) {
    int selectedMonthIdx = 9; // Default to Ramadan
    int selectedYear = 1446; // Default to next year approx

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إضافة شهر جديد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text('اختر الشهر الهجري:'),
                  DropdownButton<int>(
                    value: selectedMonthIdx,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      final monthNum = index + 1;
                      return DropdownMenuItem(
                        value: monthNum,
                        child: Text(
                          MonthYear(month: monthNum, year: 0).arabicMonthName,
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedMonthIdx = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('السنة الهجرية:'),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'مثلاً 1446'),
                    onChanged: (val) {
                      final year = int.tryParse(val);
                      if (year != null) selectedYear = year;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await ref
                          .read(ramadanDaysProvider.notifier)
                          .addMonth(
                            widget.mosque.id,
                            selectedMonthIdx,
                            selectedYear,
                          );

                      if (success) {
                        Navigator.pop(context);
                        // Refresh available months and load the new one
                        ref.invalidate(
                          availableMonthsProvider(widget.mosque.id),
                        );
                        setState(() {
                          selectedMonth = MonthYear(
                            month: selectedMonthIdx,
                            year: selectedYear,
                          );
                        });
                        ref
                            .read(ramadanDaysProvider.notifier)
                            .loadDays(
                              widget.mosque.id,
                              month: selectedMonthIdx,
                              year: selectedYear,
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إضافة الشهر بنجاح')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'فشل إضافة الشهر. ربما هو موجود بالفعل؟',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إضافة',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarView(BuildContext context, List<RamadanDay> days) {
    // Calculate progress
    final completedDays = days.where((d) => d.status == 'green').length;
    final partialDays = days.where((d) => d.status == 'yellow').length;
    final totalDays = days.isEmpty ? 1 : days.length;
    final progress = (completedDays + (partialDays * 0.5)) / totalDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأيام $completedDays/$totalDays',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'تقدمي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _buildDayCircle(
                context,
                day,
                false,
              ); // Today logic simplified for now as it depends on Hijri date
            },
          ),

          const SizedBox(height: 32),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('فارغ', Colors.grey.shade300),
              const SizedBox(width: 16),
              _buildLegendItem('جزئي', AppColors.accentYellow),
              const SizedBox(width: 16),
              _buildLegendItem('مكتمل', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(BuildContext context, RamadanDay day, bool isToday) {
    Color backgroundColor;
    Color textColor;
    bool showCheck = false;

    switch (day.status) {
      case 'green':
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        showCheck = true;
        break;
      case 'yellow':
        backgroundColor = AppColors.accentYellow;
        textColor = AppColors.accentYellowDark;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: () {
        NavigationService.navigateTo(AppRoutes.dayDetail, arguments: day);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: Center(
          child: isToday
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _toArabicNumerals(day.dayNumber),
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'اليوم',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : showCheck
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _toArabicNumerals(day.dayNumber),
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                )
              : Text(
                  _toArabicNumerals(day.dayNumber),
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabic[i]);
    }
    return result;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
