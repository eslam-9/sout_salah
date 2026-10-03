# Feature: Mosques (catalog + Ramadan + recordings + videos + schedule + requests + location)

## Purpose
Core feature: mosques → Ramadan months/days → prayers/recordings (R2 + Supabase audio) + daily videos (Chewie) + day-schedule CRUD + mosque creation (direct + request/approve) + publisher management + location picker + maps navigation. Arabic-first.

## Entry Points
- `mosque_controller.dart:17` (`mosqueProvider`), `mosque_data_providers.dart:32-162` (feature DI root)
- Routes: `mosqueDetail` (raw `Mosque` entity — `MosqueDetailArgs:68-72` dead), `dayDetail`, `daySchedule`, `uploadRecording` (+`validate()`), `dailyVideo`, `videoPlayer`, `uploadDailyVideo`, `audioPlayer`, `addMosque`, `deviceAudioSelection` (`app_router.dart:83-223`)

## User Flows
1. Browse (pageSize 20): `MosqueNotifier → GetMosquesUseCase → repo → datasource`.
2. Detail → months (`availableMonthsProvider`) → pick last → `loadDays` (`mosque_detail_page.dart:35-52`).
3. Day detail: parallel `dayRecordingsProvider(day.id)` + `dailyVideoListProvider(day.id)`.
4. Upload audio: pick file → 100MB check → `UploadRecordingNotifier.startUpload` → `UploadRecordingUseCase` stream → R2 + insert → delete pending → `sendNotification` + pop.
5. Video: list → Chewie play → upload via `VideoRepository` (bypasses `Either`).
6. Schedule CRUD via `DayScheduleNotifier` (+ duplicate `dayScheduleProvider`).
7. Add mosque direct vs request → approve (3 sequential calls, no transaction).
8. Location picker → `GetCurrentLocationUseCase` → `LocationService`; maps via `OpenMosqueInMapsUseCase` → `MapsNavigationService` (widget also has own `url_launcher` fallback bypassing the UC).

## Screens (13)
`add_mosque`, `mosque_detail`, `mosque_info`, `mosque_requests`, `day_detail` (18-line shell), `day_schedule`, `upload_recording` (218), `device_audio_selection` (untyped `Map` contract), `audio_player` (dead `ref` param `:17`), `daily_video` (error branch discards error, no retry), `video_player` (shell), `upload_daily_video`, `add_publisher` (email lookup — enumeration risk).

## Architecture
- Claimed Clean Arch; domain import-clean (zero flutter/supabase/dio hits). Leaks: DI lives in presentation (`mosque_data_providers.dart:33-162` builds 5 datasources + 6 repos + 2 services + 8 UCs); `VideoRepository` concrete class, no interface, no `Either`, raw `rethrow` — shadow stack; `DailyVideoModel` in `route_args.dart:5` + 3 presentation files; repository-direct reads bypass UCs at 4+ sites; entities passed via Navigator (stale data, no ID refetch, no deep-link).

## Presentation
- Sensible `*_components/` splits; `DayDetailBody` best loading/error gate (retry invalidates both providers); `UploadRecordingPage` disposes controllers but never resets notifier (stale Success/Error leaks); `audio_player_page` never watches audio state.

## State Management
| Provider | Verdict |
|---|---|
| `mosqueProvider` (global AsyncNotifier, pagination in-notifier) | Bad: `loadMore` wipes with `loading()` — flicker + scroll jump; not autoDispose |
| `ramadanDaysProvider` (global) | Bad scope for per-mosque data; `build()=>[]` hides loading; error double-sets |
| `availableMonthsProvider` (family future) | Bad: failure → `[]`, caller can't distinguish error vs empty |
| `uploadRecordingNotifierProvider` | Bad: `startUpload` fire-and-forget `void`, no cancel/dedup guard, uncaught stream errors |
| `dayScheduleProvider` + `dayScheduleNotifierProvider` | Dead duplication — double source of truth, double fetch |
| `dailyVideoListProvider` | No Failure mapping (raw rethrow) |
| `mosqueRequestsProvider` (global) | Fetches for all users incl. non-admins; accept/decline wipe list; `createRequest` throws instead of `Either` |
| `mosqueLocationPickerProvider` (autoDispose) | Best: typed status taxonomy; wart: `AsyncValue.data(loading())` conflation |

