import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base_audio_sheet_components/audio_sheet_header.dart';
import 'base_audio_sheet_components/audio_sheet_slider.dart';
import 'base_audio_sheet_components/audio_sheet_controls.dart';

/// A reusable bottom sheet for audio playback.
/// Handles the UI for title, subtitle, sliders, and playback controls.
/// Supports optional leading and trailing actions (e.g., download, favorite) and extra info.
class BaseAudioSheet extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final Widget? extraInfo;

  const BaseAudioSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAction,
    this.trailingAction,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Header Row (Title, Subtitle, Actions)
          AudioSheetHeader(
            title: title,
            subtitle: subtitle,
            leadingAction: leadingAction,
            trailingAction: trailingAction,
            extraInfo: extraInfo,
          ),
          const SizedBox(height: 32),

          // Slider and times layout
          const AudioSheetSlider(),
          const SizedBox(height: 32),

          // Controls
          const AudioSheetControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
