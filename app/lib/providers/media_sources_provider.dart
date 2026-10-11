import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:youtube/youtube.dart';

/// Configures the clients used by subsequently created source instances.
void configureMediaSourceClients({
  required http.Client biliClient,
  required http.Client youtubeClient,
}) {
  Bili.client = biliClient;
  YouTube.client = youtubeClient;
}

/// A description of a source that can be created for a route scope.
///
/// This is deliberately not a live [MediaSource]. Keeping factories in the
/// catalog prevents the application root from creating network clients that
/// it does not own and makes an empty catalog a valid application state.
@immutable
class const MediaSourceDefinition({
  required final String id,
  required final String name,
  required final MediaSource Function() create,
}) extends Equatable {
  @override
  List<Object?> get props => [id, name, create];
}

/// The application-owned catalog of available media sources.
///
/// Concrete source packages are imported only by this composition-root file.
/// The rest of the app consumes this catalog and the abstract [MediaSource]
/// capability interfaces.
@immutable
class MediaSourceCatalog(Iterable<MediaSourceDefinition> definitions)
    extends Equatable {
  this : definitions = List.unmodifiable(definitions) {
    final ids = <String>{};
    for (final definition in this.definitions) {
      if (definition.id.isEmpty ||
          definition.id != normalizeMediaSourceId(definition.id) ||
          !ids.add(definition.id)) {
        throw ArgumentError.value(definition.id, 'id', 'Invalid source ID');
      }
    }
  }

  final List<MediaSourceDefinition> definitions;

  @override
  List<Object?> get props => [definitions];
  MediaSourceDefinition? find(String sourceId) {
    final normalized = normalizeMediaSourceId(sourceId);
    for (final definition in definitions) {
      if (definition.id == normalized) return definition;
    }
    return null;
  }

  /// Resolves a persisted selection. Stale values fall back to the first
  /// definition; an empty catalog returns null instead of a sentinel ID.
  MediaSourceDefinition? resolvePersisted(String? persistedSourceId) {
    if (persistedSourceId != null) {
      final persisted = find(persistedSourceId);
      if (persisted != null) return persisted;
    }
    return definitions.isEmpty ? null : definitions.first;
  }
}

/// Canonical source IDs are trimmed and lower-case at every external boundary.
String normalizeMediaSourceId(String sourceId) => sourceId.trim().toLowerCase();

/// The service localization delegates used by the application shell.
const sourceLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  BilibiliLocalizations.delegate,
  YoutubeLocalizations.delegate,
];

/// Default source factories; each route scope owns its created instance.
final defaultMediaSourceCatalog = MediaSourceCatalog([
  MediaSourceDefinition(id: 'bilibili', name: 'Bilibili', create: Bili.new),
  MediaSourceDefinition(id: 'youtube', name: 'YouTube', create: YouTube.new),
]);

/// Convenience access to the immutable source catalog registered in context.
extension MediaSourceCatalogContextX on BuildContext {
  MediaSourceCatalog get mediaSourceCatalog => watch<MediaSourceCatalog>();

  /// The source definitions available for selectors and labels.
  List<MediaSourceDefinition> get mediaSourceDefinitions =>
      mediaSourceCatalog.definitions;
}
