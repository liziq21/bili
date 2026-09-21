import 'package:app/ui/search/creator_profile_item.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    },
  );
}
