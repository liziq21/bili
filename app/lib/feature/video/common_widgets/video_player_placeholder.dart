import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoPlayerPlaceholder extends StatefulWidget {
  const VideoPlayerPlaceholder({
    super.key,
    this.thumbnailUrl,
    this.title,
    this.aspectRatio = 16 / 9,
  });

  final String? thumbnailUrl;
  final String? title;
  final double aspectRatio;

  @override
  State<VideoPlayerPlaceholder> createState() => _VideoPlayerPlaceholderState();
}

class _VideoPlayerPlaceholderState extends State<VideoPlayerPlaceholder> {
  bool _isPlaying = false;
  double _progress = 0.25;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            // Play / Pause Button
            IconButton(
              iconSize: 56,
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),
            // Bottom Controls Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 20,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                    ),
                    const Text(
                      '03:12 / 12:00',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Theme.of(context).primaryColor,
                        ),
                        child: Slider(
                          value: _progress,
                          onChanged: (val) {
                            setState(() {
                              _progress = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1080P',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('全屏模式'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
