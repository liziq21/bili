import 'package:app/ui/search/creator_profile_item.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;

void main() {
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
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
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

      final subtitleWidget = tester.widget<Text>(
        find.text('@12345678901234567890'),
      );
      expect(subtitleWidget.maxLines, 1);
      expect(subtitleWidget.overflow, TextOverflow.ellipsis);
    },
  );
}
