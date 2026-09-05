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
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? 'لا توجد مساجد متاحة حاليا'
                                        : 'لا نتائج لهذا البحث',
                                  ),
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
                                  child: CircularProgressIndicator(),
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
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      ),
                      error: (error, stack) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.wifiOff,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'فشل تحميل المساجد',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'تأكد من اتصالك بالإنترنت',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _refreshMosques,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(LucideIcons.refreshCw),
                                    label: const Text(
                                      'إعادة المحاولة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
