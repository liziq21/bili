import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repository/app_search_suggest_repository.dart';
import '../data/repository/search/app_creator_profile_search_repository.dart';
import '../data/repository/search/app_live_room_search_repository.dart';
import '../data/repository/search/app_video_search_repository.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';
import '../data/repository/video_comment_repository.dart';
import '../data/repository/video_detail_repository.dart';
import 'media_sources_provider.dart';

/// Injects one route-scoped [MediaSource] and the repositories for its
/// optional capabilities.
///
/// The source catalog owns factories; this widget owns the instance returned
/// by the selected factory. Concrete source packages never appear in this
/// file. Repository injection is driven by the nullable capability interfaces
/// exposed by [MediaSource], not by source-ID switches.
class const ServiceSourceProviders({
  super.key,
  required final String source,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (source != normalizeMediaSourceId(source)) {
      throw ArgumentError.value(
        source,
        'source',
        'Source ID must be canonical',
      );
    }
    final definition = context.watch<MediaSourceCatalog>().find(source);
    if (definition == null) {
      throw ArgumentError.value(source, 'source', 'Unknown source ID');
    }
    // New routes are siblings under a Navigator, not nested source scopes.
    // Reject nesting rather than inheriting another source's missing capability.
    if (context.read<MediaSource?>() != null) {
      throw StateError('Source scopes must not be nested');
    }
    return _SourceScope(
      key: ValueKey(definition.id),
      definition: definition,
      child: child,
    );
  }
}

class const _SourceScope({
  super.key,
  required final MediaSourceDefinition definition,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_SourceScope> createState() => _SourceScopeState();
}

class _SourceScopeState() extends State<_SourceScope> {
  MediaSource? _ownedSource;
  late final List<SingleChildWidget> _providers;
  final _log = Logger('ServiceSourceProviders');

  @override
  void initState() {
    super.initState();
    final mediaSource = widget.definition.create();
    _ownedSource = mediaSource;
    try {
      if (mediaSource.id != widget.definition.id) {
        throw StateError('Source factory returned a mismatched ID');
      }
      _providers = _buildProviders(mediaSource);
    } catch (_) {
      _closeSource();
      rethrow;
    }
  }

  void _closeSource() {
    final source = _ownedSource;
    _ownedSource = null;
    if (source != null) {
      unawaited(
        Future<void>.sync(source.close)
            .catchError((Object error, StackTrace stackTrace) {
              _log.warning(
                'Failed to close source ${source.id}',
                error,
                stackTrace,
              );
            }),
      );
    }
  }

  @override
  void dispose() {
    _closeSource();
    super.dispose();
  }

  List<SingleChildWidget> _buildProviders(MediaSource source) => [
    // State owns this instance even when no descendant reads the provider.
    RepositoryProvider<MediaSource>.value(value: source),
    RepositoryProvider<MediaSourceDefinition>.value(value: widget.definition),
    if (source.videoSearchDataSource case final videoSearchDataSource?)
      RepositoryProvider<VideoSearchRepository>(
        create: (_) => AppVideoSearchRepository(videoSearchDataSource),
      ),
    if (source.creatorProfileSearchDataSource
        case final creatorProfileSearchDataSource?)
      RepositoryProvider<CreatorProfileSearchRepository>(
        create: (_) =>
            AppCreatorProfileSearchRepository(creatorProfileSearchDataSource),
      ),
    if (source.searchSuggestDataSource case final searchSuggestDataSource?)
      RepositoryProvider<SearchSuggestRepository>(
        create: (_) => AppSearchSuggestRepository(searchSuggestDataSource),
      ),
    if (source.liveRoomSearchDataSource case final liveRoomSearchDataSource?)
      RepositoryProvider<LiveRoomSearchRepository>(
        create: (_) => AppLiveRoomSearchRepository(liveRoomSearchDataSource),
      ),
    if (source.videoDetailDataSource case final videoDetailDataSource?)
      RepositoryProvider<VideoDetailRepository>(
        create: (_) => AppVideoDetailRepository(
          videoDetailDataSource,
          source.mediaStreamDataSource,
        ),
      ),
    if (source.videoCommentDataSource case final videoCommentDataSource?)
      RepositoryProvider<VideoCommentRepository>(
        create: (_) => AppVideoCommentRepository(videoCommentDataSource),
      ),
  ];

  @override
  Widget build(BuildContext context) =>
      MultiRepositoryProvider(providers: _providers, child: widget.child);
}
