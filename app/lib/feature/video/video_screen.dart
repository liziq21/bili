import 'dart:math';

//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sized_context/sized_context.dart';

import '../../main.dart';
import '../../ui/common/centered_box.dart';
import '../../utils/platfrom_info.dart';

class VideoParameters {
  const VideoParameters({
    required this.id,
    this.cid,
    this.commentRootId,
    this.commentSecondaryId,
    this.dmProgress,
  });
  final String id;
  final String? cid;
  final String? commentRootId;
  final String? commentSecondaryId;
  final String? dmProgress;
}

class const VideoScreen({
  super.key,
  final VoidCallback? onBackClick,
  final EdgeInsets contentPadding = .zero,
}) extends StatelessWidget {
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
              padding: contentPadding,
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

  Widget videoPlayer() {
    return Text('videoPlayer');
  }

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
                      data: _data,
                      height: timelineImageSize,
                    ),
                    Gap(smallMode ? $styles.insets.md : $styles.insets.lg),
                    SizedBox(
                      width: 400,
                      child: _TimelineBtn(type: widget.type),
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
                key: _eventsListKey,
                data: _data,
                topHeight: 100,
                blurOnScroll: false,
                onScroll: _handleScroll,
                initialScrollOffset: _scrollPos,
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
              _WonderImageWithTimeline(height: topHeight, data: _data),

              /// EventsList + TimelineBtn
              Column(
                children: [
                  Expanded(
                    /// EventsList
                    child: _EventsList(
                      key: _eventsListKey,
                      data: _data,
                      topHeight: topHeight,
                      blurOnScroll: true,
                      showTopGradient: false,
                      onScroll: _handleScroll,
                      initialScrollOffset: _scrollPos,
                    ),
                  ),
                  Gap($styles.insets.lg),

                  /// TimelineBtn
                  _TimelineBtn(
                    type: _data.type,
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

class const _VideoReplyPanel({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // key: const PageStorageKey(_VideoReplyPanelState),
      slivers: [
        SliverAppBar(
          pinned: true, // 吸顶效果
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          // backgroundColor: colorScheme.surface,
          title: Padding(
            padding: const .fromLTRB(12, 2.5, 6, 2.5),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('sortType.desc', style: const TextStyle(fontSize: 13)),
                TextButton.icon(
                  // style: Style.buttonStyle,
                  onPressed: () {}, //_videoReplyController.queryBySort,
                  icon: Icon(
                    Icons.sort,
                    size: 16,
                    // color: colorScheme.secondary,
                  ),
                  label: Text(
                    'sortType.descShort',
                    style: TextStyle(
                      fontSize: 13,
                      // color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        //_buildBody(_videoReplyController.loadingState.value),
      ],
    );
  }
}
