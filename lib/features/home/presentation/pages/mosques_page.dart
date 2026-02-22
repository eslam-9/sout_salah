import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/permission_checker.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../mosques/presentation/providers/mosque_controller.dart';
import '../../../mosques/presentation/bloc/mosque_state_event.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canAdd = await ref.read(permissionCheckerProvider).canAddMosque();
    if (mounted) {
      setState(() {
        _canAddMosque = canAdd;
      });
    }
  }

  Future<void> _refreshMosques() async {
    await ref.read(mosqueProvider.notifier).getMosques();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosqueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light Grey Background
      body: SafeArea(
        child: Column(
          children: [
            HomeAppBar(
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMosques,
                color: AppColors.primary,
                child: Builder(
                  builder: (context) {
                    if (state is MosqueLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is MosqueError) {
                      return ListView(
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
                                  Text(
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
                                    label: Text(
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
                      );
                    } else if (state is MosqueLoaded) {
                      final mosques = state.mosques.where((mosque) {
                        return mosque.name.contains(_searchQuery);
                      }).toList();

                      if (mosques.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'لا توجد مساجد متاحة حاليا'
                                      : 'لا نتائج لهذا البحث',
                                  style: TextStyle(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: mosques.length,
                        itemBuilder: (context, index) {
                          return MosqueCard(
                            mosque: mosques[index],
                            onTap: () {
                              NavigationService.navigateTo(
                                AppRoutes.mosqueDetail,
                                arguments: mosques[index],
                              );
                            },
                          );
                        },
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox()],
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
              onPressed: () {
                NavigationService.navigateTo(AppRoutes.addMosque);
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(LucideIcons.plus),
              label: Text(
                'إضافة مسجد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
