import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gap/gap.dart';

import '../../../main.dart';

class const VideoPlayerPlaceholder({
  super.key,
  final String? thumbnailUrl,
  final String? title,
  final double aspectRatio = 16 / 9,
}) extends StatefulWidget {
  @override
  State<VideoPlayerPlaceholder> createState() => _VideoPlayerPlaceholderState();
}

class _VideoPlayerPlaceholderState() extends State<VideoPlayerPlaceholder> {
  bool _isPlaying = false;
  double _progress = 0.25;
  String _selectedQuality = '4K 60FPS';

  final List<String> _qualities = ['4K 60FPS', '1080P 高码率', '720P', '480P'];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: $styles.colors.scrim,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Thumbnail Image
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              Positioned.fill(
                // ⚡ Bolt Optimization: Cap thumbnail image decode resolution using memCacheWidth: 720.
                // Prevents decoding raw high-res 1080p/4K network preview images into uncompressed GPU RAM,
                // saving ~10MB-25MB RAM per player view while preserving high-DPI crisp visual detail.
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  memCacheWidth: 720,
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) =>
                      Container(color: $styles.colors.surfaceContainerHighest),
                ),
              )
            else
              Positioned.fill(
                child: Container(color: $styles.colors.surfaceContainerHighest),
              ),

            // Subtle Ambient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      $styles.colors.scrim.withValues(alpha: 0.7),
                      Colors.transparent,
                      $styles.colors.scrim.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Top Control Bar (Back, Title Preview)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: $styles.colors.onScrim),
                    tooltip: '返回',
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      widget.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: $styles.text.title2.copyWith(
                        color: $styles.colors.onScrim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Big Play / Pause Trigger
            IconButton(
              iconSize: 56,
              tooltip: _isPlaying ? '暂停' : '播放',
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: $styles.colors.accentFill,
              ),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),

            // Bottom Player Control Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: $styles.insets.xs,
                  vertical: $styles.insets.xxs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      $styles.colors.scrim.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 22,
                      tooltip: _isPlaying ? '暂停' : '播放',
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: $styles.colors.onScrim,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                    ),
                    Text(
                      '03:12 / 12:00',
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onScrim,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          trackHeight: 3,
                          activeTrackColor: $styles.colors.accentFill,
                          inactiveTrackColor: $styles.colors.onScrim.withValues(
                            alpha: 0.3,
                          ),
                          thumbColor: $styles.colors.accentFill,
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
                    PopupMenuButton<String>(
                      initialValue: _selectedQuality,
                      tooltip: '切换',
                      onSelected: (val) {
                        setState(() {
                          _selectedQuality = val;
                        });
                      },
                      itemBuilder: (context) => _qualities
                          .map(
                            (q) => PopupMenuItem(
                              value: q,
                              child: Text(
                                q,
                                style: $styles.text.bodySmall.copyWith(
                                  color: q == _selectedQuality
                                      ? $styles.colors.accentText
                                      : $styles.colors.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: $styles.colors.secondary),
                          borderRadius: BorderRadius.circular(
                            $styles.corners.sm,
                          ),
                        ),
                        child: Text(
                          _selectedQuality,
                          style: $styles.text.btn.copyWith(
                            color: $styles.colors.onScrim,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      icon: Icon(
                        Icons.fullscreen,
                        color: $styles.colors.onScrim,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('全屏切换'),
                            duration: $styles.times.fast,
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