## Domain
- Entities: `Mosque`, `Recording`, `RamadanDay`, `Prayer` (10 values) + `PrayerWithRecordings`, `UploadState` (sealed), `mosque_request`, `mosque_publisher`, `mosque_location`, `day_schedule_entry`.
- **Use-case audit: 1 Meaningful** (`UploadRecording` — but hand-rolled `StreamController`, no `onCancel`, `ServerFailure(error.toString())` leaks internals, doesn't implement `UseCase`), **1 meaningful service** (`RamadanStatusService` — should return enum not String), **~14 Thin Wrappers**. Missing UCs for the hard ops (months, schedule CRUD, videos, notifications, file validation) — worst of both worlds.
- **Critical bugs**: `AddMosqueUseCase` drops `latitude/longitude` (data loss); `DeleteRecordingParams.mosqueId` accepted-and-ignored; `AddPublisherUseCase` skips `UseCase` interface.

## Entities / Repositories
- Clean repo interfaces (`Mosque`, `Recordings`, `RamadanDays`, `MosqueRequests`, `DaySchedule`, `Location`); `VideoRepository` has none.

## Data Sources
- `MosqueRemoteDataSource.getMosques`: **`.limit()` + `.range()` both** (redundant), **no `order()`** → unstable pages; `addMosque` relies on DB default for `admin_id`.
- `RecordingsRemoteDataSource`: orders by `prayer_name` lexicographically (wrong canonical order); R2 key has **unsanitized spaces/custom names**, no `contentType`, `duration` always null; **two incompatible R2-key extraction strategies** (Uri.path vs `.dev/` split) → orphaned files.
- `MosqueRequestsRemoteDataSource.accept`: select → insert → update, **no transaction** — retry duplicates mosque; no client RBAC.
- All datasources: catch-all `throw ServerException()` loses Postgrest codes. `RamadanDays/DaySchedule` datasources not read (Unknown).

## Models
- `MosqueModel`: tolerant count parsing (good) but unchecked `id/name` (null crash); asymmetric toJson.
- `RecordingModel`: `sheikh_name ?? 'غير معروف'` masks nulls; **unknown DB prayer collapses to `other` then round-trips** (corruption loop).
- `DailyVideoModel`: strict `as String` casts + `DateTime.parse` — malformed JSON crashes.

## External Dependencies
`supabase_flutter`, `riverpod+get_it` (dual DI), `chewie+video_player`, `just_audio*+on_audio_query`, `geolocator+geocoding+permission_handler+flutter_map+latlong2`, `file_picker`, `url_launcher`, `dio`, `firebase_*`, `connectivity_plus+internet_connection_checker` (duplicate), `shared_preferences`, `path_provider`, `crypto`.

## Business Rules
9 fixed prayers + Other; 100MB audio cap (widget-hardcoded); red/yellow/green day status; pending deleted after upload; videos ordered `created_at asc`; request→approve sets `admin_id=requested_by`.

## UI Rules
RTL Arabic; admin FAB gate app-side only (`mosque_detail_page.dart:80-83`); upload button disabled from `UploadState`.

## Error States
- Good: day detail (retry both), video widget (error card, no retry button), upload snackbar (no retry), picker typed taxonomy.
- Bad: list wipes on loadMore/refresh/requests-mutations; `availableMonths` hides errors; schedule mutations return `bool false` swallowing Failure; daily-video list discards error, no retry.

## Loading States
- `loadMore`/refresh/requests use full `loading()` wipes (should be `copyWithPrevious` + footer); ramadan days correct with `copyWithPrevious`; upload progress only in picker.

## Empty States
- Video empty covered; months-empty ambiguous; mosque-list empty Unknown (page not read); per-prayer empties presumed.

## Edge Cases
| Case | Status |
|---|---|
| Invalid input (`_selectedPrayer!` unwrap, weak `Args.validate()`) | Partially |
| Network fail | Partially (retry path exists but video/recordings bypass it) |
| Timeout | Partially (R2 uploads have none) |
| Logged-out upload | Not (null `publisher_id` written) |
| Non-admin approve/upload | Not (app-side FAB only; RLS unverified, permissive per schema audit) |
| Null/malformed JSON | Not (strict casts) |
| Double-tap upload / double-accept | Not (non-idempotent; double-accept creates 2 mosques) |
| Offline | Partially (fast-fail some paths; offline router redirects to login — loop) |
| Unknown prayer value | Not (collapses to Other) |
| Large data / N video players | Partially (pagination unstable; O(n) players init off-screen) |
| Pagination bounds | Not (no guards; exact-multiple wasted fetch) |
| File failures / orphan deletes | Not (unguarded `length()`, dual key parsing, swallowed pending cleanup) |
| Bad-route args | Partially (validated per type; `Mosque` vs `MosqueDetailArgs` mismatch) |
| State restoration | Not (by-value entities, global stale providers, never-reset UploadState, late-controller dispose hazard) |

## Tests
- Present: `ramadan_status_service`, `open_mosque_in_maps_usecase`, `prayer`, `ramadan_month_factory`, `upload_recording_notifier` (strongest), `add_mosque_page`, `mosque_info_page` (shallow), `mosque_repository`. Measured: `mosques/data 1.5%`, `domain 16.1%`, `presentation 39.3%`.

## Missing Tests
Pagination/loadMore/`addMosque`; ramadan error-with-previous + months masking; requests atomicity + non-admin fetch; schedule divergence + bool swallowing; upload stream ordering + pending-cleanup branch; **lat/lng drop**; `VideoRepository` paths; model null/malformed; `Prayer.fromString` collapse; router mismatch; widget dispose-before-init; datasource pagination.

## Performance
- Whole-detail rebuild on auth tick; `loadMore` full-list rebuild; global never-disposed providers leak across mosques; N `VideoPlayerController`s; double `File.length()`; months refetch per open; `addMosque` refetches page 0 instead of prepend. Chewie dispose correct except missing `mounted` guard + late-init hazard.

## Security
- **RBAC app-side only; RLS permissive** (`Mosques INSERT` any authed incl. anonymous; `Profiles SELECT USING (true)` exposes emails; only `mosque_requests` has admin check). Approve is tamperable client 3-step; null `publisher_id` writes; guessable R2 keys, no signed URLs; email enumeration via `addPublisher`. See ENGINEERING_AUDIT §10.

## Technical Debt (ranked)
1. `VideoRepository` outside arch 2. lat/lng drop 3. pagination defect + dual key parsing 4. duplicate schedule providers + global scoped data 5. `Prayer.fromString` collapse + strict casts 6. non-atomic approve + app-side RBAC + null publisher 7. fire-and-forget uploader 8. months/mutation error swallowing 9. video widget init hazard + N players 10. dual DI + duplicate connectivity libs 11. untyped nav contracts.

## Refactor Requirements
See REFACTOR_PLAN.md Phase 2 (arch parity: video entity + `Either`, pagination fix, atomic RPC approve, RLS hardening, upload hardening, model safeParse, provider scoping, video widget guards, router Args standardization) + Phase 4 (12 missing suites).

## Engineering Assessment
Architecture PARTIAL (clean skeleton, video shadow stack, DI-in-UI), Code Quality WEAK (data-loss bug, non-atomic writes, corruption loops), Testing WEAK (1.5% data), Edge Cases WEAK, Performance PARTIAL (correct patterns, scoping defects), Security WEAK (client-side RBAC), Documentation PARTIAL.

## Last Reviewed
2026-09-24 (full engineering audit; `flutter test --coverage` measured). Supersedes the 25-line stub previously in this file.
