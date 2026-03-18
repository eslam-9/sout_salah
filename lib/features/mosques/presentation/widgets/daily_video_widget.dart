import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/app_logger.dart';

import '../../data/models/daily_video_model.dart';

class DailyVideoWidget extends StatefulWidget {
  final DailyVideoModel video;

  const DailyVideoWidget({super.key, required this.video});

  @override
  State<DailyVideoWidget> createState() => _DailyVideoWidgetState();
}

class _DailyVideoWidgetState extends State<DailyVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInit = false;
  bool _hasError = false;
  bool _isFullscreen = false;
  final AppLogger _logger = GetIt.I<AppLogger>();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );
      await _controller.initialize();
      setState(() {
        _isInit = true;
      });
      _logger.i('DailyVideoWidget: Video initialized successfully');
    } catch (e) {
      _logger.e('DailyVideoWidget: Error initializing video', e);
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _skipForward() {
    final newPosition =
        _controller.value.position + const Duration(seconds: 10);
    final duration = _controller.value.duration;
    _controller.seekTo(newPosition > duration ? duration : newPosition);
  }

  void _skipBackward() {
    final newPosition =
        _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'حدث خطأ أثناء تحميل الفيديو',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (!_isInit) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _isFullscreen
                ? MediaQuery.of(context).size.aspectRatio
                : _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip Backward Button
            IconButton(
              onPressed: _skipBackward,
              icon: const Icon(LucideIcons.rewind, size: 24),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'التراجع 10 ثواني',
            ),
            const SizedBox(width: 8),
            Text(
              '-10',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 24),
            // Play/Pause Button
            IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(
                _controller.value.isPlaying
                    ? LucideIcons.pause
                    : LucideIcons.play,
                size: 32,
              ),
              color: Theme.of(context).colorScheme.primary,
              tooltip: _controller.value.isPlaying ? 'إيقاف' : 'تشغيل',
            ),
            const SizedBox(width: 24),
            // Skip Forward Button
            Text(
              '+10',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _skipForward,
              icon: const Icon(LucideIcons.fastForward, size: 24),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'التقدم 10 ثواني',
            ),
            const SizedBox(width: 24),
            // Fullscreen Button
            IconButton(
              onPressed: _toggleFullscreen,
              icon: Icon(
                _isFullscreen ? LucideIcons.maximize2 : LucideIcons.maximize,
                size: 24,
              ),
              color: Theme.of(context).colorScheme.primary,
              tooltip: _isFullscreen ? 'إغلاق الشاشة الكاملة' : 'شاشة كاملة',
            ),
          ],
        ),
        if (widget.video.description != null &&
            widget.video.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.video.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}
