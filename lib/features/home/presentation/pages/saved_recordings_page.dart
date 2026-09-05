import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';

import '../widgets/saved_recordings_components/saved_recordings_empty_state.dart';
import '../widgets/saved_recordings_components/saved_recording_card.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';

class SavedRecordingsPage extends ConsumerWidget {
  const SavedRecordingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(allFavoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'المحفوظات',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return const SavedRecordingsEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return SavedRecordingCard(favorite: favorites[index]);
            },
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) => AppErrorView(
          title: 'حدث خطأ',
          message: 'حدث خطأ في تحميل المحفوظات',
          onRetry: () => ref.invalidate(allFavoritesProvider),
        ),
      ),
    );
  }
}
