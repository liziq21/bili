import 'package:app/l10n/compact_count.dart';
import 'package:app/l10n/localization_file/app_localizations_en.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCompactCount', () {
    final en = AppLocalizationsEn();
    final zh = AppLocalizationsZh();

    test('English uses K/M/B at 10^3/10^6/10^9', () {
      expect(formatCompactCount(999, en), '999');
      expect(formatCompactCount(1000, en), '1.0K');
      expect(formatCompactCount(15500, en), '15.5K');
      expect(formatCompactCount(20970000, en), '21.0M');
      expect(formatCompactCount(2100000000, en), '2.1B');
    });

    test('Chinese uses 万/亿/万亿 at 10^4/10^8/10^12', () {
      expect(formatCompactCount(9999, zh), '9999');
      expect(formatCompactCount(10000, zh), '1.0万');
      expect(formatCompactCount(155000, zh), '15.5万');
      expect(formatCompactCount(20972000, zh), '2097.2万');
      expect(formatCompactCount(210000000, zh), '2.1亿');
      expect(formatCompactCount(1000000000000, zh), '1.0万亿');
    });
  });
}
