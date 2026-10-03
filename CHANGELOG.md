# Changelog

All notable changes to this project will be documented in this file.
Format: [Semantic Versioning](https://semver.org)

## [Unreleased]

### Security
- Removed `secrets.json` from git history (Phase 0)
- Added startup assertions for missing env vars
- Added global Flutter error boundary

### Added
- `UserPermissionService` — domain-layer permission checks replacing inline role strings
- `FailureMapper` utility — single source of truth for Failure → message mapping
- `copyWith` on `Mosque`, `Recording`, `RamadanDay` entities
- `AudioPlaybackException`, `UserNotFoundException` typed exceptions
- In-memory cache in `DownloadsService`
- `cached_network_image` for network image caching
- Search debounce (300ms) in MosquesPage
- Case-insensitive mosque search

### Changed
- Auth state folder renamed: `presentation/bloc/` → `presentation/state/`
- `loadMore()` pagination uses `copyWithPrevious` — no longer clears list during load
- `DownloadsService.getDownload()` uses `firstWhereOrNull` (no try/catch)
- Hardcoded color values replaced with `AppColors` tokens
- `analysis_options.yaml` upgraded with stricter lint rules

### Fixed
- `AudioPlayerService` provider now calls `dispose()` on cleanup
- `DownloadsService` and `FavoritesService` providers now dispose `StreamController`s
- `AppRouter` no longer depends on `GetIt` — uses `Supabase.instance.client` directly

## [1.1.4+6] - 2026-09-24
Initial audited state.
