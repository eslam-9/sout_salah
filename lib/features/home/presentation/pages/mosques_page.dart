import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../mosques/presentation/providers/mosque_controller.dart';
import '../../../mosques/presentation/bloc/mosque_state_event.dart';
import '../../../mosques/presentation/widgets/mosque_card.dart';
import '../../../mosques/presentation/pages/add_mosque_page.dart';
import '../../../mosques/presentation/pages/mosque_detail_page.dart';
import '../widgets/home_widgets.dart';

class MosquesPage extends ConsumerStatefulWidget {
  const MosquesPage({super.key});

  @override
  ConsumerState<MosquesPage> createState() => _MosquesPageState();
}

class _MosquesPageState extends ConsumerState<MosquesPage> {
  String _searchQuery = '';

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
              child: Builder(
                builder: (context) {
                  if (state is MosqueLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MosqueError) {
                    return Center(child: Text(state.message));
                  } else if (state is MosqueLoaded) {
                    final mosques = state.mosques.where((mosque) {
                      return mosque.name.contains(_searchQuery);
                    }).toList();

                    if (mosques.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'لا توجد مساجد متاحة حاليا'
                              : 'لا نتائج لهذا البحث',
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mosques.length,
                      itemBuilder: (context, index) {
                        return MosqueCard(
                          mosque: mosques[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MosqueDetailPage(mosque: mosques[index]),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMosquePage()),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(LucideIcons.plus),
        label: Text(
          'إضافة مسجد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
