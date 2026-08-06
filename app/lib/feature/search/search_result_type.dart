import 'package:app/l10n/localization_file/app_localizations.dart';

enum SearchResultType {
  all,
  video;

  String label(AppLocalizations l10n) => switch (this) {
    .all => l10n.searchResultTypeAll,
    .video => l10n.searchResultTypeVideo,
  };
}
