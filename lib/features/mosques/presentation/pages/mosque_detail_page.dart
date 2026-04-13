import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mosque.dart';
import '../providers/ramadan_days_provider.dart';
import '../widgets/mosque_detail_components/mosque_detail_app_bar.dart';
import '../widgets/mosque_detail_components/mosque_detail_body.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ramadanDaysProvider.notifier).loadDays(widget.mosque.id);
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
      appBar: MosqueDetailAppBar(mosque: widget.mosque),
      body: MosqueDetailBody(state: state),
    );
  }
}
