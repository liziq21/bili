import 'dart:ui' show SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/ui/metadata_line.dart';
import 'package:app/ui/search/creator_profile_item.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;
import '../golden/golden_font.dart';

void main() {
  // 宽度断言必须用 golden 字体子集排版：Ahem 的每个字形都是 1em 宽，
  // 量不出真实卡片里「UID 放不下、关注数与视频数放得下」这个关系。
  setUpAll(loadGoldenFont);

  test('formatCount keeps the raw count without localizations', () {
    expect(CreatorProfileItem.formatCount(500), '500');
    expect(CreatorProfileItem.formatCount(15000), '');
    expect(CreatorProfileItem.formatCount(null), '');
  });

  testWidgets(
    'CreatorProfileItem renders creator info and accessibility semantics correctly',
    (WidgetTester tester) async {
      bool tapped = false;
      const creator = CreatorProfile(
        id: '188339',
        name: 'CodeCraft',
        thumbnailUrl: 'https://example.com/avatar.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 80,
              child: CreatorProfileItem(
                creatorProfile: creator,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Semantics label exists for screen readers
      expect(find.bySemanticsLabel('CodeCraft, @188339'), findsOneWidget);

      // Verify tap behavior
      await tester.tap(find.byType(CreatorProfileItem));
      expect(tapped, isTrue);
      await clearImageCacheDuringTest(tester);
    },
  );

  testWidgets(
    'CreatorProfileItem handles untapped/null onTap gracefully without throwing',
    (WidgetTester tester) async {
      const creator = CreatorProfile(id: '188339', name: 'CodeCraft');

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 80,
              child: CreatorProfileItem(creatorProfile: creator),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('CodeCraft, @188339'), findsOneWidget);
      await tester.tap(find.byType(CreatorProfileItem));
      await tester.pump();
    },
  );

  testWidgets(
    'CreatorProfileItem enforces ellipsis and single-line layout for name and subtitle',
    (WidgetTester tester) async {
      const creator = CreatorProfile(
        id: '12345678901234567890',
        name: 'Very Long Creator Profile Name Designed To Assert Ellipsis',
      );

      await tester.pumpWidget(
        MaterialApp(
          // 只有换上 golden 字体子集，宽度才是真实比例字体的宽度；默认的
          // Ahem 每个字形都是 1em 方块，量不出「放得下几个字段」。
          theme: goldenTestTheme(),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: SizedBox(
              // 比 20 位 UID 在该字号下的宽度更窄，省略号才有机会出现。
              width: 160,
              height: 80,
              child: CreatorProfileItem(creatorProfile: creator),
            ),
          ),
        ),
      );

      final nameWidget = tester.widget<Text>(
        find.text('Very Long Creator Profile Name Designed To Assert Ellipsis'),
      );
      expect(nameWidget.maxLines, 1);
      expect(nameWidget.overflow, TextOverflow.ellipsis);

      final subtitle = tester.renderObject<RenderMetadataLine>(
        find.byType(MetadataLine),
      );
      expect(subtitle.renderedText, startsWith('@12345678901234567890'));
      // 单行 + 省略号：超长的 UID 只会被截断，不会换行撑高卡片。
      expect(subtitle.textWasClipped, isTrue);
      expect(subtitle.size.height, lessThan(24));
    },
  );

  testWidgets(
    'CreatorProfileItem drops the UID before the follower and video counts',
    (WidgetTester tester) async {
      // #682：360dp 宽的搜索页里频道卡片只剩 190dp 左右可用。UID 排在最前面又最长，
      // 整串省略时把「关注数 · 视频数」一起挤掉了；UID 的信息量最低，必须
      // 最先让位。
      const creator = CreatorProfile(
        id: '1320808120',
        name: 'Genshin',
        subscribers: 46000,
        videos: 503,
        isLive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: goldenTestTheme(),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              height: 80,
              child: CreatorProfileItem(creatorProfile: creator),
            ),
          ),
        ),
      );

      final subtitle = tester.renderObject<RenderMetadataLine>(
        find.byType(MetadataLine),
      );

      // 关注数和视频数都必须留下：只断言其中一个，优先级写反了也看不出来。
      expect(subtitle.renderedText, contains('4.6万'));
      expect(subtitle.renderedText, contains('视频'));
      expect(subtitle.renderedText, isNot(contains('@1320808120')));
      expect(subtitle.textWasClipped, isFalse);
      await clearImageCacheDuringTest(tester);
    },
  );

  testWidgets('CreatorProfileItem renders and forwards the subscribe action', (
    WidgetTester tester,
  ) async {
    const creator = CreatorProfile(id: '188339', name: 'CodeCraft');
    var itemTapped = false;
    var toggles = 0;

    Widget build({required bool isSubscribed}) => MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 80,
          child: CreatorProfileItem(
            creatorProfile: creator,
            onTap: () => itemTapped = true,
            isSubscribed: isSubscribed,
            onToggleSubscribe: () => toggles++,
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(isSubscribed: false));

    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);

    await tester.tap(find.text('Subscribe'));
    expect(toggles, 1);
    expect(itemTapped, isFalse);

    await tester.pumpWidget(build(isSubscribed: true));

    expect(find.text('Unsubscribe'), findsOneWidget);
    await tester.tap(find.text('Unsubscribe'));
    expect(toggles, 2);
    expect(itemTapped, isFalse);
  });

  testWidgets('CreatorProfileItem exposes a screen-reader tap action', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var tapCount = 0;
    const creator = CreatorProfile(id: '188339', name: 'CodeCraft');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 80,
            child: CreatorProfileItem(
              creatorProfile: creator,
              onTap: () => tapCount++,
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(CreatorProfileItem));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(tapCount, 1);
    semantics.dispose();
    await clearImageCacheDuringTest(tester);
  });

  testWidgets('CreatorProfileItem without onTap exposes no tap action', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const creator = CreatorProfile(id: '188339', name: 'CodeCraft');

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 80,
            child: CreatorProfileItem(creatorProfile: creator),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(CreatorProfileItem));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    semantics.dispose();
    await clearImageCacheDuringTest(tester);
  });
}
