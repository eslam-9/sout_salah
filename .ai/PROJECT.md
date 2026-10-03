# Sout Salah — PROJECT.md

## Classification: EXISTING

Justification:
- Clean Architecture skeleton is real and enforced: `lib/features/auth|mosques/{data,domain,presentation}` with pure domain (no flutter/supabase/dio imports in domain).
- App is functional: Supabase backend wired (`main.dart:22 Supabase.initialize`), 13 mosque screens, auth, home shell, audio/video, maps, downloads, FCM.
- State + DI established: `flutter_riverpod:^2.6.1` (69 imports) + `get_it:^9.2.0` (5 singletons in `injection_container.dart`).
- Baseline is green: `flutter analyze` 14 warnings only, `flutter test` 31/31 passing (2026-09-24).
- Debt is bounded, not structural: layer leaks are localized (providers wiring datasources, `DailyVideoModel` in routing, `video_repository.dart` bypass), not a missing architecture.

## What it is
Premium Islamic app (Arabic RTL-first): mosque prayer recordings organized by Ramadan day/prayer, background audio (`just_audio_background`), offline downloads (`Dio`), daily 4K video (`video_player`+`chewie`), OpenStreetMap explorer (`flutter_map`+`geolocator`), Supabase Auth + RBAC publisher uploads via Cloudflare R2 (SigV4), FCM push.

## Tech stack (from `pubspec.yaml`, SDK `^3.10.7`)
- `flutter_riverpod ^2.6.1`, `get_it ^9.2.0`, `dartz ^0.10.1`, `equatable ^2.0.8`
- `supabase_flutter ^2.12.0`, `dio ^5.9.1`, `crypto ^3.0.3`, `firebase_core ^4.5.0`, `firebase_messaging ^16.1.2`
- `just_audio ^0.9.42`, `just_audio_background beta.17`, `audio_session`, `on_audio_query`, `video_player ^2.11.1`, `chewie ^1.8.5`
- `flutter_map ^7.0.1`, `latlong2`, `geolocator ^13.0.0`, `geocoding ^3.0.0`
- `shared_preferences`, `path_provider`, `permission_handler`, `connectivity_plus`, `internet_connection_checker`, `url_launcher`, `lottie`, `lucide_icons`, `logger`
- Dev: `flutter_lints ^6.0.0`, `mocktail ^1.0.5`, `flutter_test`

## Layout
- `lib/main.dart` (93 lines): Supabase → GetIt → NotificationService → JustAudioBackground → `ProviderScope` → `MaterialApp` (Navigator 1.0, RTL `Directionality`).
- `lib/core/`: config, constants, di (`injection_container.dart`, `riverpod_providers.dart`), error, models, network (`network_info.dart`, `network_policy.dart`, `retry_executor.dart`), routes (4 files), services (7), theme, usecases, utils, validators, presentation, widgets.
- `lib/features/auth|mosques/{data,domain,presentation}`, `home/{presentation only}`, `shared/{widgets only}`.
- 216 lib files (~17k lines). No page >300 lines (largest service `downloads_service.dart:278`).
- `test/` 10 files mirroring part of `lib/`; `specs/001-ui-network-optimization/`; `plans/` x3; `docs/` screenshots+tech docs; `database_schema.sql`; `supabase/`; `secrets.json` gitignored, injected via `--dart-define-from-file`.

## Docs available
`README.md` (accurate stack/arch map), `review.md` (486 lines), `plans/*`, `docs/tec_documentation.md`, existing thin `.ai/` (8 files, superseded by this onboarding pass).

## Constraints / unknowns
- No flavors, no `integration_test/`, no dark mode, no `supportedLocales` (RTL forced, not localized).
- `secrets.json` present locally but untracked — never commit.
- Dirty worktree on `main` (see GIT_WORKFLOW.md) must be branched before feature work.
