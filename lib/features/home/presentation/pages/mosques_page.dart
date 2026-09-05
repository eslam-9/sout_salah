import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../mosques/presentation/providers/mosque_controller.dart';
import '../../../mosques/presentation/widgets/mosque_card.dart';
import '../widgets/home_widgets.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';

class MosquesPage extends ConsumerStatefulWidget {
  const MosquesPage({super.key});

  @override
  ConsumerState<MosquesPage> createState() => _MosquesPageState();
}

class _MosquesPageState extends ConsumerState<MosquesPage> {
  String _searchQuery = '';
  bool _canAddMosque = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(mosqueProvider.notifier).loadMore();
    }
  }

  Future<void> _checkPermissions() async {
    final canAdd = await ref.read(permissionCheckerProvider).canAddMosque();
    if (mounted) {
      setState(() => _canAddMosque = canAdd);
    }
  }

  Future<void> _refreshMosques() async {
    await ref.read(mosqueProvider.notifier).getMosques();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosqueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            HomeAppBar(
              onSearchChanged: (query) => setState(() => _searchQuery = query),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMosques,
                color: AppColors.primary,
                child: Builder(
                  builder: (context) {
                    return state.when(
                      data: (mosquesList) {
                        final mosques = mosquesList
                            .where((m) => m.name.contains(_searchQuery))
                            .toList();

                        if (mosques.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: AppEmptyState(
                                  title: _searchQuery.isEmpty
                                      ? 'لا توجد مساجد متاحة حاليا'
                                      : 'لا نتائج لهذا البحث',
                                  icon: LucideIcons.search,
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              mosques.length +
                              (ref.read(mosqueProvider.notifier).hasMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == mosques.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: AppLoadingIndicator(),
                                ),
                              );
                            }
                            return MosqueCard(
                              mosque: mosques[index],
                              onTap: () => NavigationService.navigateTo(
                                AppRoutes.mosqueDetail,
                                arguments: mosques[index],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(
                              child: AppLoadingIndicator(),
                            ),
                          ),
                        ],
                      ),
                      error: (error, stack) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: AppErrorView(
                              title: 'فشل تحميل المساجد',
                              message: 'تأكد من اتصالك بالإنترنت',
                              onRetry: _refreshMosques,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canAddMosque
          ? FloatingActionButton.extended(
              onPressed: () =>
                  NavigationService.navigateTo(AppRoutes.addMosque),
              backgroundColor: AppColors.primary,
              icon: const Icon(LucideIcons.plus),
              label: const Text(
                'إضافة مسجد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
