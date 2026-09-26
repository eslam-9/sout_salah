# Feature: Shared (reusable audio sheet + core platform services)

## Purpose
Reusable bottom-sheet audio chrome + app-wide platform services (playback, downloads, favorites, notifications, R2, startup, navigation). No screens of its own; consumed by home + mosques.

## Entry Points
- `lib/features/shared/widgets/base_audio_sheet.dart:11` (`BaseAudioSheet`)
- `.../base_audio_sheet_components/audio_sheet_{header,slider,controls}.dart`
- `lib/core/services/{audio_player_service, downloads_service, favorites_service, notification_service, r2_storage_service, startup_service, navigation_service}.dart`
- `lib/core/di/{injection_container, riverpod_providers}.dart`

## User Flows
- Caller shows sheet with metadata + optional actions → slider streams `positionStream` → controls stream `playerStateStream` → play/pause/±15s. Singleton `AudioPlayerService` shared globally.
- Downloads: `Dio.download → app docs/downloads/<id>.mp3` + prefs index; favorites: prefs JSON + optional local-file reuse; notifications: FCM token register/remove + `sendNotification`; R2: SigV4 PUT/DELETE; startup: `from('data')` remote notice + optional link launch.

## Screens
Single sheet: drag handle, header, slider, controls (`mainAxisSize.min`, topRadius30). Duration `mm:ss`, null → `--:--`.

## Architecture
- Widgets-only feature (correct). Services in `core/` mix three error contracts: `Either` (auth repos only) vs `rethrow`/raw `Exception` vs log-only — UI `when(error)` rarely triggers because services swallow to `[]`.
- `core → mosques/domain` imports (`downloads_service.dart:8`, `favorites_service.dart:7`) — inverted edge, accepted temporarily (see DECISIONS.md).

## Presentation
- `ConsumerWidget` + raw `just_audio` `StreamBuilder`s (not Riverpod AsyncValue). Play-button spinner on buffering. No `snapshot.hasError` handling anywhere — invalid URL/offline → spinner forever or unhandled exception. Slider reads sync `player.duration` (null until loaded). No error retry, no offline→local fallback contract (callers hold URL vs path; no enforced choice).

## State Management
- Global singleton player (non-`autoDispose`, `dispose()` never called — native handle leaks for app lifetime). No `recordingId` correlation with download/favorite state; can't preview two recordings; audio keeps playing after sheet dismiss (no `onDismiss` contract).

## Domain / Entities / Use Cases / Repositories / Data Sources / Models
- None for playback (direct `just_audio` + `MediaItem`). Download/favorite models: `core/models/downloaded|favorite_recording.dart` (0% coverage).

## External Dependencies
`just_audio`, `just_audio_background`, `dio`, `shared_preferences`, `path_provider`, `firebase_messaging`, `supabase_flutter`, `crypto`, `url_launcher` (startup link — **no allowlist**, remote-row URL → arbitrary open, see Security).

## Business Rules
- Seek iff `duration>0` (clamped max, but **negative seek unclamped**: `position-15s`); ±15s hard-coded; filenames `${id}.mp3` (assumes mp3); R2 upload `contentType audio/mpeg` hard-coded (m4a/wav mislabeled); `Platform.isAndroid?...` breaks web/desktop.

## UI Rules
- Title/subtitle/header slots; 72px primary play circle; `SliderTheme` primary/grey.

## Error States
- `play` type-erases to `Exception('Failed...')`; pause/resume/stop/seek throw raw. Sheet: zero error UI. `downloads_service` good cancel-vs-network split + partial cleanup, but `_emit/get` log-only/`[]` mask corruption; `removeDownload/removeFavorite` throw raw on missing. `notification/startup` log-only by design (non-critical, acceptable) — but auth flow can't know token failed.

## Loading States
- Play-button spinner only; slider `00:00/00:00` while loading; no `setAudioSource` progress; `durationStream` ignored.

## Empty States
- N/A (title required, unguarded — blank render if empty).

## Edge Cases
| Case | Status |
|---|---|
| Offline play | Not (no local fallback, generic exception) |
| Rapid-tap play/pause/seek | Not (async races, seek spam unthrottled) |
| positionStream frequency | Risk (rebuild per tick, no throttle) |
| Corrupt prefs | Not (masked as empty) |
| Orphan files on favorite-remove | Not (file kept) |
| Notification denied | Not (logged only, no denied-path) |
| Oversized multi-video pick | Not (no pre-check at pick) |
| `getCurrentRoute()` | **Critical bug**: `popUntil(()=>true)` pops entire stack as side effect of reading route (`navigation_service.dart:124-131`) |
| Audio focus/interruption | Unknown (not read) |

## Tests
- Present: none for `shared/*` or any core service. Measured: `audio_player/downloads/favorites/navigation/r2` **0%**, `notification 7.4%` (import side-effect only).

## Missing Tests
Sheet render/clamp/format/controls/error/rapid-tap; controller local-preference; download cancel/cleanup/persistence; favorite orphan; audio error paths; token register/remove; R2 signing; startup null-ambiguity; `getCurrentRoute` destruction.

## Performance
- Slider rebuild per position tick (10-100ms); sync `duration` per tick; singleton never disposed; `R2 readAsBytes` loads whole file in memory; no pre-flight connectivity (fail-late).

## Security
- `artUri: Uri.parse` unvalidated; startup `_launchUrl` remote-URL with no scheme/host allowlist (**hole**); FCM token logged plaintext (`notification_service.dart:112,134`); R2 creds correctly from `AppConfig` (good); prefs unencrypted (OK today — no secrets stored; add `flutter_secure_storage` before storing any).

## Technical Debt
Three error styles; masked corruption; orphan files; mp3/content-type assumptions; platform check; undisposed singletons (`dispose()` exists but uncalled); alias providers in home; `update_skills.py` untracked junk at repo root (pre-existing, not ours — remove).

## Refactor Requirements
1. `AudioSheetController(recordingId, url, localPath)`: prefer local, `AsyncValue` + error + retry; clamp/debounce seeks; stop-or-miniplayer on dismiss; `durationStream`. (HIGH)
2. Unify service errors (typed failures or documented rethrow); surface corrupt prefs; fix orphan files; correct content-type/extension handling. (HIGH)
3. Rewrite `getCurrentRoute` without popping (`ModalRoute.of(context)`); add test asserting stack intact. (CRITICAL)
4. Allowlist startup URLs (`https` + domain list) + `canLaunchUrl`. (HIGH)
5. Full service/sheet test suites. (HIGH)

## Engineering Assessment
Architecture PARTIAL, Code Quality WEAK (nav-stack bug, masked errors), Testing MISSING (0%), Edge Cases WEAK, Performance WEAK (tick rebuilds, leaks), Security WEAK (open launcher, token logs).

## Last Reviewed
2026-09-24 (full engineering audit; `flutter test --coverage` measured).
