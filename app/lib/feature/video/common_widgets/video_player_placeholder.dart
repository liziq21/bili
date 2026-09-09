import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../main.dart';

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
  bool _showSourcePopover = false;
  String _selectedSource = 'B站 官方原生源 (4K)';
  String _selectedQuality = '4K 60FPS';

  final List<Map<String, String>> _sources = [
    {'name': 'B站 官方原生源 (4K)', 'ping': '24ms'},
    {'name': 'YouTube 镜像 (1080P)', 'ping': '118ms'},
    {'name': 'P2P 节点分布式加速', 'ping': '45ms'},
    {'name': 'RSS 直连媒体流 (WebM)', 'ping': '62ms'},
  ];

  final List<String> _qualities = ['4K 60FPS', '1080P 高码率', '720P', '480P'];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: $styles.colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Thumbnail Image
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => Container(
                    color: $styles.colors.greyStrong,
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: $styles.colors.greyStrong,
                ),
              ),

            // Subtle Ambient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      $styles.colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      $styles.colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Top Control Bar (Back, Title Preview, Source Switcher)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: $styles.colors.white),
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
                        color: $styles.colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Gap(8),
                  // Multi-Source Switcher Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSourcePopover = !_showSourcePopover;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: $styles.insets.xs,
                        vertical: $styles.insets.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: $styles.colors.greyStrong.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular($styles.corners.lg),
                        border: Border.all(
                          color: $styles.colors.accent1.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: $styles.colors.accent1,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            _selectedSource.split(' ').first,
                            style: $styles.text.btn.copyWith(
                              color: $styles.colors.offWhite,
                              fontSize: 11,
                            ),
                          ),
                          const Gap(2),
                          Icon(
                            _showSourcePopover
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: $styles.colors.offWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Big Play / Pause Trigger
            IconButton(
              iconSize: 56,
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: $styles.colors.accent1,
              ),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),

            // Source Switcher Popover Overlay
            if (_showSourcePopover)
              Positioned(
                top: 48,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 240,
                    padding: EdgeInsets.all($styles.insets.xs),
                    decoration: BoxDecoration(
                      color: $styles.colors.black.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular($styles.corners.md),
                      border: Border.all(
                        color: $styles.colors.accent1.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '多源分流线路',
                              style: $styles.text.bodySmallBold.copyWith(
                                color: $styles.colors.accent2,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '自动优选: 极速',
                              style: $styles.text.bodySmall.copyWith(
                                color: $styles.colors.accent1,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        ..._sources.map((src) {
                          final isSelected = src['name'] == _selectedSource;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSource = src['name']!;
                                _showSourcePopover = false;
                              });
                            },
                            borderRadius: BorderRadius.circular($styles.corners.sm),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: $styles.insets.xxs,
                                vertical: $styles.insets.xxs,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 14,
                                          color: isSelected
                                              ? $styles.colors.accent1
                                              : $styles.colors.greyMedium,
                                        ),
                                        const Gap(6),
                                        Expanded(
                                          child: Text(
                                            src['name']!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: $styles.text.bodySmall.copyWith(
                                              color: isSelected
                                                  ? $styles.colors.accent1
                                                  : $styles.colors.white,
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    src['ping']!,
                                    style: $styles.text.bodySmall.copyWith(
                                      color: isSelected
                                          ? $styles.colors.accent1
                                          : $styles.colors.caption,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
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
                    colors: [Colors.transparent, $styles.colors.black.withValues(alpha: 0.9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 22,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: $styles.colors.white,
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
                        color: $styles.colors.offWhite,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          trackHeight: 3,
                          activeTrackColor: $styles.colors.accent1,
                          inactiveTrackColor: $styles.colors.white.withValues(alpha: 0.3),
                          thumbColor: $styles.colors.accent1,
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
                                      ? $styles.colors.accent1
                                      : $styles.colors.body,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: $styles.colors.accent2),
                          borderRadius: BorderRadius.circular($styles.corners.sm),
                        ),
                        child: Text(
                          _selectedQuality,
                          style: $styles.text.btn.copyWith(
                            color: $styles.colors.offWhite,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      icon: Icon(Icons.fullscreen, color: $styles.colors.white),
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
