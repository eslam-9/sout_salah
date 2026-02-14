import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/entities/ramadan_day.dart';
import '../providers/ramadan_days_provider.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import 'add_publisher_page.dart';

class MosqueDetailPage extends ConsumerStatefulWidget {
  final Mosque mosque;

  const MosqueDetailPage({super.key, required this.mosque});

  @override
  ConsumerState<MosqueDetailPage> createState() => _MosqueDetailPageState();
}

class _MosqueDetailPageState extends ConsumerState<MosqueDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fetch Ramadan days after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ramadanDaysProvider.notifier).loadDays(widget.mosque.id);
    });
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
              style: GoogleFonts.cairo(
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
      body: state is RamadanDaysLoading
          ? const Center(child: CircularProgressIndicator())
          : state is RamadanDaysError
          ? Center(child: Text(state.message))
          : state is RamadanDaysLoadedState
          ? _buildCalendarView(context, state.days)
          : const Center(child: Text('لا توجد بيانات')),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<RamadanDay> days) {
    // Calculate progress
    final completedDays = days.where((d) => d.status == 'green').length;
    final partialDays = days.where((d) => d.status == 'yellow').length;
    final totalDays = days.length;
    final progress = (completedDays + (partialDays * 0.5)) / totalDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأيام $completedDays/$totalDays',
                style: GoogleFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'تقدمي',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
              final isToday = day.dayNumber == DateTime.now().day;
              return _buildDayCircle(context, day, isToday);
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
                      day.dayNumber.toString(),
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'اليوم',
                      style: GoogleFonts.cairo(
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
                      day.dayNumber.toString(),
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontWeight: FontWeight.bold,
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
                  day.dayNumber.toString(),
                  style: GoogleFonts.cairo(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
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
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
