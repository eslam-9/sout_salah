# Git Workflow

## Reality (2026-09-24)
- Branch: `main` dirty — `M maps_navigation_service.dart`, `M mosque_info_map.dart`, `M mosque_info_maps_button.dart`, `M pubspec.yaml (1.1.3+5 → 1.1.4+6)`; untracked `.ai/`, `devtools_options.yaml`.
- Branches: `main`, `chore/secure-history-and-docs`, `refactor/architecture-phase0|phase8`, `refactor/mosque-ui-components-and-location`, `refactor/ui-widget-decomposition` + ~35 remote `pr/*` refs. Recent log is healthy conventional commits (`feat/fix/refactor/test/chore/docs`).
- Stale thin `.ai/REFACTOR_PLAN.md` referenced a `feat/maps-navigation` branch that was never created — superseded by this plan.

## Rules
1. **Never commit directly on `main`.** Current dirty maps+version work → move to `refactor/maps-navigation` (Phase 0) first.
2. Branch names: `feat/*`, `fix/*`, `refactor/*`, `chore/*`, `test/*`. One concern per branch.
3. Conventional Commits: `type(scope): description` (e.g. `fix(mosques): scope DailyVideoModel to data layer`).
4. Before each phase: `git status` clean on `main`, branch from `main`, `flutter analyze` + `flutter test` green; PR-sized diffs (<~300 lines behavior change).
5. Secrets: never commit `secrets.json`, `google-services.json`, `GoogleService-Info.plist`, `key.properties`. Version bumps isolated in `chore(release)` commits, not mixed with behavior.
6. Hand branch/commit/push execution to `git-manager`; this skill plans, it does not push.
