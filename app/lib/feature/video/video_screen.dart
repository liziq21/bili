import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sized_context/sized_context.dart';

import '../../main.dart';
import '../../ui/common/centered_box.dart';
import '../../utils/platfrom_info.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Main view content switches between 1 and 2 column layouts
    // On mobile, use the 2 column layout on screens close to landscape (>.85). This is primarily an optimization for foldable devices which have square-ish dimensions when opened.
    final twoColumnAspect = PlatformInfo.isMobile ? .85 : 1;
    final bool useTwoColumnLayout =
        MediaQuery.of(context).size.aspectRatio > twoColumnAspect;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (_, _) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  videoPlayer(),
                  if (useTwoColumnLayout)
                    _buildTwoColumn(context)
                  else
                    _buildSingleColumn(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget videoPlayer() => const Text('videoPlayer');

  Widget _buildTwoColumn(BuildContext context) {
    final bool smallMode = context.heightPx < 550;
    final double timelineImageSize = (context.heightPx - 200).clamp(200, 500);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: smallMode ? $styles.insets.sm : $styles.insets.lg,
        horizontal: $styles.insets.sm,
      ),
      child: Row(
        children: [
          /// WonderImage w/ Timeline btn
          Expanded(
            child: CenteredBox(
              width: $styles.sizes.maxContentWidth3,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: smallMode ? $styles.insets.sm : $styles.insets.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      _WonderImageWithTimeline(
                      height: timelineImageSize,
                    ),
                    Gap(smallMode ? $styles.insets.md : $styles.insets.lg),
                    SizedBox(
                      width: 400,
                      child: const _TimelineBtn(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// EventsList
          Expanded(
            child: CenteredBox(
              width: $styles.sizes.maxContentWidth2,
              child: _EventsList(
                topHeight: 100,
                blurOnScroll: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Portrait layout is a stack with the EventsList scrolling overtop of the WonderImage
  Widget _buildSingleColumn() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final double topHeight = max(constraints.maxHeight * .55, 200);
        return CenteredBox(
          width: $styles.sizes.maxContentWidth2,
          child: Stack(
            children: [
              /// Top content, sits underneath scrolling list
              _WonderImageWithTimeline(height: topHeight),

              /// EventsList + TimelineBtn
              Column(
                children: [
                  Expanded(
                    /// EventsList
                    child: _EventsList(
                      topHeight: topHeight,
                      blurOnScroll: true,
                    ),
                  ),
                  Gap($styles.insets.lg),

                  /// TimelineBtn
                  _TimelineBtn(
                    width: $styles.sizes.maxContentWidth2,
                  ),
                  Gap($styles.insets.lg),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WonderImageWithTimeline extends StatelessWidget {
  const _WonderImageWithTimeline({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height, child: const Text('WonderImage placeholder'));
}

class _TimelineBtn extends StatelessWidget {
  const _TimelineBtn({this.width});
  final double? width;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: const Text('TimelineBtn placeholder'));
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.topHeight, this.blurOnScroll = false});
  final double topHeight;
  final bool blurOnScroll;
  @override
  Widget build(BuildContext context) => const Text('EventsList placeholder');
}

