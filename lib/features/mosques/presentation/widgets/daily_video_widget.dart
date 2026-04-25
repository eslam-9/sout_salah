import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/app_logger.dart';

import '../../data/models/daily_video_model.dart';
import '../../../../core/theme/app_theme.dart';

class DailyVideoWidget extends StatefulWidget {
  final DailyVideoModel video;

  const DailyVideoWidget({super.key, required this.video});

  @override
  State<DailyVideoWidget> createState() => _DailyVideoWidgetState();
}

class _DailyVideoWidgetState extends State<DailyVideoWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  final AppLogger _logger = GetIt.I<AppLogger>();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: 'سرعة التشغيل',
          subtitlesButtonText: 'الترجمة',
          cancelButtonText: 'إلغاء',
        ),
        optionsBuilder: (context, defaultOptions) async {
          await showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'إعدادات الفيديو',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...defaultOptions.map((option) {
                      return ListTile(
                        leading: Icon(
                          option.iconData,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          option.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: option.subtitle != null
                            ? Text(option.subtitle!)
                            : null,
                        trailing: const Icon(
                          LucideIcons.chevronLeft,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          option.onTap(context);
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
        deviceOrientationsAfterFullScreen: const [
          // Return to portrait after full screen
          DeviceOrientation.portraitUp,
        ],
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      );

      setState(() {});
      _logger.i('DailyVideoWidget: Video player initialized successfully');
    } catch (e) {
      _logger.e('DailyVideoWidget: Error initializing video player', e);
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'حدث خطأ أثناء تحميل الفيديو',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aspect Ratio Container for the Video Player
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: _videoPlayerController.value.isInitialized
                  ? _videoPlayerController.value.aspectRatio
                  : 16 / 9,
              child:
                  _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: _chewieController!)
                  : Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),

          // Title and Description Area
          if ((widget.video.title != null && widget.video.title!.isNotEmpty) ||
              (widget.video.description != null &&
                  widget.video.description!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.video.title != null &&
                      widget.video.title!.isNotEmpty) ...[
                    Text(
                      widget.video.title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.video.description != null &&
                      widget.video.description!.isNotEmpty)
                    Text(
                      widget.video.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
