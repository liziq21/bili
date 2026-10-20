import 'package:meta/meta.dart';

import '../model/paged_result.dart';

/// Loads one page of a playlist.
///
/// Passing a null [pageKey] requests the first page. Subsequent calls receive
/// the page number returned by the previous [Page].
typedef PlaylistPageLoader<T> = Future<Page<T>> Function({int? pageKey});

/// The result of fetching as much of a playlist as the remote source allowed.
@immutable
final class const FullPlaylistFetchResult<T>({
  /// The unique items fetched before completion or interruption.
  required final List<T> items,

  /// Whether all pages advertised by the source were fetched.
  required final bool completed,

  /// The page that can be used to resume after an interruption.
  required final int? nextPage,

  /// The error from the failed page, if fetching was interrupted.
  final Object? error,

  /// The stack trace captured with [error].
  final StackTrace? stackTrace,
}) {
  /// Whether the result contains a usable partial list.
  bool get isPartial => !completed;
}

/// Fetches every page of a playlist, preserving the order of first appearance.
///
/// The page loader is retried once after a failure. If the retry also fails,
/// this function returns the items already fetched instead of discarding them;
/// [FullPlaylistFetchResult.nextPage] identifies the interrupted page. A
/// caller may set [startPage] to that value to resume the operation.
///
/// Duplicate items are removed using [itemKey]. [pageDelay] is applied between
/// successful page requests, while [retryDelay] is applied before the single
/// retry. Both delays default to zero so callers and tests can opt into the
/// rate limit appropriate for their source.
Future<FullPlaylistFetchResult<T>> fetchFullPlaylist<T>({
  required PlaylistPageLoader<T> fetchPage,
  required Object Function(T item) itemKey,
  int startPage = 1,
  Duration pageDelay = Duration.zero,
  Duration retryDelay = Duration.zero,
}) async {
  if (startPage < 1) {
    throw ArgumentError.value(startPage, 'startPage', 'must be positive');
  }
  if (pageDelay.isNegative) {
    throw ArgumentError.value(pageDelay, 'pageDelay', 'must not be negative');
  }
  if (retryDelay.isNegative) {
    throw ArgumentError.value(retryDelay, 'retryDelay', 'must not be negative');
  }

  final items = <T>[];
  final seenKeys = <Object>{};
  final seenPages = <int>{};
  var pageKey = startPage == 1 ? null : startPage;
  var hasFetchedPage = false;

  while (true) {
    if (hasFetchedPage && pageDelay > Duration.zero) {
      await Future<void>.delayed(pageDelay);
    }

    Page<T>? page;
    Object? error;
    StackTrace? stackTrace;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        page = await fetchPage(pageKey: pageKey);
        break;
      } on Object catch (caughtError, caughtStackTrace) {
        error = caughtError;
        stackTrace = caughtStackTrace;
        if (attempt == 0 && retryDelay > Duration.zero) {
          await Future<void>.delayed(retryDelay);
        }
      }
    }

    if (page == null) {
      return FullPlaylistFetchResult(
        items: List.unmodifiable(items),
        completed: false,
        nextPage: pageKey ?? startPage,
        error: error ?? StateError('Playlist page could not be loaded'),
        stackTrace: stackTrace,
      );
    }

    if (page.number < 1 || page.totalPages < page.number) {
      return FullPlaylistFetchResult(
        items: List.unmodifiable(items),
        completed: false,
        nextPage: pageKey ?? startPage,
        error: StateError(
          'Invalid playlist page ${page.number}/${page.totalPages}',
        ),
        stackTrace: StackTrace.current,
      );
    }
    if (!seenPages.add(page.number)) {
      return FullPlaylistFetchResult(
        items: List.unmodifiable(items),
        completed: false,
        nextPage: pageKey ?? startPage,
        error: StateError('Playlist page ${page.number} was returned twice'),
        stackTrace: StackTrace.current,
      );
    }

    hasFetchedPage = true;
    for (final item in page.data) {
      if (seenKeys.add(itemKey(item))) {
        items.add(item);
      }
    }

    if (page.number >= page.totalPages) {
      return FullPlaylistFetchResult(
        items: List.unmodifiable(items),
        completed: true,
        nextPage: null,
      );
    }

    pageKey = page.number + 1;
  }
}
