# Feature: Home (shell + downloads + favorites + settings)

## Purpose
Bottom-nav shell over 4 tabs: mosque discovery (search + pagination), offline downloads list, saved/favorites list, settings (profile/logout).

## Entry Points
- `lib/features/home/presentation/pages/home_layout.dart:15` (`HomeLayout`)
- `.../pages/mosques_page.dart:15`, `downloads_page.dart:11`, `saved_recordings_page.dart:10`, `settings_page.dart:11`
- `.../providers/favorites_provider.dart:6`, `downloads_provider.dart:20`

## User Flows
- Shell: `_currentIndex=0`, `_pages=[Mosques,Downloads,Saved,Settings]`; tap → `setState`; body shows page. Auth listener → Unauthenticated → login (`home_layout.dart:35-44`).
- Mosques: `initState` permissions + scroll listener → `mosqueProvider.when(data/loading/error)` → client filter `name.contains(query)` → `MosqueCard` tap → detail; scroll near end → `loadMore`; pull → refresh; FAB if `canAddMosque` → addMosque.
- Downloads/Saved: watch `allDownloads/allFavoritesProvider` → data (empty widget else cards) / loading / error+invalidate.
- Settings: listen Auth → Unauthenticated → login; guest hides profile entry; logout → `signOut()` with zero UI feedback.

## Screens
`HomeLayout` (nav shell), `MosquesPage`, `DownloadsPage`, `SavedRecordingsPage`, `SettingsPage`. No detail screens (delegates to mosques feature). Labels: الرئيسية/التنزيلات/المفضلة/الإعدادات.

## Architecture
- **Presentation only — no domain/data layers.** Directly imports `mosques/presentation/providers/mosque_controller` and `core/services/*`. Thin-UI-over-others'-state; cross-feature coupling by design, undocumented.

## Presentation
- White fixed bottom nav with shadow; `MosquesPage 0xFFF9FAFB + HomeAppBar + RefreshIndicator`; downloads/saved headers + padded lists; `SettingsPage` returns bare `Padding` (no Scaffold/SafeArea/scroll — overflow risk, unusable standalone).

## State Management
- Shell index: local `setState`, no `IndexedStack` (tab state fragile, lists rebuilt, streams re-emit prefs reads on switch).
- Mosques: external `mosqueProvider` + local search string, scroll controller, `_canAddMosque` (async, no loading state — FAB pops in late).
- Downloads/Favorites: `StreamProvider` from core services; `isFavorite/isDownloaded: Provider.family<AsyncValue<bool>>` via `whenData`; `allFavorites/allDownloads` are pure aliases (noise).

## Domain / Entities / Use Cases / Repositories / Data Sources / Models
- None in `home/`. Models reused: `core/models/downloaded_recording.dart`, `favorite_recording.dart`. Behavior lives in `core/services/downloads|favorites_service.dart` (SharedPreferences JSON + local files; download guard via `_cancelTokens`; favorite reuses existing `${id}.mp3`).

## External Dependencies
`flutter_riverpod`, `lucide_icons`, `NavigationService`, `PermissionChecker/MosquePermissions`, `AppColors`, shared state widgets.

## Business Rules
- FAB iff `canAddMosque()` (= `!is_guest_mode` — client-side UI gate only, bypassable). Guest hides profile. Favorite falls back to stream URL when no local file (offline playback then fails silently).

## UI Rules
- Search `contains` (case-sensitive, no trim — poor Arabic recall). Pagination footer spinner iff `hasMore`. Dedicated empty widgets (good): `AppEmptyState`, `DownloadsEmptyState`, `SavedRecordingsEmptyState`.

## Error States
- Handled: mosques error → `AppErrorView` + retry; downloads/saved error → `AppErrorView` + invalidate.
- Missing: mosque error ignores `error` object (everything reported as offline); corruption masked as empty (`getDownloads/getFavorites` return `[]` on bad JSON); settings `signOut` has no loading/error — failure strands user (shell only reacts to Unauthenticated); `HomeLayout` ignores `AuthError/Loading`.

## Loading States
- Mosques loading → scrollable spinner (no shimmer, no cached data; `loadMore` wipes list instead of footer-only). Downloads/saved → bare indicator. No loading for `_canAddMosque`/sign-out.

## Empty States
- Covered: no-mosques / no-results / no-downloads / no-favorites all have dedicated widgets. Mosques empty wrapped in always-scrollable ListView (refresh works).

## Edge Cases
| Case | Status | Evidence |
|---|---|---|
| Offline | Partially | Downloads/favorites work (local); mosques error message accidentally correct |
| Auth-fail sign-out | Not Covered | No snackbar, stuck on AuthError |
| Corrupt prefs JSON | Not Covered | Masked as empty |
| `canAddMosque` throw | Not Covered | Stays false silently, no catch |
| Rapid scroll `loadMore` | Not Covered | No `isLoadingMore` guard — duplicate fetches |
| Search keystroke | Not Covered | `setState` per key, no debounce (static perf FAIL) |
| Pagination exact-multiple | Not Covered | One wasted fetch (`_hasMore` heuristic) |

## Tests
- Present: none. Zero `home/*` tests; `test/` has no favorites/downloads providers or page tests. Measured coverage: `home/` absent from lcov — **0%**.

## Missing Tests
Everything: tab switching, auth redirect, search filter (case/whitespace/Arabic), pagination threshold/footer, refresh, FAB gating, all loading/error/empty branches, guest hiding, sign-out navigation, stream aliases.

## Performance
- Filter `where+toList` in `build` per frame; `isFavorite/isDownloaded.family` does O(N) `any()` per card — janks at hundreds of items; no `IndexedStack` (rebuild + prefs re-read per tab switch); `ListView` wrapping single `SizedBox` for empty/loading states; 1 horizontal `ListView` that should be a `Row`.

## Security
- `canAddMosque` client-side only — must be RLS-enforced (currently `Mosques INSERT WITH CHECK (auth.uid() IS NOT NULL)` allows any authed user incl. anonymous). Full entity passed via navigation (stale data, no ID refetch).

## Technical Debt
No domain layer; alias providers; case-sensitive search; unguarded pagination; duplicated auth listeners (HomeLayout + SettingsPage); `SettingsPage` not standalone-safe.

## Refactor Requirements
1. `IndexedStack` + single shell auth listener; sign-out loading/error UI. (HIGH)
2. Debounce + normalize search; move filter to notifier with `select`; guard `loadMore`. (HIGH)
3. Surface real errors; distinguish corrupt vs empty prefs. (MEDIUM)
4. Replace alias providers with `Set<String>` id lookups O(1). (MEDIUM)
5. Full test suite for providers + pages (currently 0%). (HIGH)

## Engineering Assessment
Architecture WEAK (no layers, cross-feature imports), Code Quality PARTIAL, Testing MISSING (0%), Edge Cases WEAK, Security WEAK (client-side gate).

## Last Reviewed
2026-09-24 (full engineering audit; `flutter test --coverage` measured).
