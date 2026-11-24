import 'package:app/app_scaffold.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/live_feed_section.dart';
import 'package:data/data.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'LiveFeedSection renders live room cards with tooltip, semantics label, and handles tap',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      LiveRoomModel? tappedRoom;

      final room = LiveRoomModel(
        id: 1001,
        title: '直播',
        url: 'https://live.bilibili.com/1001',
        creatorProfileName: '未知主播',
        isLive: true,
        thumbnailUrl: '',
      );

      final section = FeedSectionState<LiveRoomModel>(
        id: 'live_section',
        title: '推荐直播',
        status: FeedStatus.success,
        items: [room],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LiveFeedSection(
                  section: section,
                  onLiveTap: (r) => tappedRoom = r,
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 筛选栏已经显示当前 Feed，区块头不应再重复同一个标题。
      expect(find.text('推荐直播'), findsNothing);

      // Check tooltip
      expect(find.byTooltip('直播'), findsOneWidget);

      // Check semantics label via InkWell semantics node
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);
      final semanticsData = tester
          .getSemantics(inkWellFinder)
          .getSemanticsData();
      expect(semanticsData.label, equals('直播'));
      expect(semanticsData.flagsCollection.isButton, isTrue);

      // Tap live room card
      await tester.tap(find.byTooltip('直播'));
      expect(tappedRoom, equals(room));

      semantics.dispose();
    },
  );

  group('card layout budget', () {
    // 回归：文字高度曾按 fontSize * 1.5 估算，而 bodySmall 的真实行高是
    // 23/14 ≈ 1.643，每行少算 2px。放大字号后两行文字被 Flexible 挤进不足
    // 的高度里，字形下半截被裁掉（textScale 1.3 时实测 29.3px vs 自然 30px）。
    for (final double textScale in [1.0, 1.15, 1.3]) {
      testWidgets('keeps both text lines at natural height ($textScale)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          Builder(builder: (context) => AppScaffold(child: const SizedBox())),
        );

        final room = LiveRoomModel(
          id: 1001,
          title: '直播间标题',
          url: 'https://live.bilibili.com/1001',
          creatorProfileName: '主播名字',
          isLive: true,
          thumbnailUrl: '',
        );
        final section = FeedSectionState<LiveRoomModel>(
          id: 'live_section',
          title: '推荐直播',
          status: FeedStatus.success,
          items: [room],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: CustomScrollView(
                  slivers: [
                    LiveFeedSection(
                      section: section,
                      onLiveTap: (_) {},
                      onRetry: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final lines = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .where(
              (p) =>
                  p.text.toPlainText() == '直播间标题' ||
                  p.text.toPlainText() == '主播名字',
            )
            .toList();

        expect(lines, hasLength(2));
        for (final line in lines) {
          expect(
            line.size.height,
            greaterThanOrEqualTo(
              line.getMaxIntrinsicHeight(double.infinity) - 0.01,
            ),
            reason: 'text "${line.text.toPlainText()}" was squeezed',
          );
        }
      });
    }
  });
}
