import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/daily_video_model.dart';
import '../widgets/daily_video_widget.dart';

class DailyVideoPage extends StatelessWidget {
  final DailyVideoModel video;

  const DailyVideoPage({super.key, required this.video});

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
        title: const Text(
          'فيديو اليوم',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DailyVideoWidget(video: video),
              const SizedBox(height: 24),
              // We can add more info here if needed later, 
              // like the mosque name or date.
            ],
          ),
        ),
      ),
    );
  }
}
