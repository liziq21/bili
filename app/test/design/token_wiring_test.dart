import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/design/design.dart';
import 'package:app/main.dart';
import 'package:app/ui/search/creator_profile_item.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;

/// P4 迁移的接线断言。
///
/// 断言的是**颜色取自 token**（与 `$styles.colors.*` 相等），不是断言具体
/// 色值：色值归 `BrandPalette` 独占（R1），这里要防的是「有人改回字面量」
/// 或「某处漏接 token」。
///
/// 为什么不靠 golden：`flutter_test_config.dart` 的 `CiGoldensConfig(
/// diffThreshold: 0.01)` 允许 1% 像素带差异，而本文件覆盖的几处改动
/// 实测只占 `video_card.png` 的 0.548%、`video_feed_section.png` 的
/// 0.184%——全部在阈值内，改动前后 golden 都判绿。golden 证明不了这里的
/// 任何断言，见 `app/docs/design-system.md` 的「验证范围声明」。
void main() {
  group('P4 硬编码色迁移的 token 接线', () {
    testWidgets('CreatorProfileItem 的 ID 文字取 onSurfaceVariant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 80,
              child: CreatorProfileItem(
                creatorProfile: const CreatorProfile(
                  id: '188339',
                  name: 'CodeCraft',
                  thumbnailUrl: 'https://example.com/avatar.jpg',
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final id = tester.widget<Text>(find.text('@188339'));
      expect(
        id.style?.color,
        $styles.colors.onSurfaceVariant,
        reason: 'ID 文字应读 onSurfaceVariant（弱化文字：时间戳、标签）',
      );
      await clearImageCacheDuringTest(tester);
    });

    testWidgets('CreatorProfileItem 的箭头图标取 outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 80,
              child: CreatorProfileItem(
                creatorProfile: const CreatorProfile(
                  id: '188339',
                  name: 'CodeCraft',
                  thumbnailUrl: 'https://example.com/avatar.jpg',
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final chevron = tester.widget<Icon>(
        find.byIcon(Icons.chevron_right_rounded),
      );
      expect(
        chevron.color,
        $styles.colors.outline,
        reason: '箭头属弱图形，与分隔线同取 outline',
      );
      await clearImageCacheDuringTest(tester);
    });

    testWidgets('VideoCard 默认样式的副标题取 onSurfaceVariant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 280,
              child: VideoCard(
                videoInfoBase: VideoModel(
                  id: 'BV1xx411c7mD',
                  title: '标题',
                  url: 'https://www.bilibili.com/video/BV1xx411c7mD',
                  thumbnailUrl: 'https://example.com/thumb.jpg',
                  viewCount: 1280000,
                  duration: 754,
                ),
              ),
            ),
          ),
        ),
      );

      final subtitle = tester.widget<Text>(find.textContaining('观看'));
      expect(
        subtitle.style?.color,
        $styles.colors.onSurfaceVariant,
        reason: '副标题属弱化文字',
      );
      await clearImageCacheDuringTest(tester);
    });

    testWidgets('VideoCard feed 样式的时长角标取 scrim / onScrim', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 280,
              child: VideoCard(
                variant: VideoCardVariant.feed,
                videoInfoBase: VideoModel(
                  id: 'BV1xx411c7mD',
                  title: '标题',
                  url: 'https://www.bilibili.com/video/BV1xx411c7mD',
                  thumbnailUrl: 'https://example.com/thumb.jpg',
                  viewCount: 1280000,
                  duration: 754,
                ),
              ),
            ),
          ),
        ),
      );

      // 754s -> "12:34"，取时长角标里那一个 Text。
      final duration = tester.widget<Text>(find.text('12:34'));
      expect(
        duration.style?.color,
        $styles.colors.onScrim,
        reason: '压在 scrim 之上的前景',
      );

      // 角标底是唯一的 75% 透明深色容器。
      final badges = tester.widgetList<Container>(find.byType(Container)).where(
        (c) {
          final decoration = c.decoration;
          return decoration is BoxDecoration && decoration.color != null;
        },
      ).toList();
      expect(
        badges.map((c) => (c.decoration! as BoxDecoration).color).toList(),
        contains($styles.colors.scrim.withValues(alpha: 0.75)),
        reason: '时长标签底属恒深承载面，用 scrim 而非黑色字面量',
      );
      await clearImageCacheDuringTest(tester);
    });

    testWidgets('FilterBar 底部面板的拖拽条取 outline', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              filters: const [],
              onChanged: (_) {},
              title: '筛选条件',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // 拖拽条是面板头部里唯一 36x4 的容器。
      final handle = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxWidth == 36)
          .single;
      final decoration = handle.decoration! as BoxDecoration;
      expect(
        decoration.color,
        $styles.colors.outline,
        reason: '拖拽条属弱图形，与分隔线同取 outline',
      );
    });

    // Greptile P1：CreatorProfileItem 的 build() 修复前不读 Theme.of，
    // $styles 是全局静态量，主题翻转后 AppScaffold 交回同一 child 实例、
    // Element.updateChild 短路，颜色停留旧值。照 palette_test.dart 的
    // "page rebuild on theme flip" 范式：探针照抄 video_screen.dart 的
    // 依赖声明，断言的是**画出来的色值**（不是静态量），只有真正重跑
    // build 才能变色。
    testWidgets('CreatorProfileItem 主题翻转后重建', (tester) async {
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);

      const cp = CreatorProfile(
        id: '188339',
        name: 'CodeCraft',
        thumbnailUrl: 'https://example.com/avatar.jpg',
      );
      final item = CreatorProfileItem(creatorProfile: cp, onTap: () {});

      Color idTextColor(WidgetTester t) =>
          t.widget<Text>(find.text('@188339')).style!.color!;

      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: mode,
          builder: (_, ThemeMode m, _) => MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: MaterialApp(
              theme: appThemeData(AppColors(BrandPalette.of(Brightness.light))),
              darkTheme: appThemeData(
                AppColors(BrandPalette.of(Brightness.dark)),
              ),
              themeMode: m,
              home: AppScaffold(
                child: SizedBox(width: 320, height: 80, child: item),
              ),
            ),
          ),
        ),
      );
      final light = idTextColor(tester);
      expect(
        light,
        AppColors(BrandPalette.of(Brightness.light)).onSurfaceVariant,
      );

      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      final dark = idTextColor(tester);
      expect(
        dark,
        AppColors(BrandPalette.of(Brightness.dark)).onSurfaceVariant,
        reason: '翻转后必须重读暗色板；修复前 build 不依赖 Theme，会停留亮色值',
      );
      expect(dark, isNot(equals(light)));
      await clearImageCacheDuringTest(tester);
    });
  });
}
