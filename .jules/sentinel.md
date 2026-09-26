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
