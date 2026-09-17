# Sentinel Security Journal

## 2026-09-16 - Enforce TLS/SSL Certificate Validation in HttpIOClient

Vulnerability: `badCertificateCallback = (_, _, _) => true` was hardcoded on the primary `HttpClient` / `http.IOClient` in `app/lib/main.dart`, bypassing all TLS/SSL certificate verification for Bilibili API requests.
Learning: Debug proxy setups (e.g. Charles/Burp) often introduce local certificate overrides that can easily leak into application code if not stripped before committing or guarded strictly behind debug environments.
Prevention: Never hardcode `badCertificateCallback` overrides returning `true` in shared client initialization. Enforce standard platform certificate validation across all build targets.
