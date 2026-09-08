import 'package:bpi/src/error/bpi_exception.dart';
import 'package:bpi/src/utils/wbi_utils.dart';
import 'package:test/test.dart';

void main() {
  const imgKey = '0123456789abcdef0123456789abcdef';
  const subKey = 'fedcba9876543210fedcba9876543210';

  test('uses the complete WBI permutation table', () {
    expect(
      WbiUtils.generateMixinKey(imgKey + subKey),
      '1022a87ffdaf532cb45ee953dce8c96d',
    );
  });

  test('signs a copy of the parameters', () {
    final params = <String, dynamic>{
      'keyword': "hello!'()*",
      'page': null,
      'w_rid': 'stale-signature',
      'wts': 1,
    };

    final signed = WbiUtils.encWbi(
      params,
      '1022a87ffdaf532cb45ee953dce8c96d',
      timestamp: 1702204169,
    );

    expect(params, {
      'keyword': "hello!'()*",
      'page': null,
      'w_rid': 'stale-signature',
      'wts': 1,
    });
    expect(signed['keyword'], "hello!'()*");
    expect(signed.containsKey('page'), isFalse);
    expect(signed['wts'], 1702204169);
    expect(signed['w_rid'], '2dc666fc9c54ab6569b18dbda63b33d1');
  });

  test('rejects a short combined key', () {
    expect(
      () => WbiUtils.generateMixinKey('too-short'),
      throwsA(isA<WbiException>()),
    );
  });
}
