import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/mosque.dart';
import '../providers/ramadan_days_provider.dart';
import '../providers/month_year.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../widgets/mosque_detail_components/mosque_detail_app_bar.dart';
import '../widgets/mosque_detail_components/mosque_detail_body.dart';
import '../widgets/mosque_detail_components/mosque_detail_month_navigator.dart';
import '../widgets/mosque_detail_components/mosque_detail_add_month_dialog.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final months = await ref.read(
      availableMonthsProvider(widget.mosque.id).future,
    );

    if (months.isNotEmpty) {
      setState(() {
        selectedMonth = months.last;
      });
      ref.read(ramadanDaysProvider.notifier).loadDays(
            widget.mosque.id,
            month: selectedMonth!.month,
            year: selectedMonth!.year,
          );
    } else {
      ref.read(ramadanDaysProvider.notifier).loadDays(widget.mosque.id);
    }
  }

  void _showAddMonthDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MosqueDetailAddMonthDialog(
        mosqueId: widget.mosque.id,
        onMonthAdded: (newMonth) {
          setState(() {
            selectedMonth = newMonth;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ramadanDaysProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: MosqueDetailAppBar(mosque: widget.mosque),
      floatingActionButton: (authState is AuthAuthenticated &&
              (authState.user.role == 'admin' ||
               authState.user.role == 'super_admin' ||
               authState.user.id == widget.mosque.adminId))
          ? FloatingActionButton(
              onPressed: () => _showAddMonthDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          MosqueDetailMonthNavigator(
            mosqueId: widget.mosque.id,
            selectedMonth: selectedMonth,
            onMonthSelected: (month) {
              setState(() {
                selectedMonth = month;
              });
            },
          ),
          Expanded(
            child: MosqueDetailBody(state: state),
          ),
        ],
      ),
    );
  }
}
