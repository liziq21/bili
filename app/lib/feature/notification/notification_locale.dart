import 'dart:ui' show Locale, PlatformDispatcher;

import '../../l10n/localization_file/app_localizations.dart';

/// 通知文案与界面同语言。
///
/// 通知在 UI 之外发出，拿不到 `BuildContext`，所以按系统语言解析。规则与
/// `MaterialApp.localeResolutionCallback` 一致：只比语言码，不支持的语言
/// 回落到第一项，即 `zh`（见 `app.dart` 的 `supportedLocales`）。
AppLocalizations resolveNotificationLocalizations() => lookupAppLocalizations(
  switch (PlatformDispatcher.instance.locale.languageCode) {
    'en' => const Locale('en'),
    _ => const Locale('zh'),
  },
);
