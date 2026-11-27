import 'localization_file/app_localizations.dart';

/// Formats [count] with the compact magnitude unit of [l10n]'s locale.
///
/// English steps at 10^3 / 10^6 / 10^9 (K/M/B); Chinese steps at
/// 10^4 / 10^8 / 10^12 (万/亿/万亿). The divisor is chosen here because an ARB
/// message carries the suffix but cannot scale the value it interpolates.
String formatCompactCount(int count, AppLocalizations l10n) {
  final (kilo, mega, giga) = l10n.localeName.startsWith('zh')
      ? (10000, 100000000, 1000000000000)
      : (1000, 1000000, 1000000000);
  if (count >= giga) {
    return l10n.countCompactGiga(_scaled(count, giga));
  }
  if (count >= mega) {
    final scaled = _scaled(count, mega);
    if (_roundsToNextUnit(scaled, mega ~/ kilo)) {
      return l10n.countCompactGiga(_scaled(count, giga));
    }
    return l10n.countCompactMega(scaled);
  }
  if (count >= kilo) {
    final scaled = _scaled(count, kilo);
    if (_roundsToNextUnit(scaled, mega ~/ kilo)) {
      return l10n.countCompactMega(_scaled(count, mega));
    }
    return l10n.countCompactKilo(scaled);
  }
  return '$count';
}

String _scaled(int count, int divisor) => (count / divisor).toStringAsFixed(1);

// 999,950 rounds to "1000.0K"; promote it so the unit never overflows.
bool _roundsToNextUnit(String scaled, int unitsPerTier) =>
    double.parse(scaled) >= unitsPerTier;
