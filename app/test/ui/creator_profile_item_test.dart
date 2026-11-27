import 'dart:ui' show SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/ui/search/creator_profile_item.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;

void main() {
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
        const MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
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
