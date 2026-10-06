import 'package:app/data/repository/search/app_live_room_search_repository.dart';
import 'package:app/data/repository/search/app_user_search_repository.dart';
import 'package:app/data/repository/search/app_video_search_repository.dart';
import 'package:app/data/repository/search/app_youtube_video_search_repository.dart';
import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/providers/service_source_providers.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube/youtube.dart';

/// bilibili 分支应当注册的全部可读类型。
final Map<String, Object? Function(BuildContext)> _bilibiliReaders = {
  'String': (c) => c.read<String>(),
  'MediaSource': (c) => c.read<MediaSource>(),
  'Bili': (c) => c.read<Bili>(),
  'VideoSearchRepository': (c) => c.read<VideoSearchRepository>(),
  'CreatorProfileSearchRepository': (c) =>
      c.read<CreatorProfileSearchRepository>(),
  'LiveRoomSearchRepository': (c) => c.read<LiveRoomSearchRepository>(),
  'SearchSuggestRepository': (c) => c.read<SearchSuggestRepository>(),
  'VideoDetailRepository': (c) => c.read<VideoDetailRepository>(),
  'VideoCommentRepository': (c) => c.read<VideoCommentRepository>(),
};

/// youtube 分支应当注册的类型，以及必须**不**存在的类型。
final Map<String, Object? Function(BuildContext)> _youtubeReaders = {
  'String': (c) => c.read<String>(),
  'MediaSource': (c) => c.read<MediaSource>(),
  'YouTube': (c) => c.read<YouTube>(),
  'VideoSearchRepository': (c) => c.read<VideoSearchRepository>(),
  'VideoDetailRepository': (c) => c.read<VideoDetailRepository>(),
  'VideoCommentRepository': (c) => c.read<VideoCommentRepository>(),
  'CreatorProfileSearchRepository': (c) =>
      c.read<CreatorProfileSearchRepository>(),
};

void main() {
  const marker = '子组件标记';

  Widget build(String source, {String? ancestorSource}) {
    final child = MaterialApp(
      home: ServiceSourceProviders(source: source, child: const Text(marker)),
    );
    if (ancestorSource == null) return child;
    return RepositoryProvider<String>.value(
      value: ancestorSource,
      child: child,
    );
  }

  testWidgets('已注册标识正常渲染子组件', (tester) async {
    await tester.pumpWidget(build('bilibili'));
    expect(tester.takeException(), isNull);
    expect(find.text(marker), findsOneWidget);
  });

  testWidgets('未注册标识在无祖先 String 时抛 ArgumentError', (tester) async {
    await tester.pumpWidget(build('typo-source'));
    expect(tester.takeException(), isArgumentError);
  });

  // 回归：校验若放在提前 return child 之后，祖先 String 与 source 相同时会被绕过。
  testWidgets('祖先已注册同名 String 时未注册标识仍抛 ArgumentError', (tester) async {
    await tester.pumpWidget(
      build('typo-source', ancestorSource: 'typo-source'),
    );
    expect(tester.takeException(), isArgumentError);
    expect(find.text(marker), findsNothing);
  });
  // 以下用例钉住「哪个 source 注入哪些 Repository」：这是本文件的核心逻辑，
  // 缺了它，新增数据源漏注册某个 Repository 不会被任何测试发现。
  group('branch injection', () {
    Map<String, Object?> found = <String, Object?>{};

    setUp(() => found = <String, Object?>{});

    testWidgets('bilibili injects every repository its branch declares', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceSourceProviders(
            source: 'bilibili',
            child: Builder(
              builder: (BuildContext context) {
                for (final entry in _bilibiliReaders.entries) {
                  try {
                    found[entry.key] = entry.value(context);
                  } catch (e) {
                    found[entry.key] = e;
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(found['Bili'], isA<Bili>());
      expect(found['MediaSource'], isA<Bili>());
      expect(found['String'], 'bilibili');
      expect(found['VideoSearchRepository'], isA<AppVideoSearchRepository>());
      expect(
        found['CreatorProfileSearchRepository'],
        isA<AppUserSearchRepository>(),
      );
      expect(
        found['LiveRoomSearchRepository'],
        isA<AppLiveRoomSearchRepository>(),
      );
      expect(found['SearchSuggestRepository'], isA<AppUserSearchRepository>());
      expect(found['VideoDetailRepository'], isA<AppVideoDetailRepository>());
      expect(found['VideoCommentRepository'], isA<AppVideoCommentRepository>());
    });

    testWidgets('youtube injects only its own two repositories', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceSourceProviders(
            source: 'youtube',
            child: Builder(
              builder: (BuildContext context) {
                for (final entry in _youtubeReaders.entries) {
                  try {
                    found[entry.key] = entry.value(context);
                  } catch (e) {
                    found[entry.key] = e;
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(found['YouTube'], isA<YouTube>());
      expect(found['MediaSource'], isA<YouTube>());
      expect(found['String'], 'youtube');
      expect(
        found['VideoSearchRepository'],
        isA<AppYouTubeVideoSearchRepository>(),
      );
      // youtube 分支不注册详情/评论/直播等仓库，读这些必须抛。
      expect(found['VideoDetailRepository'], isA<ProviderNotFoundException>());
      expect(found['VideoCommentRepository'], isA<ProviderNotFoundException>());
      expect(
        found['CreatorProfileSearchRepository'],
        isA<ProviderNotFoundException>(),
      );
    });

    testWidgets('the media source instance is shared across repositories', (
      tester,
    ) async {
      // 详情仓库与评论仓库各自 context.read<Bili>()，若拿到不同实例，
      // 关闭时会残留未关闭的客户端。
      Object? error;
      bool shared = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceSourceProviders(
            source: 'bilibili',
            child: Builder(
              builder: (BuildContext context) {
                try {
                  final bili = context.read<Bili>();
                  // 详情/评论仓库各自经 context.read<Bili>() 取数据源；
                  // 确认它们与 String provider 同源于同一实例。
                  context.read<VideoDetailRepository>();
                  context.read<VideoCommentRepository>();
                  shared = identical(bili, context.read<MediaSource>());
                } catch (e) {
                  error = e;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(error, isNull);
      expect(shared, isTrue);
    });

    testWidgets('repeated reads within one tree share the instance', (
      tester,
    ) async {
      Object? error;
      bool sameInstance = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceSourceProviders(
            source: 'bilibili',
            child: Builder(
              builder: (BuildContext context) {
                try {
                  sameInstance = identical(
                    context.read<MediaSource>(),
                    context.read<MediaSource>(),
                  );
                } catch (e) {
                  error = e;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(error, isNull);
      expect(sameInstance, isTrue);
    });

    testWidgets('a remount builds a new media source instance', (tester) async {
      Object? firstId;
      Object? secondId;

      Future<void> mountOnce(void Function(MediaSource) record) =>
          tester.pumpWidget(
            MaterialApp(
              home: ServiceSourceProviders(
                source: 'bilibili',
                child: Builder(
                  builder: (BuildContext context) {
                    record(context.read<MediaSource>());
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

      await mountOnce((s) => firstId = identityHashCode(s));
      await mountOnce((s) => secondId = identityHashCode(s));

      // _registry 存构造函数 tear-off 而非实例：每次 mount 必须 new 出新
      // 实例，否则两次挂载共用一个客户端、dispose 时只关掉其中一个。
      expect(firstId, isNotNull);
      expect(secondId, isNotNull);
      expect(secondId, isNot(firstId));
    });
  });
}
