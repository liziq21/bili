import 'package:app/providers/service_source_providers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
}
