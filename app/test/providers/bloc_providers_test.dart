// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

import 'package:app/app_bloc.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/providers/bloc_providers.dart';
import 'package:app/providers/repo_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart'
    show InMemorySharedPreferencesAsync;
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart'
    show SharedPreferencesAsyncPlatform;

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
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  T resolve<T>(BuildContext context) => context.read<T>();

  Widget graph(Widget child) => MultiRepositoryProvider(
    providers: repoProviders,
    child: Builder(
      builder: (context) => MultiBlocProvider(
        providers: getBlocProviders(context),
        child: MaterialApp(home: child),
      ),
    ),
  );

  testWidgets('getBlocProviders registers AppBloc', (tester) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          expectSync(resolve<AppBloc>(context), isNotNull);
          expectSync(resolve<UserDataRepository>(context), isNotNull);
        }),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('AppBloc is created with the repository from the graph', (
    tester,
  ) async {
    await tester.pumpWidget(
      graph(
        _Probe((context) {
          final bloc = resolve<AppBloc>(context);
          expectSync(bloc, isNotNull);
        }),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
