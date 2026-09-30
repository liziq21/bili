import 'package:alchemist/alchemist.dart';
import 'package:app/ui/search/creator_profile_item.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'golden_font.dart';

void main() {
  group('CreatorProfileItem golden', () {
    goldenTest(
      'renders CreatorProfileItem variants',
      fileName: 'creator_profile_item',
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: goldenTestTheme(),
              home: Scaffold(body: Center(child: widget)),
            ),
          );
          await tester.pumpAndSettle();
        });
      },
      builder: () => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: const BoxConstraints(maxWidth: 360, maxHeight: 80),
        children: [
          GoldenTestScenario(
            name: 'default with avatar',
            child: CreatorProfileItem(
              creatorProfile: const CreatorProfile(
                id: '123456',
                name: '测试UP主',
                thumbnailUrl: 'https://example.com/avatar.jpg',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'without avatar',
            child: CreatorProfileItem(
              creatorProfile: const CreatorProfile(id: '654321', name: '无图创作者'),
            ),
          ),
          GoldenTestScenario(
            name: 'long name and id',
            child: CreatorProfileItem(
              creatorProfile: const CreatorProfile(
                id: '9999999999999999999',
                name: '长名字创作者长名字创作者长名字创作者',
                thumbnailUrl: 'https://example.com/avatar.jpg',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with stats and live status',
            child: CreatorProfileItem(
              creatorProfile: const CreatorProfile(
                id: '888888',
                name: '热门创作者',
                thumbnailUrl: 'https://example.com/avatar.jpg',
                isLive: true,
                liveRoomId: 1001,
                subscribers: 1000000,
                videos: 500,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
