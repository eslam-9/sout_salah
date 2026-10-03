# Engineering Audit — Sout Salah

**Date:** 2026-09-24. **Method:** full 19-step workflow (onboarding → analysis → feature discovery → arch/UI/domain/data/state/DI/testing/edge-case/performance/git/docs audits → maturity → feature docs → matrix → refactor plan). Actual code read throughout; evidence `file:line`. **Validation:** `flutter analyze` 14 warnings/0 errors; `flutter test` 31/31 (27 unit + 4 widget + 0 integration); `flutter test --coverage` **16.3%** line coverage (356/2181, executed files only — true repo coverage lower). **Performance Runtime Validation: NOT PERFORMED** (no device) → Performance Status: UNKNOWN.

## Project Overview
Existing Arabic RTL-first Islamic app (mosque recordings, background audio, offline downloads, daily video, maps, publisher uploads, FCM). Clean skeleton (Riverpod + GetIt, Navigator 1.0, Supabase + Dio + R2 SigV4), 216 lib files, 10 test files. Functional but audit finds 2 critical defects, systemic error-swallowing, client-side-only RBAC, 0%-tested areas, and a nav-stack-destroying getter.

## Architecture Assessment
Skeleton real, discipline partial. Domain import-clean. Presentation is the DI container (`mosque_data_providers.dart:33-162`, `auth_data_providers.dart:7-18`, `daily_video_providers.dart:7-13`); video feature lives outside Clean Arch (`video_repository.dart` concrete, no interface/`Either`, raw rethrows; `DailyVideoModel` in `route_args.dart:5` + 3 presentation files); repository-direct reads bypass UCs at 4+ sites (`mosque_data_providers.dart:122-123`, `ramadan_days_provider.dart:83-84`, `day_schedule_provider.dart:8,29,50,76,95`, `daily_video_providers.dart:18-19`); domain leaks Supabase schema (`ramadan_month_factory.dart:11-18`); dual DI (Riverpod veil over GetIt) + Supabase in router guard (`app_router.dart:2,32-40`); entities passed via Navigator (stale data, no ID refetch).

## Feature Assessment
Mosques: god-feature, most defects here (see features/mosques.md). Auth: error swallowing + destructive transitions + duplicate UC/provider. Home: no layers, 0% tests, unguarded pagination/search. Shared/services: three error contracts, masked corruption, orphan files, nav-stack bug.

## Testing Assessment
31 tests = 27 unit + 4 widget + 0 integration. **Coverage MEASURED 16.3%** (auth/data 9.4%, auth/domain 27%, auth/presentation 32.7%, mosques/data 1.5%, mosques/domain 16.1%, mosques/presentation 39.3%, home 0%, core services ~0%). No CI (`.github/` absent), no coverage gate/badge, no `integration_test/`. Widget tests are `find.text` smoke. Critical paths untested: playback, downloads, R2 upload, maps service, 6 mosque providers, router/guards, signup/anon/updateProfile flows.

## Edge Case Assessment
Per-feature tables in `features/*.md`. Systemic: offline untested; timeouts missing on R2 uploads; null/malformed JSON crashes (strict casts); double-tap upload/accept unguarded (double-accept creates 2 mosques); pagination bounds unguarded; permissions partially typed (location) else absent; state restoration absent (by-value entities, stale globals, never-reset UploadState).

## Performance Assessment
Static review only. Risks with evidence: list-wide rebuild on playback state (every card watches player + currentId); full-list `loading()` wipes on loadMore/refresh/requests; `FutureProvider.family(autoDispose)` thrash (refetch per navigation, no keepAlive); no search debounce (rebuild per keystroke) + client filter defeats server pagination; O(N) players for N videos (dispose correct, `mounted` guard missing, late-init hazard); position-stream tick rebuilds; singleton player never disposed; R2 `readAsBytes` whole-file memory. Non-issues: no remote images (nothing to cache), Chewie dispose present, pagination exists (but unstable: limit+range, no order). Runtime: NOT PERFORMED → UNKNOWN.

## Security Assessment
Secrets handling GOOD (dart-define only, gitignored, no literals). RLS enabled but permissive: `Profiles SELECT USING (true)` exposes emails; `Mosques INSERT` allows any authed incl. anonymous; enforcement is app-side (FAB visibility) — assume bypassable. Client-supplied `role:user` on signUp. PII/token logging: emails, user IDs, FCM token plaintext. Startup `_launchUrl` opens remote-row URLs with no allowlist (compromised row → arbitrary open). `publisher_id: null` writes allowed. Guessable R2 keys, no signed URLs. Email enumeration via `addPublisher`. No secrets in prefs (narrow pass).

## Git Assessment
Conventional prefixes mostly followed, vague bodies, oversized refactor blobs. Branch sprawl (6 local + ~35 stale `origin/pr/*`), overlapping long-lived refactors, drift merge. **Dirty `main`**: 4 modified (3 maps files + version bump) + 3 untracked (`.ai/`, `devtools_options.yaml`, `update_skills.py`). No CI to gate anything.

