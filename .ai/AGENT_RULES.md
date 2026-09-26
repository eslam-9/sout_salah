# Agent Rules

Project `.ai/` overrides generic preferences. Read these files before any task: `PROJECT.md`, `ARCHITECTURE.md`, `STATE_MANAGEMENT.md`, `DATA_LAYER.md`, `CONVENTIONS.md`, `FEATURES.md`, `UI_GUIDELINES.md`, `TESTING.md`, `PERFORMANCE.md`, `GIT_WORKFLOW.md`, `DECISIONS.md`, `REFACTOR_PLAN.md`.

1. **No massive refactors.** One REFACTOR_PLAN phase at a time, tests-before-behavior-change, `flutter analyze` + `flutter test` green to close a phase.
2. **Respect layering:** presentation → domain → data impls. Forbid new imports of `data/models|datasources` from presentation/routes; forbid `flutter|supabase|dio` in domain; keep `video_repository` fix in place.
3. **State:** Riverpod for UI/async, GetIt for the 5 singletons only. No new global state without a documented owner provider.
4. **No invented architecture.** Simplest fix satisfying requirements; no go_router/auto_route/freezed/bags migration unless a phase explicitly approves it.
5. **Verify, don't claim.** Never report "passes" without running `flutter analyze` / `flutter test`; quote real output. Evidence uses `file:line` paths.
6. **RTL + light theme only.** No dark mode, no localization infra, no new image-caching deps without measurement.
7. **Secrets stay local.** Never print or commit `secrets.json` contents.
8. **Git via `git-manager`.** No direct pushes to `main`; dirty `main` must be branched first.
9. **Review routing:** architecture → `architecture-reviewer`; state/DI → `state-management-reviewer`/`dependency-injection-reviewer`; data → `data-layer-reviewer`; widgets → `ui-layer-reviewer`; tests → `testing-reviewer`; perf → `performance-reviewer` (risks, not rewrites); scope disputes → `feature-boundary-reviewer`; plan coordination → `project-orchestrator`.
