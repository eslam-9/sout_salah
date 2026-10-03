# Refactor Plan (problem-referenced, priority-ranked)

Source: `.ai/ENGINEERING_AUDIT.md` (2026-09-24 full audit). Baseline: `flutter analyze` 14 warnings/0 errors; `flutter test` 31/31; coverage measured 16.3%; runtime perf NOT PERFORMED. Priorities rank by user impact, bug/security risk, architecture impact, testing difficulty, future cost, migration risk.

## Executive Summary
Fix 4 critical defects first (duplicate use case, silent coordinate loss, nav-stack destruction, non-atomic approve + permissive RLS), then auth failure handling + video arch parity + pagination + upload hardening, then test the untested half, then measure performance. No rewrite; no framework migration.

## Current / Target Architecture
See `ARCHITECTURE.md` + `ENGINEERING_AUDIT.md` (Architecture Assessment). Target = same skeleton with DI in `core/di/`, presentation importing domain only, video on the datasource→`Either` path, scoped providers, ID-based navigation, enforced RLS.

## Phase 0 — Secure git baseline (LOW)
- Problem: dirty `main` (3 maps files + version bump) + untracked `.ai/`, `devtools_options.yaml`, `update_skills.py` blocks reproducible builds (Git Audit).
- Goal: clean `main`, work isolated per branch.
- Skills: `git-manager`, `project-analyzer`
- Validation: `git status --short` clean on `main`; `flutter analyze` + `flutter test` recorded.

## Phase 1 — Critical defects (CRITICAL)
- Problems: (1) duplicate `SignUpUseCase` incompatible returns (`auth_usecases.dart:57` vs `sign_up_usecase.dart:7`); (2) `AddMosqueUseCase` drops lat/lng (`:33-39`); (3) `getCurrentRoute()` pops stack (`navigation_service.dart:124-131`); (4) approve 3-step non-transactional, double-accept duplicates mosque (`mosque_requests_remote_data_source.dart:82-116`).
- Goal: delete/merge duplicate UC (one contract); forward coordinates; rewrite route reader without popping; move approve to Postgres RPC (`SECURITY DEFINER`, role check, atomic, idempotent).
- Skills: `architecture-reviewer`, `domain-reviewer`, `data-layer-reviewer`, `testing-reviewer`, `refactoring-reviewer`, `code-reviewer`
- Required Tests: UC contract test; lat/lng round-trip regression test; nav-stack-intact test; approve retry-safety test.
- Validation: `flutter analyze` clean; `flutter test` green incl. 4 new suites.
- Risk: High (touches auth/mosque writes — small diffs, per-file review).

## Phase 2 — Auth failure handling + log redaction + RLS least-privilege (HIGH)
- Problems: datasource swallows Supabase errors to bare `ServerException` (`auth_remote_data_source.dart:42-44,...`); destructive `updateUsername`/`signOut` failures; PII/FCM-token logging (`:30,:54`, `notification_service.dart:112,134`); client-supplied `role:user`; `Profiles SELECT USING (true)` exposes emails; `Mosques INSERT` open to any authed incl. anonymous; null `publisher_id` writes; `getPendingRequests` unfiltered.
- Goal: preserve `AuthException.message/statusCode` → `AuthFailure`; null user → Unauthenticated; non-destructive failure states; redacted logs; server-enforced roles; tightened RLS + server-side `publisher_id`; startup URL allowlist.
- Skills: `data-layer-reviewer`, `domain-reviewer`, `testing-reviewer`, `code-reviewer`
- Required Tests: datasource error mapping; destructive-transition tests; RLS policy tests; guest-flag tests.
- Validation: `flutter analyze`; `flutter test`; manual RLS probe documented.
- Risk: Medium.

## Phase 3 — Video arch parity + pagination + upload hardening (HIGH)
- Problems: `VideoRepository` shadow stack + `DailyVideoModel` in routes; limit+range/no-order pagination; R2 unsanitized keys, no contentType, dual key parsing; `Prayer.fromString` collapse; strict model casts; uploader fire-and-forget + widget-held rules/notifications; N players; missing `mounted` guard.
- Goal: video entity + interface + `Either` + UCs; single-range ordered pagination + guards; sanitized keys + unified key helper + contentType + duration; safeParse models + `unknown` prayer variant; `startUpload → Future` with guard/reset/validation-in-UC/notification-in-UC; lazy video init + retry button.
- Skills: `architecture-reviewer`, `data-layer-reviewer`, `domain-reviewer`, `state-management-reviewer`, `ui-layer-reviewer`, `testing-reviewer`, `refactoring-reviewer`, `code-reviewer`
- Required Tests: video repo/UC suites; pagination (incl. exact-multiple); model malformed-JSON; upload ordering + cleanup branch; widget dispose-before-init.
- Validation: `flutter analyze`; `grep data/(models|datasources)` in presentation/routes → empty; `flutter test`.
- Risk: High (largest blast radius — split into 3 sub-PRs max ~300 lines each).

## Phase 4 — Test the untested half + warnings + provider dedup (HIGH)
- Problems: home 0%, services ~0%, 6 mosque providers untested, router/guards untested; 14 analyzer warnings; duplicate `initialCheckDoneProvider`; duplicate schedule providers; alias providers; unguarded `loadMore`; un-debounced search.
- Goal: 0 warnings; single provider instances; scoped `family+autoDispose` providers; debounced server-consistent search; guarded pagination; suites for home providers/pages, services, mosque providers, router guards.
- Skills: `testing-reviewer`, `state-management-reviewer`, `ui-layer-reviewer`, `dependency-injection-reviewer`, `code-reviewer`
- Required Tests: ≥25 new (providers, pages, services, guards); coverage re-measured and recorded.
- Validation: `flutter analyze` → "No issues found"; `flutter test --coverage` number in TESTING.md; `flutter test`.
- Risk: Medium (async flakiness — quarantine, don't skip).

## Phase 5 — Performance disposition with numbers (MEDIUM)
- Problems: 9 static risks, 0 runtime numbers (PERFORMANCE.md).
- Goal: `flutter run --profile` + DevTools over 6 flows; disposition each risk Measured-OK or Fixed-with-number (select/family scoping, keepAlive, RouteObserver, dispose audit).
- Skills: `performance-reviewer`, `state-management-reviewer`
- Validation: PERFORMANCE.md each risk → number; `flutter analyze` + `flutter test`.
- Risk: Low (no speculative optimization).

## Validation Criteria
Per phase: `flutter analyze` (Phase 4+: zero issues), `flutter test` (+ `--coverage` from Phase 4), phase-specific grep/tests above. No SQL/RLS edits outside Phases 1-2; no player/router-framework upgrades in this plan.

## Completed / Remaining
- Completed: none (baseline recorded 2026-09-24).
- Remaining: Phase 0 → 1 → 2 → 3 → 4 → 5. Phase 0 unblocks all; 1 before 2-3 (defects first); 5 last.
