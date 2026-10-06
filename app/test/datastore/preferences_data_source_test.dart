import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/datastore/preferences_key_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 聚合 [PreferencesKey.sourceId] 与 [PreferencesKey.themeConfig] 两个 key，
/// 用于验证 streamOfSet 的聚合语义。
class _SourceAndThemeSet implements PreferencesKeySet<String> {
  @override
  List<PreferencesKey<Object?>> get keys => [
    PreferencesKey.sourceId,
    PreferencesKey.themeConfig,
  ];

  @override
  String fromJson(Map<String, Object?> json) =>
      '${json['SOURCE_ID'] ?? '-'}/${json['THEME_CONFIG'] ?? '-'}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySharedPreferencesAsync inMemory;
  late PreferencesDataSource ds;

  setUp(() {
    inMemory = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = inMemory;
    ds = PreferencesDataSource(sharedPreferences: SharedPreferencesAsync());
  });

  tearDown(() {
    ds.dispose();
  });

  group('PreferencesKey values and defaults', () {
    test('returns null when a nullable String key is unset', () async {
      final Result<String?> result = await ds.get(PreferencesKey.sourceId);

      expect(result.isOk, isTrue);
      expect((result as Ok<String?>).value, isNull);
    });

    test('reads back the value written to a nullable String key', () async {
      await ds.set(PreferencesKey.sourceId, 'bilibili');

      final Result<String?> result = await ds.get(PreferencesKey.sourceId);

      expect(result.isOk, isTrue);
      expect((result as Ok<String?>).value, 'bilibili');
    });

    test('falls back to the declared true default for bool', () async {
      // useDynamicColor 的默认值是 true，读默认值而不是 false 才能让首次启动
      // 进入动态取色。
      final result = await ds.get(PreferencesKey.useDynamicColor);

      expect((result as Ok<bool>).value, isTrue);
    });

    test('falls back to the declared default for String', () async {
      final result = await ds.get(PreferencesKey.themeConfig);

      expect((result as Ok<String>).value, 'FOLLOW_SYSTEM');
    });

    test('reads back false after writing false to a bool key', () async {
      await ds.set(PreferencesKey.useDynamicColor, false);

      final result = await ds.get(PreferencesKey.useDynamicColor);

      expect((result as Ok<bool>).value, isFalse);
    });

    test('does not cross values between bool and String keys', () async {
      // 若 set 的类型分发把 bool 落到 String 分支，或 get 的类型判定把
      // SOURCE_ID 当成 bool 读，读回值会互换。
      await ds.set(PreferencesKey.themeConfig, 'DARK');
      await ds.set(PreferencesKey.useDynamicColor, false);

      final theme = await ds.get(PreferencesKey.themeConfig);
      final dynamicColor = await ds.get(PreferencesKey.useDynamicColor);

      expect((theme as Ok<String>).value, 'DARK');
      expect((dynamicColor as Ok<bool>).value, isFalse);
    });

    test('treats writing null as removal and falls back to default', () async {
      await ds.set(PreferencesKey.useDynamicColor, false);
      await ds.set(PreferencesKey.useDynamicColor, null);

      final result = await ds.get(PreferencesKey.useDynamicColor);

      expect((result as Ok<bool>).value, isTrue);
    });
  });

  group('data stream', () {
    test('emits UserData after a write', () async {
      // 订阅时 onListen 会先读一次并发出当时的快照，所以要跳过第一次、
      // 取写入后的那次发射。
      final values = <String?>[];
      final sub = ds.data.listen((d) => values.add(d.sourceId));

      await ds.set(PreferencesKey.sourceId, 'bilibili');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(values, [null, 'bilibili']);
    });

    test('emits default UserData when nothing was written', () async {
      final emitted = ds.data.first;

      final data = await emitted;
      expect(data.sourceId, isNull);
      expect(data.useDynamicColor, isTrue);
    });

    test('shares one broadcast stream across repeated data access', () async {
      // 每个订阅者都收到同一批事件，说明底层 controller 是共享的；判据用
      // 订阅行为而不是 stream 对象的标识——同一 controller 的 .stream 每次
      // 访问都会返回新的包装器，identical 恒为 false。
      final a = <String?>[];
      final b = <String?>[];
      final subA = ds.data.listen((d) => a.add(d.sourceId));
      final subB = ds.data.listen((d) => b.add(d.sourceId));

      await ds.set(PreferencesKey.sourceId, 'bilibili');
      await Future<void>.delayed(Duration.zero);

      await subA.cancel();
      await subB.cancel();
      expect(a, isNotEmpty);
      expect(b, a);
    });
  });

