import 'package:app/feature/video/common_widgets/video_description_text.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _FakeMediaSource extends MediaSource {
  @override
  String get id => 'bilibili';

  @override
  String get name => 'Bilibili';
}

void main() {
  group('tokenizeDescription', () {
    test('returns a single text token for plain text', () {
      final tokens = tokenizeDescription('plain description');

      expect(tokens, hasLength(1));
      expect(tokens.single.type, DescriptionTokenType.text);
      expect(tokens.single.text, 'plain description');
    });

    test('returns no tokens for an empty string', () {
      expect(tokenizeDescription(''), isEmpty);
    });

    test('splits a URL and a topic out of surrounding text', () {
      final tokens = tokenizeDescription(
        'watch https://www.bilibili.com/video/BV1xx411c7mD then #Flutter#',
      );

      expect(tokens.map((token) => (token.type, token.text)), [
        (DescriptionTokenType.text, 'watch '),
        (
          DescriptionTokenType.link,
          'https://www.bilibili.com/video/BV1xx411c7mD',
        ),
        (DescriptionTokenType.text, ' then '),
        (DescriptionTokenType.topic, '#Flutter#'),
      ]);
    });

    test('trims sentence punctuation that trails a URL', () {
      final fullStop = String.fromCharCode(0x3002);
      final tokens = tokenizeDescription('see https://example.com/a$fullStop');

      expect(tokens.map((token) => (token.type, token.text)), [
        (DescriptionTokenType.text, 'see '),
        (DescriptionTokenType.link, 'https://example.com/a'),
        (DescriptionTokenType.text, fullStop),
      ]);
    });

    test('keeps multiple links and topics in order', () {
      final tokens = tokenizeDescription(
        'https://a.example #one# https://b.example #two#',
      );

      expect(tokens.map((token) => token.type), [
        DescriptionTokenType.link,
        DescriptionTokenType.text,
        DescriptionTokenType.topic,
        DescriptionTokenType.text,
        DescriptionTokenType.link,
        DescriptionTokenType.text,
        DescriptionTokenType.topic,
      ]);
    });
  });

  group('VideoDescriptionText', () {
    Widget mount(String text, {bool isExpanded = false}) {
      return MaterialApp(
        home: Scaffold(
          body: VideoDescriptionText(text: text, isExpanded: isExpanded),
        ),
      );
    }

    TextSpan descriptionSpan(WidgetTester tester) {
      final text = tester.widget<Text>(find.byType(Text));
      return text.textSpan! as TextSpan;
    }

    testWidgets('renders links as tappable underlined spans', (tester) async {
      await tester.pumpWidget(mount('open https://example.com now'));

      final span = descriptionSpan(tester);
      final linkSpan = span.children!.whereType<TextSpan>().singleWhere(
        (child) => child.recognizer != null,
      );

      expect(linkSpan.text, 'https://example.com');
      expect(linkSpan.style?.decoration, TextDecoration.underline);
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('tapping an external link copies it to the clipboard', (
      tester,
    ) async {
      final clipboardCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      // The whole text is the link, so a real tap exercises the gesture path
      // through SelectionArea instead of invoking the recognizer directly.
      await tester.pumpWidget(mount('https://example.com'));
      await tester.tap(find.byType(Text));
      await tester.pump();

      expect(clipboardCalls, hasLength(1));
      expect(
        (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
        'https://example.com',
      );
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('tapping a Bilibili video link navigates in-app', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MultiProvider(
              providers: [
                Provider<MediaSource>.value(value: _FakeMediaSource()),
                Provider<MediaSourceCatalog>.value(
                  value: MediaSourceCatalog([
                    MediaSourceDefinition(
                      id: 'bilibili',
                      name: 'Bilibili',
                      create: _FakeMediaSource.new,
                    ),
                  ]),
                ),
              ],
              child: const Scaffold(
                body: VideoDescriptionText(
                  text: 'https://www.bilibili.com/video/BV1xx411c7mD',
                  isExpanded: true,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/video/:id',
            builder: (context, state) =>
                Scaffold(body: Text('video:${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final linkSpan = descriptionSpan(tester).children!
          .whereType<TextSpan>()
          .singleWhere((child) => child.recognizer != null);
      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      expect(find.text('video:BV1xx411c7mD'), findsOneWidget);
    });

    testWidgets('collapsed text is limited to two lines', (tester) async {
      await tester.pumpWidget(mount('a description'));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('expanded text is not line limited', (tester) async {
      await tester.pumpWidget(mount('a description', isExpanded: true));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, isNull);
      expect(text.overflow, TextOverflow.visible);
    });
  });
}
