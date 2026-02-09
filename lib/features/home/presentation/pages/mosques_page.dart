import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mosques/presentation/providers/mosque_controller.dart';
import '../../../mosques/presentation/bloc/mosque_state_event.dart';
import '../../../mosques/presentation/widgets/mosque_card.dart';
import '../widgets/home_widgets.dart';

class MosquesPage extends ConsumerWidget {
  const MosquesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mosqueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light Grey Background
      body: SafeArea(
        child: Column(
          children: [
            const HomeAppBar(),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state is MosqueLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MosqueError) {
                    return Center(child: Text(state.message));
                  } else if (state is MosqueLoaded) {
                    if (state.mosques.isEmpty) {
                      return const Center(
                        child: Text('لا توجد مساجد متاحة حاليا'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.mosques.length,
                      itemBuilder: (context, index) {
                        return MosqueCard(
                          mosque: state.mosques[index],
                          onTap: () {},
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
    );
  }
}
