import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeData;

/// The font family golden tests render with.
///
/// The production app bundles no font: `pubspec.yaml` declares no `fonts:`
/// block and the repository holds no font asset, so `material_ui`'s
/// `ThemeData` resolves its `fontFamily: 'Roboto'` to nothing and the engine
/// falls back. Under `flutter test` that fallback is Ahem, which draws every
/// glyph as a solid 1em box. A golden recorded that way cannot tell a
/// two-character title from a forty-character one — both occupy the same
/// width — so clipped text and bad line wrapping are invisible to it.
///
/// The subset in `test/fonts/` replaces that fallback for golden rendering
/// only. It is loaded through [FontLoader] rather than a `fonts:` block so
/// the asset stays out of the app bundle: production pixels and APK size are
/// untouched.
const String goldenFontFamily = 'BiliGoldenSubset';

/// Path to the subset, relative to the `app/` package root.
const String _fontPath = 'test/fonts/NotoSansSC-golden-subset.otf';

/// Loads [goldenFontFamily] into the test engine.
///
/// Returns without doing anything if the family is already registered, so
/// every golden test can call it unconditionally.
///
/// The bytes are read with [File.readAsBytes] rather than `rootBundle` because
/// the subset is not declared as a Flutter asset — `rootBundle` cannot see
/// files that no `pubspec.yaml` block lists. That is the same reason the font
/// does not reach production.
Future<void> loadGoldenFont() async {
  if (_loaded) return;
  final file = File(_fontPath);
  if (!file.existsSync()) {
    throw StateError(
      'Golden font subset missing at $_fontPath. It is generated from '
      'Noto Sans CJK SC and committed to the repository; without it every '
      'golden renders as Ahem boxes and stops detecting text layout.',
    );
  }
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(goldenFontFamily)
    ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  await loader.load();
  _loaded = true;
}

bool _loaded = false;

/// Returns a [ThemeData] that renders text with [goldenFontFamily].
///
/// Pass it to the `theme:` of the `material_ui` `MaterialApp` that wraps a
/// golden scenario — not to a `Theme` above that `MaterialApp`. A probe
/// (`test/probe/`, run 2026-09-29) measured both: an outer `Theme` leaves
/// `Theme.of(context).textTheme.bodyMedium.fontFamily` at `'Roboto'`, because
/// `material_ui`'s `MaterialApp` builds its own `ThemeData` nearer to the
/// text and shadows it. Handing the family to that `MaterialApp` directly
/// resolves to `BiliGoldenSubset`.
///
/// The result is otherwise the stock light [ThemeData], so the only difference
/// from the previous golden runs is the typeface.
ThemeData goldenTestTheme() => ThemeData(fontFamily: goldenFontFamily);
