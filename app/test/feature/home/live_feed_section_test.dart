import 'package:app/app_scaffold.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/live_feed_section.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('does not repeat the active feed title above the cards', (
    WidgetTester tester,
  ) async {
    final room = LiveRoomModel(
      id: 1001,
      title: '直播',
      url: 'https://live.bilibili.com/1001',
      creatorProfileName: '未知主播',
      isLive: true,
    );
    final section = FeedSectionState<LiveRoomModel>(
      id: 'live_section',
      title: '推荐直播',
      status: FeedStatus.success,
      items: [room],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: CustomScrollView(
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
    );
    await tester.pump();

    // The filter bar already names the active feed.
    expect(find.text('推荐直播'), findsNothing);
  });

  testWidgets(
    'keeps every visible card inside the viewport on a desktop window',
    (WidgetTester tester) async {
      // 回归：卡片宽度按外层宽度算，而横向 ListView 的 padding 在卡片之外，
      // 桌面端一屏 4 张时最右一张整体溢出到窗口外（1189 宽实测溢出 7px）。
      tester.view.physicalSize = const Size(1189, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final section = FeedSectionState<LiveRoomModel>(
        id: 'live_section',
        title: '推荐直播',
        status: FeedStatus.success,
        items: [
          for (var i = 0; i < 6; i++)
            LiveRoomModel(
              id: 1000 + i,
              title: '直播标题 $i',
              url: 'https://live.bilibili.com/${1000 + i}',
              creatorProfileName: '主播 $i',
              isLive: true,
            ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: CustomScrollView(
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
      );
      await tester.pump();

      // 横向列表会按缓存范围多建几张卡，只校验一屏能看到的这四张。
      final cards = find.byType(InkWell).evaluate().take(4).toList();
      expect(cards, hasLength(4));
      for (final element in cards) {
        final box = element.renderObject! as RenderBox;
        final right = box.localToGlobal(Offset.zero).dx + box.size.width;
        expect(
          right,
          lessThanOrEqualTo(1189),
          reason: 'the card right edge must stay inside the viewport',
        );
      }
    },
  );

  group('adaptive columns', () {
    // 回归：#644 在 1280 宽桌面上一屏 4 张时最右一张整体溢出，1000 宽时
    // 第四张被裁掉一截。列数必须由可用宽度算出，且卡片宽度精确铺满，
    // 任何宽度下都不能有卡落在视口外。
    for (final width in <double>[1280, 1189, 1000, 768, 400, 300, 180]) {
      testWidgets('keeps every card inside a ${width.toInt()}px viewport', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(width, 500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final section = FeedSectionState<LiveRoomModel>(
          id: 'live_section',
          title: '推荐直播',
          status: FeedStatus.success,
          items: [
            for (var i = 0; i < 8; i++)
              LiveRoomModel(
                id: 1000 + i,
                title: '直播标题 $i',
                url: 'https://live.bilibili.com/${1000 + i}',
                creatorProfileName: '主播 $i',
                isLive: true,
              ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: Scaffold(
              body: CustomScrollView(
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
        );
        await tester.pump();

        final cards = find.byType(InkWell).evaluate().toList();
        expect(cards, isNotEmpty);
        for (final element in cards) {
          final box = element.renderObject! as RenderBox;
          final left = box.localToGlobal(Offset.zero).dx;
          expect(left, greaterThanOrEqualTo(0));
          expect(
            left + box.size.width,
            lessThanOrEqualTo(width),
            reason: 'the card right edge must stay inside the viewport',
          );
        }
      });
    }
  });

  testWidgets('clips the card content to its rounded shape', (
    WidgetTester tester,
  ) async {
    // 封面是不透明的 Container，Material 不裁剪时会盖掉顶部两个圆角。
    final section = FeedSectionState<LiveRoomModel>(
      id: 'live_section',
      title: '推荐直播',
      status: FeedStatus.success,
      items: [
        LiveRoomModel(
          id: 1001,
          title: '直播',
          url: 'https://live.bilibili.com/1001',
          creatorProfileName: '主播',
          isLive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: CustomScrollView(
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
    );
    await tester.pump();

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.byType(InkWell), matching: find.byType(Material))
          .first,
    );
    expect(material.clipBehavior, Clip.antiAlias);
  });

  testWidgets('mouse wheel scrolls the live row horizontally', (
    WidgetTester tester,
  ) async {
    // 回归 LIZ-198：横向列表只读取滚轮的 dx，普通滚轮只给出 dy，桌面端
    // 鼠标停在卡片上滚动时整行纹丝不动，一屏 4 张之外的房间无法到达。
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final section = FeedSectionState<LiveRoomModel>(
      id: 'live_section',
      title: '推荐直播',
      status: FeedStatus.success,
      items: [
        for (var i = 0; i < 30; i++)
          LiveRoomModel(
            id: 1000 + i,
            title: '直播标题 $i',
            url: 'https://live.bilibili.com/${1000 + i}',
            creatorProfileName: '主播 $i',
            isLive: true,
          ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: CustomScrollView(
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
    );
    await tester.pump();

    final horizontal = tester.state<ScrollableState>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.right,
      ),
    );
    expect(horizontal.position.pixels, 0);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(
      tester.getCenter(
        find.byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        ),
      ),
    );
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 300)));
    await tester.pump();

    // 300 像素滚轮增量应原样落到横向位置，而不是只挪动一点点。
    expect(horizontal.position.pixels, 300);
  });

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
