import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 值是格式化串（分隔符、单位后缀、纯占位符拼接），两种语言下刻意相同。
///
/// 名单里的 key 必须真的两侧同值，否则说明翻译已经落地，条目该删掉——
/// 由 `the locale-neutral allow-list has no stale entries` 执行。
const localeNeutralKeys = {
  'playerQualityHeight', // {p1}P：画质高度标记，不含自然语言
  'spacedDot', // " · "：分隔符
  'spacedBullet', // " • "：分隔符
  'dotSeparator', // "·"：分隔符
};

/// 文案只有在两种语言下真的不同，翻译缺失才可见。
///
/// `hardcoded_copy_test.dart` 保证用户可见文案都来自 ARB，但不检查 ARB 里
/// 的中文是否仍是英文原样。2026-11-23 的 en 模板混入中文与 2026-11-24 的
/// zh 侧 3 个 key 未翻译（#590 / #630）都属于「两侧同值」这一类，任何
/// widget 测试都拦不住。这里从数据层兜住。
void main() {
  final en = _readArb('lib/l10n/app_.arb');
  final zh = _readArb('lib/l10n/app_zh.arb');

  group('localization contract', () {
    test('both ARB files declare the same key set', () {
      // Given the English template and the Chinese translation.
      // Then neither side carries a key the other lacks, @meta included.
      expect(zh.keys.toSet(), en.keys.toSet());
    });

    test('every translated value differs from the English template', () {
      // Given the English template values.
      final untranslated = <String, String>{};
      for (final entry in en.entries) {
        final value = entry.value;
        if (entry.key.startsWith('@') || value is! String) continue;
        if (zh[entry.key] != value) continue;
        if (localeNeutralKeys.contains(entry.key)) continue;
        untranslated[entry.key] = value;
      }

      // Then no untranslated value slips through.
      expect(
        untranslated,
        isEmpty,
        reason:
            'app_zh.arb still repeats the English template for these keys. '
            'Translate them, or add the key to localeNeutralKeys when the '
            'value is a format string that must stay identical:\n'
            '${untranslated.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
      );
    });

    test('the locale-neutral allow-list has no stale entries', () {
      // Given the allow-list.
      final missing = [
        for (final key in localeNeutralKeys)
          if (!en.containsKey(key) || !zh.containsKey(key)) key,
      ];
      final stale = [
        for (final key in localeNeutralKeys)
          if (en[key] != zh[key]) key,
      ];

      // Then every entry still exists on both sides and is still identical.
      expect(
        missing,
        isEmpty,
        reason:
            'These keys are gone from the ARB files, so drop them from '
            'localeNeutralKeys: ${missing.join(', ')}',
      );
      expect(
        stale,
        isEmpty,
        reason:
            'These keys are translated now, so drop them from '
            'localeNeutralKeys: ${stale.join(', ')}',
      );
    });

    test('lib sources never fall back to hardcoded copy', () {
      // Given the hand-written app sources.
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (path.startsWith('lib/l10n/localization_file')) continue;
        final source = entity.readAsStringSync();
        if (_fallbackPattern.hasMatch(source)) offenders.add(path);
      }

      // Then every lookup is non-nullable, so a missing delegate throws
      // instead of silently rendering a hardcoded language.
      expect(
        offenders,
        isEmpty,
        reason:
            'AppLocalizations.of(context) must be non-nullable: a `??` '
            'fallback turns a missing Localizations delegate or an '
            'unresolved locale into silently rendered copy in the wrong '
            'language. Use AppLocalizations.of(context)! and let the wiring '
            'failure surface. Files:\n  ${offenders.join('\n  ')}',
      );
    });
  });
}

/// Matches `AppLocalizations.of(anything)?` and `?? AppLocalizationsZh()`.
final _fallbackPattern = RegExp(
  r'AppLocalizations\.of\([^)]*\)\s*\?'
  r'|\?\?\s*AppLocalizationsZh\(',
);

Map<String, dynamic> _readArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
