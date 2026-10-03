# Feature Matrix

Measured 2026-09-24 (`flutter test --coverage`: 16.3% line coverage over executed files; `flutter analyze`: 14 warnings/0 errors; runtime profiling NOT PERFORMED — no device).

| Feature | Architecture | Code Quality | Testing | Edge Cases | Performance | Security | Documentation | Technical Debt | Priority |
|---|---|---|---|---|---|---|---|---|---|
| Mosques | PARTIAL | WEAK | WEAK | WEAK | PARTIAL | WEAK | PARTIAL | HIGH | HIGH |
| Auth | PARTIAL | WEAK | PARTIAL | WEAK | PARTIAL | WEAK | PARTIAL | MEDIUM | HIGH |
| Home | WEAK | PARTIAL | MISSING | WEAK | WEAK | WEAK | PARTIAL | MEDIUM | HIGH |
| Shared + Core services | PARTIAL | WEAK | MISSING | WEAK | WEAK | WEAK | PARTIAL | HIGH | CRITICAL |

Values: GOOD | PARTIAL | WEAK | MISSING | UNKNOWN. Performance is static-review only (never GOOD without runtime data).
Details: `.ai/features/mosques.md`, `.ai/features/auth.md`, `.ai/features/home.md`, `.ai/features/shared.md`.