## Documentation Assessment
README accurate; `review.md`/`plans`/`docs` exist; `.ai/` now complete per new standard (this file + features/ + matrix + updated TESTING/PERFORMANCE/FEATURES/REFACTOR_PLAN). Gaps closed except runtime perf numbers and RLS verification (owner/DB tasks).

## Engineering Maturity (codebase, not person)
| Category | Score | Confidence | Key evidence |
|---|---|---|---|
| Architecture | 2 | HIGH | Skeleton clean, DI-in-UI, video shadow stack, dual DI |
| Feature Design | 3 | MEDIUM | Cohesive features, sensible splits; mosques oversized but coherent |
| Code Quality | 2 | HIGH | Data-loss bug, duplicate UC, non-atomic writes, corruption loops |
| State Management | 2 | HIGH | Correct lib, wrong scopes, wipes, duplication, fire-and-forget |
| Dependency Management | 3 | MEDIUM | Pinned, appropriate; duplicate connectivity libs, beta background audio |
| Domain Design | 2 | HIGH | Pure imports, 1 real UC + 1 real rule, ~18 thin wrappers, schema leak |
| Data Layer | 2 | HIGH | Isolated clients, `executeWithCatch` best-in-repo; video bypass, unstable pagination, swallowed codes |
| UI Architecture | 3 | MEDIUM | Component splits, shared states/sheet; logic-in-widgets pockets, missing error branches |
| Testing | 2 | HIGH | 31 green incl. strong notifier test; 16.3%, 0 integration, 0%-areas, no CI |
| Edge Case Handling | 2 | HIGH | Location taxonomy good; systemic unguarded actions, masked errors |
| Error Handling | 2 | HIGH | Best-in-repo taxonomy exists but bypassed: swallowing at datasource, log-only services, destructive auth transitions |
| Performance Engineering | 2 | MEDIUM | Correct patterns present; no debounce/caching/disposal discipline, no profiling (static only) |
| Security | 2 | HIGH | Secret hygiene good; permissive RLS, client RBAC, PII logs, open launcher |
| Documentation | 3 | HIGH | README + full `.ai/`; missing runtime numbers, RLS proof |
| Git Workflow | 2 | HIGH | Conventional style; dirty main, sprawl, no CI gate |
| Maintainability | 2 | HIGH | Small files, clear layers; global stale state, shadow paths, untyped contracts |
| Scalability | 2 | MEDIUM | Pagination exists; unstable pages, N-players, no caching strategy |

Overall: **2 / 5 (Developing)** —依赖 HIGH-confidence categories dominate. No overall score was computed before categories were done (per policy).

## Critical Findings
1. `SignUpUseCase` defined twice with incompatible returns (`auth_usecases.dart:57` vs `sign_up_usecase.dart:7`). (Auth)
2. `AddMosqueUseCase` drops `latitude/longitude` — silent data loss (`add_mosque_usecase.dart:33-39`). (Mosques)
3. `getCurrentRoute()` pops the entire nav stack (`navigation_service.dart:124-131`). (Shared)
4. Approve-request 3-step non-transactional; double-accept creates two mosques; no client RBAC; RLS permissive. (Mosques/Security)

## High Findings
- Auth error swallowing → generic errors; destructive `updateUsername`/`signOut` failures; PII/FCM-token logging; client-supplied role.
- Video shadow stack (no interface/`Either`/UC) + `DailyVideoModel` in routes.
- `loadMore`/refresh/requests full-list wipes; global providers for scoped data; duplicate schedule providers; fire-and-forget uploader.
- Unstable pagination (limit+range, no order); dual R2-key parsing (orphans); `Prayer.fromString` corruption loop; strict model casts.
- Dirty `main`; 16.3% coverage; no debounce; N video players; startup URL hole; null `publisher_id` writes.

## Medium Findings
Stringly-typed red/yellow/green; dead `MosqueDetailArgs`/duplicate providers/alias providers; mutation `bool false` swallowing; months-empty ambiguity; untyped audio-file `Map`; `Platform.isAndroid` desktop break; mp3/content-type assumptions; orphan files on unfavorite; const density; nested scrollables.

## Low Findings
Param-style drift; exact-multiple wasted fetch; FAB pop-in; spinner-only loadings; `update_skills.py` root junk; stale `pr/*` refs; vague commit bodies.

## Missing Practices
No integration tests; no coverage gate (now measured once, not enforced); no CI; no runtime profiling; no offline/timeout/permission/rapid-action test matrix; no error-state widget tests for most screens; no ADRs (now DECISIONS.md started); no branch isolation (dirty main); no signed R2 URLs; no `flutter_secure_storage` path; no debounce/caching policy.

## Refactor Priorities
CRITICAL: duplicate UC, lat/lng loss, nav-stack getter, atomic approve + RLS hardening. HIGH: auth failure preservation + non-destructive transitions + log redaction, video arch parity, pagination fix, upload hardening, search debounce, startup allowlist, home test suite. MEDIUM: provider scoping/dedup, model safeParse, enum status, error surfacing. LOW: const/pass hygiene, branch pruning, commit bodies.
