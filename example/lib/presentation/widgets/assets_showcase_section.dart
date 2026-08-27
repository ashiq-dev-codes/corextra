import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

// Exercises a PNG, a JPG, an SVG, a custom font, and a video asset together — so the App Size tab has a realistic mix of asset types to scan, not just plain text/icons.
class AssetsShowcaseSection extends StatefulWidget {
  const AssetsShowcaseSection({super.key});

  @override
  State<AssetsShowcaseSection> createState() => _AssetsShowcaseSectionState();
}

class _AssetsShowcaseSectionState extends State<AssetsShowcaseSection> {
  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/sample_clip.mp4')
          ..initialize().then((_) {
            if (mounted) setState(() => _videoReady = true);
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _AssetThumb(child: Image.asset('assets/images/sample_icon_small.png')),
            const SizedBox(width: 10),
            _AssetThumb(child: Image.asset('assets/images/sample_photo.jpg')),
            const SizedBox(width: 10),
            _AssetThumb(child: SvgPicture.asset('assets/svgs/sample_badge.svg')),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'ABC 123',
          style: const TextStyle(
            fontFamily: 'CorextraDemoBlock',
            fontSize: 32,
          ).copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Custom font: CorextraDemoBlock',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _videoReady ? _videoController.value.aspectRatio : 4 / 3,
            child: _videoReady
                ? GestureDetector(
                    onTap: () => setState(() {
                      _videoController.value.isPlaying
                          ? _videoController.pause()
                          : _videoController.play();
                    }),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController),
                        if (!_videoController.value.isPlaying)
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 48,
                            color: Colors.white70,
                          ),
                      ],
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AssetThumb extends StatelessWidget {
  const _AssetThumb({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 56, height: 56, child: child),
    );
  }
}