  group('streamOf caching and updates', () {
    test('delivers the same events to two subscribers of one key', () async {
      final a = <bool>[];
      final b = <bool>[];
      final subA = ds.streamOf(PreferencesKey.useDynamicColor).listen(a.add);
      final subB = ds.streamOf(PreferencesKey.useDynamicColor).listen(b.add);

      await ds.set(PreferencesKey.useDynamicColor, false);
      await Future<void>.delayed(Duration.zero);

      await subA.cancel();
      await subB.cancel();
      expect(a, [true, false]);
      expect(b, a);
    });

    test('delivers the new value to an existing subscriber', () async {
      final values = <bool>[];
      final sub = ds
          .streamOf(PreferencesKey.useDynamicColor)
          .listen(values.add);

      await ds.set(PreferencesKey.useDynamicColor, false);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(values, [
        true,
        false,
      ], reason: 'default first, then the written value');
    });

    test('keeps streams of different keys independent', () async {
      final sourceValues = <String?>[];
      final themeValues = <String>[];
      final sub1 = ds
          .streamOf(PreferencesKey.sourceId)
          .listen(sourceValues.add);
      final sub2 = ds
          .streamOf(PreferencesKey.themeConfig)
          .listen(themeValues.add);

      await ds.set(PreferencesKey.sourceId, 'bilibili');
      await Future<void>.delayed(Duration.zero);

      await sub1.cancel();
      await sub2.cancel();
      expect(sourceValues.last, 'bilibili');
      expect(themeValues.last, 'FOLLOW_SYSTEM');
    });

    test(
      're-reads current value when subscribing again after cancel',
      () async {
        final sub = ds.streamOf(PreferencesKey.useDynamicColor).listen((_) {});
        await sub.cancel();

        await ds.set(PreferencesKey.useDynamicColor, false);

        // 重新订阅必须读到 false（当前值）而不是默认值 true。
        final again = ds.streamOf(PreferencesKey.useDynamicColor);
        final value = await again.first;

        expect(value, isFalse);
      },
    );
  });

  group('streamOfSet aggregation', () {
    test('emits a new aggregate when any member key is written', () async {
      final values = <String>[];
      final sub = ds.streamOfSet(_SourceAndThemeSet()).listen(values.add);

      await ds.set(PreferencesKey.sourceId, 'bilibili');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(values.last, contains('bilibili'));
    });

    test(
      'delivers the same aggregate to two subscribers of one keySet',
      () async {
        final a = <String>[];
        final b = <String>[];
        final subA = ds.streamOfSet(_SourceAndThemeSet()).listen(a.add);
        final subB = ds.streamOfSet(_SourceAndThemeSet()).listen(b.add);

        await ds.set(PreferencesKey.sourceId, 'bilibili');
        await Future<void>.delayed(Duration.zero);

        await subA.cancel();
        await subB.cancel();
        expect(a, isNotEmpty);
        expect(b, a);
      },
    );
  });

  group('dispose', () {
    test('rebuilds a usable data stream after dispose', () async {
      // 必须先访问 data 把 controller 建出来：否则 dispose 时 _controller
      // 本就是 null，「置空」与否无观测差异，这条用例就成假绿。
      await ds.data.first;

      ds.dispose();

      // dispose 只置空引用、不置新值，所以重取应重新读盘并发射当前数据。
      final value = await ds.data.first;
      expect(value.sourceId, isNull);
      expect(value.useDynamicColor, isTrue);
    });

    test('still receives writes on the rebuilt stream after dispose', () async {
      await ds.data.first;
      ds.dispose();

      final values = <String?>[];
      final sub = ds.data.listen((d) => values.add(d.sourceId));

      await ds.set(PreferencesKey.sourceId, 'bilibili');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      // 若 dispose 未置空 _controller，这里拿到的是已关闭的流，永远收不到写入。
      expect(values, [null, 'bilibili']);
    });

    test('can be called repeatedly without throwing', () async {
      ds.dispose();

      expect(ds.dispose, returnsNormally);
      expect(ds.dispose, returnsNormally);
    });
  });
}
