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

  test('surfaces the -352 business code as a typed error', () {
    // 分类留给 converter：只有它同时看得到业务码和 HTTP 状态。这里保证 -352
    // 不会被当成成功信封继续解码。
    final result = ApiResult<Map<String, dynamic>>.fromJson({
      'code': -352,
      'message': '风控校验失败',
      'data': {'v_voucher': 'voucher-token'},
    }, decode);

    expect(result, isA<Error<Map<String, dynamic>>>());
    expect((result as Error<Map<String, dynamic>>).code, -352);
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

  test('reports a GAIA challenge as risk control, not a decode failure', () {
    // 风控挑战的信封也是 code: 0，data 里只有 v_voucher。按解码失败处理会把
    // 「请求被拦」说成「数据格式变了」，排查时找错方向。
    expect(
      () => ApiResult<Map<String, dynamic>>.fromJson({
        'code': 0,
        'message': '0',
        'data': {'v_voucher': 'voucher-token'},
      }, decode),
      throwsA(isA<BiliRiskControlException>()),
    );
  });

  test('decodes data that carries a v_voucher next to real results', () {
    final result = ApiResult<Map<String, dynamic>>.fromJson({
      'code': 0,
      'message': '0',
      'data': {
        'v_voucher': 'voucher-token',
        'result': {'value': 1},
      },
    }, decode);

    expect(result, isA<Ok<Map<String, dynamic>>>());
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
