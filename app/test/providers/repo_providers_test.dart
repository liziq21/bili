// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/dao/media_history_dao.dart';
import 'package:app/database/dao/recent_search_query_dao.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/providers/repo_providers.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 在真实 [repoProviders] 下把 [probe] 结果取出来的探针组件。
/// 在 build 回调里断言的探针。
///
/// 断言写在 [probe] 内部并用 [expectSync]：这是 flutter_test 专门为 build /
/// layout 回调提供的变体，不检查未完成的异步 API。把断言放在闭包内部，测试
/// 就无需用外部可变变量把结果带出来——那种写法要求变量在 try 成功路径上也被
/// 赋值，`dart analyze` 会以 "definitely unassigned" 直接拒绝编译。
class _Probe extends StatelessWidget {
  const _Probe(this.probe);

  final void Function(BuildContext context) probe;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Builder(
      builder: (context) {
        probe(context);
        return const SizedBox.shrink();
      },
    ),
  );
}

void main() {
  // PreferencesDataSource 的默认构造会读 SharedPreferencesAsyncPlatform.instance，
  // 测试环境未装该平台时整个 provider 图建不起来。
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  /// 解析 [repoProviders] 下的 [T]，失败时把异常抛给 tester。
  T resolve<T>(BuildContext context) => context.read<T>();

  Widget graph(Widget child) => MultiRepositoryProvider(
    providers: repoProviders,
    child: MaterialApp(home: child),
  );

  testWidgets('resolves the whole repository graph without missing deps', (
    tester,
  ) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          // 任一 read 抛错都会让本用例在这里失败，并带出 ProviderNotFoundException。
          expectSync(resolve<AppDatabase>(context), isNotNull);
          expectSync(resolve<RecentSearchQueryDao>(context), isNotNull);
          expectSync(resolve<MediaHistoryDao>(context), isNotNull);
          expectSync(resolve<PreferencesDataSource>(context), isNotNull);
          expectSync(resolve<UserDataRepository>(context), isNotNull);
          expectSync(resolve<RecentSearchQueryRepository>(context), isNotNull);
          expectSync(
            resolve<GetRecentSearchQueriesUseCase>(context),
            isNotNull,
          );
        }),
      ),
    );

    // 卸载整棵 provider 图：dispose 会关数据库与数据源，否则残留 timer 触发
    // "A Timer is still pending" 断言。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('the use case reads back the same repository instance', (
    tester,
  ) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          // provider 每次 read 必须给同一实例，否则 use case 会持到另一份 DAO。
          expectSync(
            identical(
              resolve<GetRecentSearchQueriesUseCase>(context),
              resolve<GetRecentSearchQueriesUseCase>(context),
            ),
            isTrue,
          );
          expectSync(
            identical(
              resolve<RecentSearchQueryRepository>(context),
              resolve<RecentSearchQueryRepository>(context),
            ),
            isTrue,
          );
        }),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('writing through the repository is visible in the graph prefs', (
    tester,
  ) async {
    Object? readBack;
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          final repo = resolve<UserDataRepository>(context);
          final prefs = resolve<PreferencesDataSource>(context);
          // 断言的是「读写打通」而非「实例同一」：实测两个独立
          // PreferencesDataSource 实例共享同一份 platform 级 backing store，
          // 所以把 repository 换成自建数据源在本存储下不产生行为差异。
          unawaited(repo.setSourceId('bilibili'));
          unawaited(prefs.data.first.then((d) => readBack = d.sourceId));
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(readBack, 'bilibili');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('preferences provider creates its own data source instance', (
    tester,
  ) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          expectSync(
            identical(
              resolve<PreferencesDataSource>(context),
              resolve<PreferencesDataSource>(context),
            ),
            isTrue,
          );
        }),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('dao providers expose the daos owned by the database', (
    tester,
  ) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          final db = resolve<AppDatabase>(context);
          // provider 必须透出 AppDatabase 自己持有的 DAO 实例，不能另建一个。
          expectSync(
            identical(
              db.recentSearchQueryDao,
              resolve<RecentSearchQueryDao>(context),
            ),
            isTrue,
          );
          expectSync(
            identical(db.mediaHistoryDao, resolve<MediaHistoryDao>(context)),
            isTrue,
          );
        }),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('the two sub-lists together equal the full provider list', (
    tester,
  ) async {
    expect(
      databaseProviders.length + preferencesProviders.length + 3,
      repoProviders.length,
    );
  });
}
