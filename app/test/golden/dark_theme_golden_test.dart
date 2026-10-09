import 'package:alchemist/alchemist.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/design/design.dart';
import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'golden_font.dart';

/// 暗色主题的 golden 变体。
///
/// 生产路径里暗色 `ThemeData` 由 `ThemeWrapper` 经
/// `appThemeData(AppColors(BrandPalette.of(Brightness.dark)))` 构造
/// （theme_wrapper.dart:33）——`BrandPalette._dark` 自带一整套暗色
/// `ColorScheme`。golden 必须走同一条路：写 `ThemeData(brightness: dark)`
/// 不够，它只改 brightness 而 `colorScheme` 仍是默认亮色（探针实测 surface
/// 亮度 0.948 近白，见 dark_theme_probe_test）。
///
/// 这里取同一个 `ColorScheme` 直接构造，而非 `appThemeData(...).copyWith(
/// fontFamily:)`：material_ui 1.4.0 的 `copyWith` 没有 `fontFamily` 参数，
/// 而 `appThemeData` 内部也不设字体族。字体族只在构造器里给得出。
ThemeData _darkGoldenTheme() {
  final colors = AppColors(BrandPalette.of(Brightness.dark));
  return ThemeData(
    fontFamily: goldenFontFamily,
    colorScheme: colors.scheme,
    textTheme: ThemeData.dark().textTheme,
  );
}

void main() {
  group('dark theme golden', () {
    goldenTest(
      'renders dark theme variants',
      fileName: 'dark_theme',
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: _darkGoldenTheme(),
              darkTheme: _darkGoldenTheme(),
              themeMode: ThemeMode.dark,
              // $styles 是 AppScaffold 持有的全局单例，由
              // Theme.of(context).brightness 决定取亮/暗哪套色板
              // （app_scaffold.dart:29-35）。不嵌一层 AppScaffold，
              // $styles 永远停在默认的 AppStyle(isDark:false)，VideoCard
              // 那 20 处 $styles.colors 全是亮色值——暗色基线就只有
              // Theme.colorScheme 那半边是暗的。
              home: AppScaffold(
                child: Scaffold(body: Center(child: widget)),
              ),
            ),
          );
          await tester.pumpAndSettle();
        });
      },
      builder: () => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 600,
        ),
        children: [
          // VideoCard 是 $styles 用得最密的组件之一（20 处），暗色下
          // surface / onSurface / badge 全部要换到另一套色板。
          GoldenTestScenario(
            name: 'video card',
            child: VideoCard(
              videoInfoBase: VideoModel(
                id: 'BV1dark01',
                title: '暗色主题下的视频卡片',
                url: 'https://www.bilibili.com/video/BV1dark01',
                thumbnailUrl: 'https://example.com/thumb.jpg',
                viewCount: 1280000,
                duration: 754,
                creatorProfileName: '测试UP主',
                creatorProfileId: '123456',
              ),
              variant: VideoCardVariant.feed,
              sourceBadge: '哔哩哔哩',
            ),
          ),
          // NotFoundScreen 的 Text 跟着 Theme.colorScheme 走，暗色下应取
          // onSurface 的暗色值。
          GoldenTestScenario(
            name: 'not found screen',
            child: const NotFoundScreen(
              uri: 'https://example.com/missing',
              path: '/missing',
            ),
          ),
          // FilterBar 折叠态：图标色取 $styles.colors，是三个场景里唯一
          // 同时吃 Theme 与 $styles 的，正好钉住两条通路都切了暗色。
          GoldenTestScenario(
            name: 'filter bar',
            child: FilterBar(
              filters: const [],
              onChanged: (_) {},
              title: '高级筛选',
            ),
          ),
        ],
      ),
    );
  });
}
