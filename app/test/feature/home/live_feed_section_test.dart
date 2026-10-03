import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/live_feed_section.dart';
import 'package:data/data.dart';
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
                  sourceName: 'Bilibili',
                  onLiveTap: (r) => tappedRoom = r,
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tooltip
      expect(find.byTooltip('直播'), findsOneWidget);

      // Check semantics label via InkWell semantics node
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);
      final semanticsData = tester
          .getSemantics(inkWellFinder)
          .getSemanticsData();
      expect(semanticsData.label, equals('直播，主播: 未知主播，直播中'));
      expect(semanticsData.flagsCollection.isButton, isTrue);

      // Tap live room card
      await tester.tap(find.byTooltip('直播'));
      expect(tappedRoom, equals(room));

      semantics.dispose();
    },
  );
}
