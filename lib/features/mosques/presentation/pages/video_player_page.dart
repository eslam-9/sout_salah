import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/daily_video_widget.dart';
import '../../domain/entities/daily_video.dart';

class VideoPlayerPage extends StatelessWidget {

  const VideoPlayerPage({super.key, required this.video});
  final DailyVideo video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          video.title?.isNotEmpty == true ? video.title! : 'تشغيل الفيديو',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DailyVideoWidget(video: video),
        ),
      ),
    );
  }
}
