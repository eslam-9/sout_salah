import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../providers/mosque_requests_provider.dart';
import '../../domain/entities/mosque_request.dart';

class MosqueRequestsPage extends ConsumerStatefulWidget {
  const MosqueRequestsPage({super.key});

  @override
  ConsumerState<MosqueRequestsPage> createState() => _MosqueRequestsPageState();
}

class _MosqueRequestsPageState extends ConsumerState<MosqueRequestsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mosqueRequestsProvider.notifier).fetchPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosqueRequestsProvider);

    ref.listen(mosqueRequestsProvider, (previous, next) {
      if (next is AsyncError) {
        AppSnackBar.showError(context, 'حدث خطأ: ${next.error}');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'طلبات المساجد',
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
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AsyncValue<List<MosqueRequest>> state) {
    return state.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد طلبات معلقة',
            icon: LucideIcons.inbox,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(mosqueRequestsProvider.notifier).fetchPendingRequests(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'قيد المراجعة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.location,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (request.description != null &&
                          request.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          request.description!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(mosqueRequestsProvider.notifier)
                                      .declineRequest(request.id);
                                  if (context.mounted) {
                                    AppSnackBar.showSuccess(context, 'تم رفض الطلب.');
                                  }
                                } catch (e) {
                                  // Handled by ref.listen AsyncError
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(mosqueRequestsProvider.notifier)
                                      .acceptRequest(request.id);
                                  if (context.mounted) {
                                    AppSnackBar.showSuccess(context, 'تم قبول الطلب وإنشاء المسجد بنجاح.');
                                  }
                                } catch (e) {
                                  // Handled by ref.listen AsyncError
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('قبول'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (error, stack) => AppErrorView(
        title: 'حدث خطأ',
        message: 'حدث خطأ في تحميل الطلبات',
        onRetry: () => ref.read(mosqueRequestsProvider.notifier).fetchPendingRequests(),
      ),
    );
  }
}
