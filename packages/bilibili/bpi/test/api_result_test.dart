import 'package:bpi/src/error/bpi_exception.dart';
import 'package:bpi/src/model/api_result.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> decode(Map<String, dynamic> json) =>
      Map<String, dynamic>.from(json);

  test('accepts a numeric success code and data', () {
    final result = ApiResult<Map<String, dynamic>>.fromJson({
      'code': 0,
      'message': '0',
      'data': {'value': 42},
    }, decode);

    expect(result, isA<Ok<Map<String, dynamic>>>());
    expect((result as Ok<Map<String, dynamic>>).data['value'], 42);
  });

  test('accepts a string success code and result', () {
    final result = ApiResult<Map<String, dynamic>>.fromJson({
      'code': '0',
      'message': '0',
      'result': {'value': 7},
    }, decode);

    expect((result as Ok<Map<String, dynamic>>).data['value'], 7);
  });

  test('returns a typed API error for a non-zero code', () {
    final result = ApiResult<Map<String, dynamic>>.fromJson({
      'code': -101,
      'message': '账号未登录',
    }, decode);

    expect(result, isA<Error<Map<String, dynamic>>>());
    expect((result as Error<Map<String, dynamic>>).code, -101);
  });

  test('rejects successful responses without object data', () {
    expect(
      () => ApiResult<Map<String, dynamic>>.fromJson({
        'code': 0,
        'message': '0',
        'data': null,
      }, decode),
      throwsA(isA<BpiSerializationException>()),
    );
  });

  test('rejects responses without a numeric code', () {
    expect(
      () => ApiResult<Map<String, dynamic>>.fromJson({
        'message': 'bad response',
      }, decode),
      throwsA(isA<BpiSerializationException>()),
    );
  });
}
