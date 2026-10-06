# Sentinel Security Journal

## 2026-09-16 - Enforce TLS/SSL Certificate Validation in HttpIOClient

Vulnerability: `badCertificateCallback = (_, _, _) => true` was hardcoded on the primary `HttpClient` / `http.IOClient` in `app/lib/main.dart`, bypassing all TLS/SSL certificate verification for Bilibili API requests.
Learning: Debug proxy setups (e.g. Charles/Burp) often introduce local certificate overrides that can easily leak into application code if not stripped before committing or guarded strictly behind debug environments.
Prevention: Never hardcode `badCertificateCallback` overrides returning `true` in shared client initialization. Enforce standard platform certificate validation across all build targets.

## 2026-09-17 - Restrict DebugOverlay and HttpLogClient to Debug Environments

Vulnerability: `DebugOverlay.enabled = true` and `HttpLogClient(App.httpBucket, ...)` were hardcoded unconditionally in `app/lib/main.dart`, capturing sensitive network request/response traffic and runtime logs into memory buckets and exposing the debug overlay in production release builds.
Learning: Debug overlays and HTTP logging interceptors must be guarded strictly by release mode checks (`kReleaseMode`), as un-guarded debug tools expose HTTP headers, response payloads, and internal log traces to end-users or background screen captures in release builds.
Prevention: Always verify `DebugOverlay.enabled = false` and use standard un-intercepted network clients in `kReleaseMode`.

## 2026-09-18 - Sanitize and Mask User-Facing UI Exception Outputs

Vulnerability: Raw `${state.error}` string interpolations were directly rendered in user-facing UI components (`VideoInfoView`, `VideoCommentsView`, and `App`), exposing internal system exception messages, database paths, or network stack traces to end users.
Learning: Displaying unformatted or raw exception strings in UI widgets leaks sensitive internal application state, database file locations, or network error details in release builds.
Prevention: Always replace raw `${state.error}` UI interpolations with localized, generic error messages (e.g., `'视频加载失败，请重试'`) and confine detailed exception logs to internal logging frameworks.

## 2026-09-19 - Restrict Router Diagnostic Logs in Release Builds

Vulnerability: `debugLogDiagnostics: true` was hardcoded in `GoRouter` configuration (`app/lib/routing/router.dart`), outputting all internal navigation state transitions, route paths, deep-link queries, and UI parameters to system logs.
Learning: Un-guarded router diagnostic logging prints route parameters and state paths to platform-level system logs (e.g., Logcat / os_log) in production release builds, exposing user navigation patterns and parameter payloads.
Prevention: Always gate router diagnostic logging with `!kReleaseMode` (or `kDebugMode`) from `package:flutter/foundation.dart`.

## 2026-09-20 - Sanitize HTML Markup in Search Titles and Handle Null Values Safely

Vulnerability: `HtmlTitle.fromJson` converted raw dynamic JSON strings without null guards or defensive HTML tag stripping, potentially leading to null type errors or rendering unparsed HTML/XSS markup in UI text components.
Learning: Search API results from external endpoints (like Bilibili) embed raw HTML formatting tags (`<em class="keyword">`) and require robust tag stripping and null handling during deserialization.
Prevention: Always sanitize untrusted HTML string payloads during JSON deserialization and provide fallback regex stripping and null-coalescing.

## 2026-09-21 - Sanitize Control Characters and Enforce Length Limits on Search Queries in Local Storage

Vulnerability: Unbounded user search input in `RecentSearchQueryDao.insertOrReplaceRecentSearch` stored raw queries directly into SQLite without character sanitization or length limits, allowing potential application DoS via memory/storage exhaustion or control-character rendering corruption.
Learning: Local database queries sourced from user input (e.g. search bars) must be constrained and sanitized before storage to prevent excessive memory allocations and UI lag during retrieval.
Prevention: Strip non-printable control characters (`[\x00-\x1F\x7F]`) and enforce strict length limits (e.g. 200 characters) in local storage DAOs.

## 2026-09-22 - Enforce Static YouTube HTTP Client Configuration Parity with Bilibili Media Source

Vulnerability: `YouTube` facade class created un-monitored default `http.Client()` instances when instantiated without explicit parameters, ignoring `initDebugOverlayBridge` static HTTP client policy configuration in `app/lib/main.dart` and bypassing network logging isolation and release/debug client policies.
Learning: Media source facades in modular architectures must support static client properties (`YouTube.client`) to ensure global HTTP client policies (such as debug log buckets or release IO clients) apply uniformly across all data sources.
Prevention: Always expose static `client` configuration fields on media source wrappers and default `httpClient ?? client` during service initialization.

## 2026-09-23 - Mask Deep-Link Query Parameters and Sanitize Control Characters on 404 NotFound UI

Vulnerability: Unhandled or invalid deep-link URIs (e.g., `bili://auth/callback?token=secret123`) passed to `NotFoundScreen` rendered raw query parameters in cleartext UI text, exposing sensitive session tokens or authentication credentials to end users and screen captures.
Learning: Navigation 404/error screens displaying raw state URIs or deep-link routes can inadvertently expose sensitive authentication query parameters or crash UI text rendering due to non-printable control characters.
Prevention: Always mask query parameter values (e.g., replacing values with `'REDACTED'`) and strip control characters (`[\x00-\x1F\x7F]`) when formatting URI representations for user-facing error views.

## 2026-09-24 - Sanitize Control Characters and Encode Query Components in Referer Headers

