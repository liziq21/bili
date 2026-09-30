import 'package:app/datastore/preferences_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySharedPreferencesAsync inMemory;
  late PreferencesDataSource ds;

  setUp(() {
    inMemory = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = inMemory;
    ds = PreferencesDataSource(sharedPreferences: SharedPreferencesAsync());
  });

  test('PreferencesKey<String?> 读取未存储值时返回 null', () async {
    final Result<String?> result = await ds.get(PreferencesKey.sourceId);

    expect(result.isOk, true);
    expect((result as Ok<String?>).value, isNull);
  });

  test('PreferencesKey<String?> 写入后读回', () async {
    await ds.set(PreferencesKey.sourceId, 'bilibili');

    final Result<String?> result = await ds.get(PreferencesKey.sourceId);
    expect(result.isOk, true);
    expect((result as Ok<String?>).value, 'bilibili');
  });
}
