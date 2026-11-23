import 'package:meta/meta.dart';

import 'mapping_descriptor.dart';
import 'mapping_descriptor_validator.dart';

enum SourceHttpMethod() {
  get,
  post,
}

enum SourceAuthKind() {
  none,
  apiKeyHeader,
  apiKeyQuery,
  bearerToken,
  oauth,
  customSignature,
}

enum SourcePaginationKind() {
  none,
  pageNumber,
  hasMore,
  totalCount,
  continuationToken,
}

/// Transport-level authentication metadata for one source.
///
/// The descriptor never stores a credential; [tokenEnvironmentVariable] names
/// where a runtime adapter reads it.
@immutable
final class const SourceAuthDescriptor({
  final SourceAuthKind kind = SourceAuthKind.none,
  final String? headerName,
  final String? queryParameter,
  final String? tokenEnvironmentVariable,
});

/// Transport-level pagination metadata for one source.
@immutable
final class const SourcePaginationDescriptor({
  final SourcePaginationKind kind = SourcePaginationKind.none,
  final String? pageParameter,
  final String? pageSizeParameter,
  final int? defaultPageSize,
  final String? cursorParameter,
});

@immutable
final class const SourceRateLimitDescriptor({
  final int? requestsPerMinute,
  final int? burst,
});

/// Describes a source's transport and, optionally, its item mapping.
///
/// [FeedMappingDescriptor] owns item → canonical field rules. This type owns
/// the surrounding contract: endpoint, method, auth, pagination, rate limits,
/// and whether a Dart adapter is still required for signing or media handling.
@immutable
final class const SourceDescriptor({
  required final String id,
  required final String displayName,
  required final String endpoint,
  final SourceHttpMethod method = SourceHttpMethod.get,
  final SourceAuthDescriptor auth = const SourceAuthDescriptor(),
  final SourcePaginationDescriptor pagination =
      const SourcePaginationDescriptor(),
  final SourceRateLimitDescriptor? rateLimit,
  final FeedMappingDescriptor? mapping,
  final bool requiresDartAdapter = false,
  final String? notes,
});

/// Checks transport metadata and, when present, the nested mapping.
List<String> validateSourceDescriptor(
  SourceDescriptor source, {
  required Set<String> requiredFields,
}) {
  final issues = <String>[];

  if (source.id.trim().isEmpty) {
    issues.add('source.id must not be empty');
  }
  if (source.displayName.trim().isEmpty) {
    issues.add('source.displayName must not be empty');
  }
  if (!source.endpoint.startsWith('https://')) {
    issues.add('source.endpoint must use https');
  }

  _validateAuth(source, issues);
  _validatePagination(source, issues);

  final rateLimit = source.rateLimit;
  if (rateLimit != null) {
    if (rateLimit.requestsPerMinute != null &&
        rateLimit.requestsPerMinute! <= 0) {
      issues.add('rateLimit.requestsPerMinute must be positive');
    }
    if (rateLimit.burst != null && rateLimit.burst! <= 0) {
      issues.add('rateLimit.burst must be positive');
    }
  }

  final mapping = source.mapping;
  if (mapping != null) {
    issues.addAll(
      validateFeedMappingDescriptor(mapping, requiredFields: requiredFields),
    );
  }

  return issues;
}

void _validateAuth(SourceDescriptor source, List<String> issues) {
  final auth = source.auth;
  switch (auth.kind) {
    case SourceAuthKind.none:
      if (auth.headerName != null ||
          auth.queryParameter != null ||
          auth.tokenEnvironmentVariable != null) {
        issues.add('auth.none must not set header/query/token fields');
      }
    case SourceAuthKind.apiKeyHeader:
      if (auth.headerName == null || auth.headerName!.trim().isEmpty) {
        issues.add('auth.apiKeyHeader requires headerName');
      }
    case SourceAuthKind.apiKeyQuery:
      if (auth.queryParameter == null || auth.queryParameter!.trim().isEmpty) {
        issues.add('auth.apiKeyQuery requires queryParameter');
      }
    case SourceAuthKind.bearerToken || SourceAuthKind.oauth:
      if (auth.tokenEnvironmentVariable == null ||
          auth.tokenEnvironmentVariable!.trim().isEmpty) {
        issues.add('auth.${auth.kind.name} requires tokenEnvironmentVariable');
      }
    case SourceAuthKind.customSignature:
      if (!source.requiresDartAdapter) {
        issues.add('auth.customSignature requires requiresDartAdapter');
      }
  }

  final env = auth.tokenEnvironmentVariable;
  if (env != null && !RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(env)) {
    issues.add('auth.tokenEnvironmentVariable must be an env var name');
  }
}

void _validatePagination(SourceDescriptor source, List<String> issues) {
  final pagination = source.pagination;
  final mapping = source.mapping;
  if (pagination.defaultPageSize != null && pagination.defaultPageSize! <= 0) {
    issues.add('pagination.defaultPageSize must be positive');
  }
  switch (pagination.kind) {
    case SourcePaginationKind.none:
      return;
    case SourcePaginationKind.pageNumber:
      if (pagination.pageParameter == null ||
          pagination.pageParameter!.trim().isEmpty) {
        issues.add('pagination.pageNumber requires pageParameter');
      }
    case SourcePaginationKind.hasMore:
      if (mapping != null && mapping.hasMorePath == null) {
        issues.add('pagination.hasMore requires mapping.hasMorePath');
      }
    case SourcePaginationKind.totalCount:
      if (mapping != null &&
          (mapping.totalCountPath == null || mapping.pageSize == null)) {
        issues.add(
          'pagination.totalCount requires mapping.totalCountPath and pageSize',
        );
      }
    case SourcePaginationKind.continuationToken:
      if (pagination.cursorParameter == null ||
          pagination.cursorParameter!.trim().isEmpty) {
        issues.add('pagination.continuationToken requires cursorParameter');
      }
      if (mapping != null && mapping.continuationTokenPath == null) {
        issues.add(
          'pagination.continuationToken requires '
          'mapping.continuationTokenPath',
        );
      }
  }
}
