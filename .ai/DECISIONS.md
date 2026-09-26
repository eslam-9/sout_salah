# Decisions

- **2026-09-24 — Keep Navigator 1.0 + GetIt+Riverpod hybrid.** No migration to go_router/Riverpod-only. Reason: router guards + typed args work, 243-line router is contained, hybrid DI is explicit. Revisit only if deep-linking is required (UNKNOWN: deep-link requirement — ask owner).
- **2026-09-24 — Keep `mosques` as one feature.** 13 pages/11 providers is large but cohesive (mosque → day → prayer → recording). Split videos/requests/location out only on team growth or independent release cadence.
- **2026-09-24 — `DailyVideoModel` leak must be fixed, not legitimized (for now).** Routing + 3 presentation files import the data model; no domain video entity exists. Decision: introduce domain video entity in Phase 2 (small), not a new feature.
- **2026-09-24 — Accept `core → mosques/domain` import temporarily.** `downloads/favorites` services + home cards use `Recording` entity. Promote to core-owned audio model only if a second feature needs it.
- **2026-09-24 — No pagination/caching/slivers.** Lists are small (Ramadan scale), images local-only. Optimize only on measured jank.
- **2026-09-24 — No dark mode / no localization infra.** Forced RTL + light Rubik theme is the product identity. Owner request required to change.
- **Contradiction recorded:** old `.ai/REFACTOR_PLAN.md` prescribed `feat/maps-navigation` + `dart-add-unit-test`/`flutter-widget-decomposition` skills — branch was never created and those skill names are invalid. Superseded by this plan's Phase 0 + valid skill names.

## Open product questions (need owner)
1. Deep links / shareable mosque-day URLs required? (affects router future)
2. Offline scope: audio-only or also video? (affects downloads_service growth)
3. Publisher RBAC matrix source of truth — Supabase RLS or app-side? (code assumes app-side checks + SQL RLS, unverified)

## 2026-09-24 — Full engineering audit: system upgraded, verdict CHANGES_REQUIRED
- Upgraded all 20 global review skills (missing-practices-as-findings, coverage-UNKNOWN rules, static+runtime perf levels, edge-case tables, use-case classification, maturity-not-person assessment, strengths-last ordering, CONDITIONAL status, 17-section report format, per-feature docs + matrix requirements).
- Audit executed: 31 tests = 27 unit + 4 widget + 0 integration; coverage MEASURED 16.3% (`flutter test --coverage`); runtime perf NOT PERFORMED (no device) → UNKNOWN.
- Critical defects confirmed: duplicate `SignUpUseCase`, lat/lng loss, `getCurrentRoute` stack pop, non-atomic approve. RLS permissive (profiles world-readable, mosque insert open). PII/token logging. Dirty `main`.
- Prior audit's `APPROVED` verdict was invalid under the new Final Status Rules — corrected to `CHANGES_REQUIRED` with reasons in `ENGINEERING_AUDIT.md`. Never regress: green tests + unknown coverage/perf + missing widget tests + warnings + git violation ⇒ not APPROVED.
- Refactor plan rewritten problem-referenced with CRITICAL/HIGH/MEDIUM/LOW priorities (was generic phases).
