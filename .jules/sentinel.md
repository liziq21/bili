# Sentinel Security Journal

## 2026-09-16 - Enforce TLS/SSL Certificate Validation in HttpIOClient

Vulnerability: `badCertificateCallback = (_, _, _) => true` was hardcoded on the primary `HttpClient` / `http.IOClient` in `app/lib/main.dart`, bypassing all TLS/SSL certificate verification for Bilibili API requests.
Learning: Debug proxy setups (e.g. Charles/Burp) often introduce local certificate overrides that can easily leak into application code if not stripped before committing or guarded strictly behind debug environments.
Prevention: Never hardcode `badCertificateCallback` overrides returning `true` in shared client initialization. Enforce standard platform certificate validation across all build targets.

## 2026-09-17 - Restrict DebugOverlay and HttpLogClient to Debug Environments

Vulnerability: `DebugOverlay.enabled = true` and `HttpLogClient(App.httpBucket, ...)` were hardcoded unconditionally in `app/lib/main.dart`, capturing sensitive network request/response traffic and runtime logs into memory buckets and exposing the debug overlay in production release builds.
Learning: Debug overlays and HTTP logging interceptors must be guarded strictly by release mode checks (`kReleaseMode`), as un-guarded debug tools expose HTTP headers, response payloads, and internal log traces to end-users or background screen captures in release builds.
Prevention: Always verify `DebugOverlay.enabled = false` and use standard un-intercepted network clients in `kReleaseMode`.