Vulnerability: `ApiInterceptor` constructed `HttpHeaders.refererHeader` using `Uri.encodeFull(keyword)`, which failed to escape URL query delimiters (`#`, `&`, `?`, `=`) and allowed non-printable control characters (`\r\n`) to pass into HTTP headers, creating risk of CRLF header injection and Referer parameter corruption.
Learning: `Uri.encodeFull` is meant for full URIs and leaves reserved query characters intact. Constructing custom HTTP query strings for headers requires query component encoding (`Uri.encodeQueryComponent`) and control character stripping (`[\x00-\x1F\x7F]`).
Prevention: Always use `Uri.encodeQueryComponent` for query parameter values in HTTP headers and sanitize control characters to prevent header splitting or injection.

## 2026-09-25 - Sanitize Control Characters in YouTube Service Search Queries

Vulnerability: `YoutubeService` passed raw search `query` parameters containing non-printable control characters (`\r\n`, `\x00`, `\x1f`) directly into HTTP GET query parameters and POST request body payloads, exposing outgoing YouTube/Google Suggest API requests to CRLF query injection and server request errors.
Learning: Unsanitized search inputs sourced from user text fields or deep-link params can leak control characters into HTTP query strings and REST API bodies.
Prevention: Strip non-printable ASCII control characters (`[\x00-\x1F\x7F]`) from search query parameters in API services before executing outgoing network requests.

## 2026-09-26 - Sanitize Control Characters in Query Inputs and HTML Tags in Bilibili Search Suggestions

Vulnerability: `BiliSearchSuggestRemoteDataSource.getSuggests` passed raw `query` strings containing non-printable ASCII control characters (`\r\n`, `\x00`, `\x1f`) directly to the Bilibili suggest endpoint, and returned unsanitized search suggestion terms containing raw HTML tags (`<em class="keyword">`) and control characters directly to the UI layer.
Learning: Search suggest endpoints accept user inputs and return server-formatted strings that may contain control characters and embedded HTML markup, requiring sanitization at the remote data source boundary.
Prevention: Strip non-printable ASCII control characters (`[\x00-\x1F\x7F]`) from incoming search queries and strip HTML markup (`<[^>]*>`) and control characters from returned search suggest terms.

## 2026-09-27 - Sanitize Control Characters in YouTube Remote Data Source Search Queries

Vulnerability: `YouTubeVideoSearchRemoteDataSource` and `YouTubeCreatorProfileSearchRemoteDataSource` passed raw search queries containing non-printable ASCII control characters (`\r\n`, `\x00`, `\x1f`) directly to InnerTube remote API services and continuation token cache keys, causing unnecessary API requests on whitespace/control-character-only inputs.
Learning: Remote data sources must strip control characters and return an empty `Page` immediately for blank or control-character-only queries to avoid redundant API network traffic and query injection risk.
Prevention: Always sanitize control characters (`[\x00-\x1F\x7F]`) and trim search query strings before building continuation keys or invoking API services.

## 2026-09-28 - Sanitize Control Characters in Bilibili Search Remote Data Sources

Vulnerability: Bilibili search remote data sources (`BiliVideoSearchRemoteDataSource`, `BiliCreatorProfileSearchRemoteDataSource`, `BiliLiveRoomSearchRemoteDataSource`, and `BiliAggregateSearchRemoteDataSource`) passed raw search `query` parameters containing non-printable control characters (`\r\n`, `\x00`, `\x1F`, `\x7F`) directly to network API services, and executed remote network calls for empty or whitespace-only search queries.
Learning: Remote search data sources must strip non-printable ASCII control characters and return empty `Page` or `AggregateSearchPage` results immediately for blank or control-character-only search inputs to prevent CRLF query injection and redundant network requests.
Prevention: Strip non-printable ASCII control characters (`[\x00-\x1F\x7F]`) and short-circuit empty queries with an empty result `Page` before calling backend search APIs.

## 2026-09-29 - Sanitize Control Characters and Validate Video IDs in Bilibili Remote Data Sources

Vulnerability: `BiliVideoDetailRemoteDataSource`, `BiliVideoCommentRemoteDataSource`, and `BiliMediaStreamRemoteDataSource` passed raw `videoId` / `id` parameters containing non-printable ASCII control characters (`\r\n`, `\x00`, `\x1f`, `\x7f`) or empty strings directly to Bilibili network API calls (`getVideoDetail`, `getReplyList`, `getPlayUrl`), risking parameter corruption and redundant network requests.
Learning: Video ID parameters sourced from deep links, routes, or user navigation must be sanitized at the remote data source boundary to prevent CRLF parameter injection and fail fast on blank inputs.
Prevention: Strip non-printable ASCII control characters (`[\x00-\x1F\x7F]`) and trim video ID parameters, returning `Result.error` fast for empty or whitespace-only inputs.

## 2026-10-06 - Standardize and Secure Bilibili Media Asset URLs in DTO Mappers

Vulnerability: Model DTO mappers across Bilibili search, ranking, and user results used naive string concatenation (`'https:$upic'`, `'https:$cover'`) or incomplete URL checks, producing corrupted schemes (`https:https://...` or `https:http://...`) when endpoints returned full URLs, and leaving scheme-relative URLs (`//...`) without explicit `https:`.
Learning: Untrusted network JSON asset fields can vary between scheme-relative (`//`), unencrypted (`http://`), or full HTTPS URLs (`https://`). Naive string interpolation corrupts valid HTTPS URLs or fails to enforce encrypted HTTPS transport.
Prevention: Use a standardized URL normalizer (`normalizeBiliUrl`) that securely converts `//` and `http://` to `https://`, preserves existing `https://` URLs, and handles `null`/empty values safely.
