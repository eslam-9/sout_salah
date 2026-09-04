import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/recording.dart';
import '../widgets/audio_player_components/audio_player_info.dart';
import '../widgets/audio_player_components/audio_download_button.dart';
import '../widgets/audio_player_components/audio_favorite_button.dart';
import '../widgets/audio_player_components/audio_player_slider.dart';
import '../widgets/audio_player_components/audio_player_controls.dart';

class AudioPlayerPage extends ConsumerWidget {
  final Recording recording;

  const AudioPlayerPage({super.key, required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تشغيل التلاوة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              AudioPlayerInfo(recording: recording),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AudioDownloadButton(recording: recording),
                  const SizedBox(width: 32),
                  AudioFavoriteButton(recording: recording),
                ],
              ),
              const SizedBox(height: 48),
              
              const AudioPlayerSlider(),
              const SizedBox(height: 24),
              
              const AudioPlayerControls(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
