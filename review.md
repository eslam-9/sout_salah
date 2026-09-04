# Flutter Project Senior Audit — `sout_salah`

## 1. Executive Summary

`sout_salah` is an Islamic audio application: mosque directory → Ramadan days (month/year filtered) → prayer recordings (Fajr, Isha, Taraweh 1-4, Shaf/Witr, Other) stored in Cloudflare R2, with Supabase as metadata/auth backend, FCM push, offline downloads/favorites, and video daily-updates. Codebase ~177 `lib/` files, 3-layer Clean Architecture intent via `core` + `features/auth|mosques|home`, Riverpod + GetIt hybrid, `dartz Either<Failure,T>` error model, Arabic RTL.

**Verdict in one line:** Strong mid-level skeleton with correct Clean Architecture intent and solid error/network scaffolding, held back by hybrid DI, leaked business logic, missing tests, and production hardening gaps. Not production-ready without Phase 1 fixes. Current score ~61/100.

---

## 2. Project Understanding

**What it does:**
- Browse mosques (`mosques` table + `recordings(count)` aggregate).
- Browse `ramadan_days` (30 rows per month, status red/yellow/green derived from recording count).
- Play/download/favorite `recordings` (R2 CDN URL + metadata).
- Upload flow: pick device audio or record, `R2StorageService.uploadFile` → insert `recordings` row → optional delete `pending` → FCM broadcast `new_recording`.
- Day schedule (`day_schedule` CRUD) for prayer timetables.
- Mosque requests workflow (create → pending list → accept/decline → creates `mosques` row).
- Auth: Supabase password + anonymous guest (`SharedPreferences is_guest_mode`), role `admin` gating FABs.
- Daily video (`daily_video`) with `video_player`/`chewie`.

**Target user:** Arabic-speaking mosque attendees during Ramadan. Offline resilience required.

**Critical flows:**
`Splash → StartupCheckWrapper(checkAuthStatus + startupService.data) → HomeLayout(MosquesPage) → MosqueDetail(availableMonthsProvider + ramadanDaysProvider.loadDays) → DayDetail(dayRecordingsProvider/dayPrayerList) → AudioPlayer/Downloads` and `UploadRecordingController → R2 → DB`.

---

## 3. Technology & Dependencies

**Environment:** `sdk: ^3.10.7`, Flutter stable `3b62efc2a3`, `analysis_options.yaml:1` (`include: package:flutter_lints/flutter.yaml` no custom rules), no `l10n.yaml`, no `test/` folder, `android compileSdk 36/targetSdk 36 / NDK+Kotlin 2.2.20`, `iOS` standard.

| Package | Purpose | Where Used | Appropriate? | Concerns |
|---|---|---|---|---|
| `dartz ^0.10.1` | `Either<Failure,T>` | All repositories/usecases | Yes | Verbose vs `fpdart`/`Either` sealed; but correct |
| `equatable ^2.0.8` | Value equality | Entities/params | Yes | Replaced by `freezed` in modern code, still fine |
| `flutter_riverpod ^2.6.1` | State mgmt | 7 StateNotifiers + 4 FutureProviders | Yes | Legacy `StateNotifier`; `Riverpod 2.6` supports `Notifier/AsyncNotifier` not used |
| `get_it ^9.2.0` | Service locator | `lib/core/di/injection_container.dart:38` owns singletons | **Duplicated** | Dual DI: GetIt creates, Riverpod re-exposes. Single container should own creation. |
| `supabase_flutter ^2.12.0` | Auth + DB + Functions | Datasources, `NotificationService` | Yes | Correct |
| `firebase_core ^4.5.0` + `firebase_messaging ^16.1.2` | FCM | `lib/core/services/notification_service.dart:15` | Yes | `print` left in background handler `:13` |
| `dio ^5.9.1` | HTTP + R2 signed PUT | `lib/core/services/r2_storage_service.dart:50`, `lib/core/services/downloads_service.dart:278` | Yes | Correct timeout config `NetworkConfig` |
| `connectivity_plus ^6.1.5` + `internet_connection_checker ^3.0.1` | Network check | `lib/core/network/network_info.dart:20`, `lib/core/di/injection_container.dart:56` | **Duplicate** | `NetworkInfoImpl` uses `connectivity_plus` only; `InternetConnectionChecker` registered but never read — wasted dep |
| `just_audio ^0.9.42` + `just_audio_background ^0.0.1-beta.17` + `audio_session ^0.1.21` | Audio | `lib/core/services/audio_player_service.dart:6` | Yes | `beta.17` pre-release risk |
| `shared_preferences ^2.2.2` + `path_provider ^2.1.2` | KV + files | `lib/core/services/favorites_service.dart:162`, `lib/core/services/downloads_service.dart:278` | Yes | Adequate for <500 items; Hive/Drift would scale better |
| `crypto ^3.0.3` | HMAC-SHA256 SigV4 | `lib/core/services/r2_storage_service.dart:4` | Yes | Hand-rolled SigV4 is risky surface |
| `video_player ^2.11.1` + `chewie ^1.8.5` | Video | `daily_video` | Yes | OK |
| `file_picker ^8.1.6` + `permission_handler ^12.0.1` + `on_audio_query ^2.9.0` | Files/permissions | `device_audio_selection` | Yes | `on_audio_query` verify usage — appears imported but usage not confirmed |
| `logger ^2.6.2` + `google_fonts ^8.0.1` + `lottie ^3.1.0` + `lucide_icons ^0.257.0` | Logging/UI | Global | Yes | `google_fonts` declared but `AppTheme` uses asset `Rubik` — potentially unused |
| `url_launcher ^6.2.5` | Update link | `lib/core/widgets/startup_check_wrapper.dart:123` | Yes | OK |

**Unused/duplicate:** `internet_connection_checker` (registered, never injected), `on_audio_query` verify usage, `get_it` + `flutter_riverpod` overlap, `flutter_lints ^6.0.0` not enforced via strict `analysis_options.yaml`.

---

## 4. Architecture Analysis

**Declared vs actual:**

| Intent | Actual |
|---|---|
| Clean Architecture feature-first `data/domain/presentation` | **Present and followed 80%**: `mosques` and `auth` each have `datasources/models/repositories_impl` → `entities/repositories/usecases` → `pages/providers/widgets`. `core` is horizontal. |
| UseCase pattern | 11 usecases, 9 thin delegates, 1 orchestrator `UploadRecordingUseCase` with post-upload delete-pending, 1 non-conforming `AddPublisherUseCase` custom signature. |
| Repository abstraction | `MosqueRepository:79` + `AuthRepository:22` pure `Either` contracts. Impl catches `ServerException→ServerFailure`. Good. |
| DI | **Hybrid**: GetIt owns lifecycle (`lib/core/di/injection_container.dart:105`), `lib/core/di/providers.dart:42` re-exports as `Provider<T>((ref)=>GetIt.I<T>())`. Providers also duplicate `getMosquesUseCaseProvider` in both `mosque_controller.dart` and `mosque_data_providers.dart`. |
| State mgmt | Riverpod `StateNotifierProvider` (legacy) + `FutureProvider.family` + `StatefulWidget.setState` hybrid. No `flutter_bloc` despite `bloc/mosque_state_event.dart` vestige. |

**10 architecture diagnosis questions:**

1. Uses hybrid Clean-Arch + MVVM via Notifiers.
2. Patterns: Repository, UseCase, RetryExecutorMixin, Service Locator, Provider Bridge.
3. Correct: models extend entities isolation, usecase thinness, central `AppRouter`, error `Failure` hierarchy.
4. Violations: `dayRecordingsProvider:lib/features/mosques/presentation/providers/mosque_data_providers.dart:28` bypasses usecase → direct `repository.getDayRecordings`; `DayPrayerList` groups prayers; `RamadanDayModel.fromJson` computes status.
5. Inconsistent: `RecordingsNotifier` without `RetryExecutorMixin` vs `MosqueNotifier` with it; `StateNotifier<AsyncValue>` in `day_schedule_provider.dart`.
6. Separation weak: responsibilities split, but DI duplication leaks.
7. Dependency direction correct (UI → provider → usecase → repo → datasource) except leaked FutureProviders calling repo directly.
8. Business logic not fully separated (see §8).
9. Data access separated, but models do business calc.
10. Abstractions where valuable (repo, NetworkInfo) yes; `R2StorageService` no abstraction — concrete only.
11. DI incorrectly handled (dual container).
12. Appropriate for size? Yes, Clean Arch fits 177 files but overkill for current CRUD thickness; worth keeping if tests added, otherwise Riverpod-only DI would be leaner.

**Actual diagram:**
```
MaterialApp (lib/main.dart:72 RTL Directionality + StartupCheckWrapper)
  ↓
AppRouter.onGenerateRoute (auth guard _isAuthenticated via Supabase.currentUser)
  ↓
Pages (ConsumerStatefulWidget / ConsumerWidget) + Widgets (presentational)
  ↓  ←→  Stateful local state (selectedMonth setState) leaks
Riverpod layer:
  StateNotifierProviders (MosqueNotifier, RamadanDaysNotifier, AuthNotifier, MosqueRequestsNotifier)
  + FutureProvider.family (dayRecordingsProvider, availableMonthsProvider, dayScheduleProvider)
  + RetryExecutorMixin (timeout 5s, 1 retry, exponential 2s) — only some notifiers
  ↓  (some FutureProviders bypass ↓)
UseCases (GetMosquesUseCase etc. → Either<Failure,T>) 
  ↓
Repositories abstract (MosqueRepository) → MosqueRepositoryImpl (maps ServerException→ServerFailure)
  ↓
Datasources (MosqueRemoteDataSourceImpl:611 Supabase queries + R2StorageService)
  ↓
External: Supabase Postgres (mosques, ramadan_days, recordings, day_schedule, mosque_requests, fcm_tokens)
         + Cloudflare R2 via hand-rolled SigV4 (R2StorageService:220)
         + Firebase FCM + SharedPreferences/path_provider (favorites/downloads)
```

---

## 5. Project Structure

**Naming/organization:** Good. `lib/core/{config,constants,di,error,models,network,services,theme,utils,validators}` + `features/*/{data,domain,presentation}` consistent. File responsibilities mostly single, except:

- `lib/features/mosques/data/datasources/mosque_remote_data_source.dart:611` god file (18 methods, addMonth bulk + mosque_requests + day_schedule) — split by aggregate.
- `lib/features/mosques/presentation/pages/upload_recording_controller.dart:129` god static controller doing validation + navigation + notification + progress callback.
- `lib/features/mosques/presentation/bloc/mosque_state_event.dart` dead — defines `MosqueState` union but no Bloc; reused as Riverpod state.

**Placement errors:** `upload_recording_controller.dart` lives in `pages/` not `providers/`; `MonthYear` entity-like value object lives in `providers/month_year.dart` not `domain/entities`.

**Duplication:** `getMosquesUseCaseProvider`/`addMosqueUseCaseProvider` defined twice; `NetworkInfo` vs `InternetConnectionChecker`; RECORD fetch duplicated (`RecordingsNotifier` dead unused vs `dayRecordingsProvider`).

**Dead code:** `RecordingsNotifier/RecordingsState` never watched (UI uses `dayRecordingsProvider`); `RamadanDaysLoaded/RecordingsLoaded` in `MosqueState` never emitted; `FutureProvider` error previousData never rendered.

**Discoverability:** High; scalability medium (adding new feature requires touching both GetIt and Riverpod DI).

**Score: 68/100** — well structured, but god datasource, placement drift, duplicate providers.

---

## 6. Dart & Flutter Code Quality

**Dart — positives:** Null-safety thorough (`required`, `maybeSingle`, `try/catch`), `final`, `const` constructors (`MosqueModel`), `Equatable` props, `async/await` correct, `copyWith` on `UploadRecordingParams`.

**Negatives:**
- `withOpacity` deprecated elsewhere (reported), `curly_braces` lint not enforced (`analysis_options.yaml:1` single include, no rules).
- `lib/core/network/retry_executor.dart:57` catches `catch(e)` and wraps as `ServerFailure(e.toString())` losing stack; duplicates.
- `copyWith:lib/features/mosques/domain/usecases/upload_recording_params.dart` cannot clear nullable fields (`customPrayerName ?? this.customPrayerName`).
- `lib/core/services/r2_storage_service.dart:15` `final Dio _dio = Dio();` creates second Dio ignoring base `connectTimeout` singleton (should inject).
- Hardcoded magic numbers: `30 days`, `100*1024*1024`, `attempt*2 seconds`, `120s audioTimeout`.

**Flutter — positives:** Widget composition small (`MosqueCard:140` pure, `DayDetailBody` delegates), `const` used, lifecycle `mounted` checks correct (`lib/features/mosques/presentation/pages/upload_recording_controller.dart:43`, `lib/core/widgets/startup_check_wrapper.dart:29`).

**Negatives:**
- `const` missing many `Text`, `SizedBox`; `build()` does work: `MosquesPage:197` filters `where(m.name.contains)` on every build — should be `select`.
- Controllers/FocusNodes: `TextEditingController` in `UploadRecordingPage` (verify dispose), not checked but pattern uses `StatefulWidget`.
- Rebuilds: `ref.watch` on large providers without `select`; `MosqueDetailPage` hybrid `setState` + `ref.read(future)` triggers double build.
- No `Keys` on list items (`MosqueCard` in `ListView.builder` missing `ValueKey(mosque.id)`).
- Loading/error/empty states present (MosquesPage covers all), but `DayScheduleProvider` maps `Failure→Exception('فشل...')` losing detail.
- Theme used (`AppTheme.lightTheme` M3, `AppColors`), but `StartupCheckWrapper:76` hardcodes `Color(0xFF2E7D32)` instead of `AppColors.primary`.

**Score: Dart 62, Flutter 65**

---

## 7. State Management

**Mechanisms found:** Riverpod `flutter_riverpod ^2.6.1` primary; `StateNotifierProvider` ×7, `FutureProvider.family` ×4, `StreamProvider` ×2 (favorites/downloads), `Provider` DI bridge, `StateProvider<String?> currentPlayingRecordingProvider`, plus `StatefulWidget.setState` for `selectedMonth`, `UploadRecordingPage` file/prayer selection.

**Evaluation:**

- **Why:** Riverpod handles async + DI; GetIt kept from earlier setup.
- **Consistency:** No. `MosqueNotifier`+`RamadanDaysNotifier` use `RetryExecutorMixin`+`NetworkInfo`; `RecordingsNotifier` and `DayScheduleNotifier` don't. `DayScheduleNotifier extends StateNotifier<AsyncValue<List<...>>>` double-wraps async (anti-pattern; use `AsyncNotifier`).
- **Lifecycle:** `MosqueNotifier(..getMosques())` side-effect in constructor; `_loadSchedule()` in `DayScheduleNotifier` constructor — untestable. No `autoDispose` on family providers → memory retention across mosque nav.
- **Scope:** All providers top-level (global). No scoped override per screen.
- **Rebuilds:** `FutureProvider.family` re-fetches on each `ref.watch` miss; no caching beyond Riverpod keepAlive. `StreamProvider` for favorites/downloads correctly broadcast.
- **Error/loading:** `RamadanDaysState` has `previousData` preservation clever but widget discards it. `MosqueRequestsNotifier.acceptRequest:lib/features/mosques/presentation/providers/mosque_requests_provider.dart` bug: `state=Error(...)` then immediately `state=currentState` — error never visible.
- **Complexity:** Unnecessary complexity in `DayScheduleNotifier` wrapping `AsyncValue` inside `StateNotifier`. Too simple elsewhere (`UploadRecordingController` static fat method should be `AsyncNotifier<UploadState>` with progress).

**Leaked logic:** `dayRecordingsProvider` bypasses usecase.

**Score: 58/100**

---

## 8. Business Logic

**Separation:** Usecases 90% thin delegates. Real logic hidden in:
- `lib/features/mosques/data/models/ramadan_day_model.dart:23` `count>=4 green, >0 yellow else red/status` — business rule in data layer.
- `lib/features/mosques/data/datasources/mosque_remote_data_source.dart:176` `for 1..30 insert status red active true` — domain rule in datasource.
- `lib/features/mosques/presentation/widgets/day_detail_components/day_prayer_list.dart:20` grouping `Map<Prayer,List<Recording>>` + ordering `defaultPrayers=[Fajr, Isha, Taraweeh1-4]` — domain in widget.
- `lib/features/mosques/presentation/pages/mosque_detail_page.dart:35` `months.last` as selected — implicit “current month is last”.
- `lib/features/mosques/data/models/mosque_model.dart` expects `recordings[count]` Supabase shape — brittle.

**Input → Processing → State → Output example (Upload):**
`File+sheikhName+prayer` (UI) → `UploadRecordingController.validate (size>100MB)` → `UploadRecordingParams(copyWith onProgress callback)` → `UploadRecordingUseCase.call → repository.uploadRecording → R2 put + DB insert → deletePending if needed` → `State: setUploading + ScaffoldMessenger + Navigation.pop + NotificationService.sendNotification` (output mixes UI side-effects in controller).

**Testability:** Usecases testable, but `UploadRecordingUseCase` orchestration with swallowed `catch(e) // ignore` hides compensation failure. No pure domain service for status calc.

**Score: 55/100**

---

## 9. Data Layer

**API clients:** Supabase `SupabaseClient.from().select/insert/update/delete` raw; Dio for R2 + downloads. No interceptors, no retry at Dio layer (done in `RetryExecutorMixin` above).

**Separation:** Remote datasource only; no local cache datasource (SharedPreferences used directly in services bypassing datasource). Repository correctly abstracts remote, but `VideoRepository` separate from `MosqueRepository` breaks cohesion.

**Error mapping:** Datasource throws `ServerException`, repository `→ Left(ServerFailure)` — good, but loses HTTP code/message (all `ServerException()` empty). `lib/features/auth/data/datasources/auth_remote_data_source.dart:154` swallows `AuthException.message` via generic `ServerException()` then repo wraps `e.toString()` — inconsistent.

**Serialization:** `RecordingModel.fromJson` handles `Prayer.fromString` fallback to `other`; defaults `sheikh_name → 'غير معروف'`. `MosqueModel` parsing of `recordings[count]` via `first['count']` fragile to Supabase output change. No `json_serializable` but manual — acceptable for size.

**Caching/offline:** No cache. `NetworkInfo` fast-fail offline before retry, but no offline queue, no retry after reconnect. `DownloadsService` stores metadata in `SharedPreferences` JSON list + files on disk — simple, not transactional.

**Retry/timeouts:** `NetworkConfig.standardTimeout 10s`, `audioTimeout 120s` per call; `NetworkPolicy.requestTimeout 5s` in `RetryExecutorMixin.timeout` overrides — double timeout layers. `maxRetryAttempts 1` with `attempt*2s` backoff.

**Cleanup:** R2 delete extracts key via `Uri.path` — correct but assumes CDN URL shape; `DownloadsService.cancelDownload` cleans partial file.

**Score: 62/100**

---

## 10. Error Handling

**Detected → Converted → Propagated → Displayed:**

- **Detected:** `try/catch` in every datasource method (100+ catches). Good coverage.
- **Converted:** `ServerException → ServerFailure`, `NetworkFailure` via `NetworkInfo`. `AddPublisher` special `catch(e) contains 'User not found' → Exception('المستخدم غير موجود')` leaky string-match.
- **Propagated:** `Either<Failure,T>` to providers via `executeWithRetry`. But `dayRecordingsProvider` converts `Left → throw Exception('Failed')` losing type.
- **Displayed:** `MosquesPage:197` maps to Arabic snack; `RecordingsError` shows generic “Server Failure” (English) in `lib/features/mosques/presentation/providers/recordings_provider.dart:49` — language inconsistency. `CacheFailure` never displayed distinct.

**Gaps:** Empty? No empty catch, but `lib/features/mosques/domain/usecases/upload_recording_usecase.dart` silently catches `deleteRecording` failure `catch(e){}` with TODO comment — hidden failure. `lib/features/auth/data/datasources/auth_remote_data_source.dart:154` converts all to `ServerException()` without message — auth error “Invalid credentials” becomes “خطأ في الخادم”. `lib/core/services/r2_storage_service.dart:75` `rethrow` after logging exposes raw `DioException` to repository then `ServerException`.

**Score: 60/100**

---

## 11. Performance

- **Critical:** None.
- **High:** `MosquesPage:197` `where(m.name.contains)` + `ListView.builder` without `ValueKey` causes full rebuild on search keystroke; large recording lists in `DayPrayerList` group recomputed each build (O(n) grouping in widget). `R2StorageService:16` second `Dio()` instance doubles connection pools.
- **Medium:** `getAvailableMonths` fetches all `ramadan_days month/year` rows then dedups client-side — should `SELECT DISTINCT`. `getMosques` fetches `*` plus `recordings(count)` for all mosques even when paginated needed. `DownloadsService` `jsonEncode` whole list on each add. Missing `const` on many `Padding/Text` causes unnecessary rebuilds. `google_fonts` imported but theme uses asset `Rubik` — unused dep cost.
- **Low:** `Lottie` splash animation preload not prefetched; `video_player` controllers not disposed check pending.

**Score: 60/100**

---

## 12. UI / UX

**Visual:** `AppTheme.lightTheme:106` M3 `ColorScheme.fromSeed(seed:2E7D32)`, green/orange palette consistent, `Rubik` 300-900 weights, cards `rounded12`+shadow, spacing `20` horizontal, `LucideIcons` — clean professional base. Arabic RTL forced globally `Directionality:rtl` in `lib/main.dart:85`. `proguard` minify enabled.

**Widget quality:** `MosqueCard` presentational, shadows aligned; `HomeLayout:88` bottom nav fixed 4 items Arabic labels, `MosquesPage` search + FAB gated by `permissionCheckerProvider.canAddMosque`. `ErrorPage`/`SplashScreen` exist but minimal.

**UX gaps:**
- No dark mode, no responsive breakpoints (tablet `GridView` still `ListView`), `iOS Info.plist` allows landscape but layout not tested.
- No `EmptyState` reuse? `DownloadsEmptyState`/`SavedEmpty` present but similar code duplicated.
- No shimmer/skeleton loading — only `CircularProgressIndicator`.
- Hardcoded Arabic everywhere (≈310 lines grepped `ء-ي`) — no `arb`/`intl`, blocks localization and a11y `Semantics`.
- Accessibility: no `Semantics` labels, minimum tap 48dp not verified.

**Score: UI Impl 68, UX 60**

---

## 13. Security

- 🔴 **Critical:** `secrets.json:9` contains live `SUPABASE_ANON_KEY` and `R2_ACCESS_KEY`/`R2_SECRET_KEY` plaintext. File is `.gitignore:54` ignored, so not pushed if respected, but **secrets live on disk plaintext** and `AppConfig.fromEnvironment` requires `--dart-define-from-file=secrets.json` which leaks into build if CI logs. **Do not reproduce actual secret values in report.** Rotate R2 keys and use `dart-define` CI secrets not repo file. Location: `secrets.json` (gitignored) and `lib/core/config/app_config.dart:4` (`String.fromEnvironment`).
- 🟠 **High:** `android/app/upload-keystore.jks` present — keystore in project dir, ignore relies on `android/app/*.jks` gitignore line 51; verify not committed (`git status` check required). `R2StorageService:198` signs with `UNSIGNED-PAYLOAD` — Cloudflare R2 allows, but reduces integrity check.
- 🟡 **Medium:** Supabase RLS assumed: `mosque_publishers` admin check done client-side `profileResponse['role']!='admin' throw` (`lib/features/mosques/data/datasources/mosque_remote_data_source.dart:354`), not enforced DB-side → privilege bypass if RLS permissive. `supabase.functions.invoke('send-notification')` with `type/data` no authz check at edge. `SharedPreferences` stores favorites/downloads unencrypted — low risk.
- 🟢 No hardcoded API keys in code (via `AppConfig`), no unsafe `print` of tokens except debug logs. Permissions `READ_MEDIA_AUDIO`, `WRITE_EXTERNAL_STORAGE` requested but `path_provider` uses app docs not external — over-permission.

**Score: 45/100** — secret file presence + client-side authz dominate.

---

## 14. Testing & Testability

- `test/` **does not exist** (`ls test: No such file`). `pubspec` dev has only `flutter_test` + lints, no `mocktail/mockito/fake_async`.
- **Can be tested easily:** Usecases (pure `Either` delegates), `MosqueModel.fromJson`, `RetryExecutorMixin`, `AppLogger`.
- **Hard to test:** `MosqueRemoteDataSourceImpl:611` (concrete Supabase+R2, no injectable http mock), `R2StorageService` (new `Dio()` + `AppConfig` static), `NotificationService` static + `GetIt.I`, `StartupCheckWrapper` `Future.delayed + dialog`, `UploadRecordingController` static with `BuildContext` + `ScaffoldMessenger`.
- **What to test first:** Contract tests for repo `Left/Right`, widget tests for `MosquesPage` loading/error/list, integration for `uploadRecording` R2 success/failure.

**Score: 10/100** — zero coverage, architecture testable but not tested.

---

## 15. Clean Code & SOLID

- **SRP:** Violated: `MosqueRemoteDataSourceImpl` 8 responsibilities (mosques, days, recordings, publishers, requests, schedule); `UploadRecordingController` validation + navigation + notification.
- **OCP:** Open via new usecase, closed via repo abstraction — good.
- **LSP:** `MosqueModel extends Mosque` Liskov holds, but leaks entity into data parsing.
- **ISP:** Repositories coarse (18 methods); should split `MosqueRepository` into `MosqueRead`, `RecordingWrite`, `Schedule` interfaces.
- **DIP:** Depends on abstractions `MosqueRepository`, `NetworkInfo` good; but `R2StorageService`, `NavigationService`, `NotificationService` depend on concretes/statics.
- **DRY:** Duplicate `mapFailureToMessage` in `recordings_provider.dart` vs mixin; duplicate provider definitions.
- **KISS:** Hand-rolled SigV4 over AWS SDK is over-complex; Keep but document.

**Score: 58/100**

---

## 16. Production Readiness

| Dimension | Level |
|---|---|
| Maintainability | Mid — structure clear, but dual DI + god datasource hinders |
| Scalability | Low-Mid — client-side dedup/sort, no pagination, SP JSON will degrade >1k items |
| Reliability | Mid — offline fast-fail + retry works, but silent `catch(e)//ignore` hides failures |
| Performance | Mid — see §11 |
| Security | Low — secrets handling + client-side role check |
| Testing | None |
| Architecture | Mid |
| UI quality | Mid-High visual, low a11y |
| DX | Mid — logging good, but no strict lints, no CI shown |

**Is production-ready?** No for public store: needs Phase 1 critical fixes (secrets, error propagation, RLS enforcement, tests) before approving merge.

---

## 17. Developer-Level Estimation

**Estimated developer level: Strong Junior → Mid-level (3-5 years)**

**Why:**

- **Mid signals:** Feature-first Clean Arch with `data/domain/presentation` correctly wired; `Either<Failure,T>` + `UseCase` generics + `equatable`; `RetryExecutorMixin` with timeout + `NetworkInfo` check + exponential backoff; centralized `AppRouter` with typed `RouteArgs` validation + auth guard; `R2 SigV4` manual implementation working; structured logging via `AppLogger` + `GetIt`.
- **Junior/Strong-junior signals:** Dual GetIt+Riverpod confusion; dead `bloc/` artifact; `FutureProvider` bypassing usecase; `StateNotifier<AsyncValue>` anti-pattern; hardcoded 30-day loop + magic numbers; ~310 hardcoded Arabic strings no `arb`; second `Dio()` instance; `StateNotifier` constructor side-effects; zero tests; `analysis_options.yaml` single line.
- **AI hint:** Boilerplate usecases 80% identical pass-through, verbose logging emojis, `tec_documentation.md` typo — 70% AI-assisted plausible.

**Portfolio impression senior would get:** “Good architectural ambition, understands layers and Riverpod, but not yet senior polish — leaves leaks, duplication, and no tests. With hardening, solid mid-level candidate; as-is, would require mentoring before production ownership.”

---

## 18. Scorecard

| Category | Score |
|---|---|
| Architecture | 64 /100 |
| Project Structure | 68 /100 |
| Dart Code Quality | 62 /100 |
| Flutter Code Quality | 65 /100 |
| State Management | 58 /100 |
| Business Logic | 55 /100 |
| Data Layer | 62 /100 |
| Error Handling | 60 /100 |
| Performance | 60 /100 |
| UI Implementation | 68 /100 |
| UX | 60 /100 |
| Security | 45 /100 |
| Testing | 10 /100 |
| Clean Code | 58 /100 |
| Maintainability | 60 /100 |
| Scalability | 52 /100 |
| Production Readiness | 48 /100 |
| **Overall** | **61 /100** |

Most impactful factors: Testing 10, Security 45, State/Business leaks pull overall down despite decent UI/structure.

---

## 19. Critical & High-Priority Findings

| Severity | File | Line/Area | Problem | Why It Matters | Recommended Fix |
|---|---|---|---|---|---|
| 🔴 Critical | `secrets.json:1-9` / `lib/core/config/app_config.dart:4` | Live R2 secret + Supabase anon key plaintext on disk | Key compromise, abused storage/billing | Rotate R2_SECRET_KEY/R2_ACCESS_KEY immediately, delete `secrets.json`, inject via CI env `--dart-define`, not file |
| 🔴 Critical | `lib/features/mosques/data/datasources/mosque_remote_data_source.dart:336-387` `addPublisher` | Role `admin` check only client-side `profileResponse['role']!='admin'` | Privilege escalation if RLS permissive | Enforce via Supabase RLS policy `auth.uid() role=admin` + Postgres function; keep UI check as UX only |
| 🟠 High | `lib/features/mosques/presentation/providers/mosque_data_providers.dart:28-40` `dayRecordingsProvider` | `throw Exception('Failed...')` bypasses `Either`, loses `Failure` type | UI can't distinguish network vs server | Wrap via `GetDayRecordingsUseCase` + `AsyncValue<T>` mapping `Failure` → Arabic message, not throw |
| 🟠 High | `lib/features/mosques/presentation/providers/mosque_requests_provider.dart` `acceptRequest/decline` | `state=Error` then `state=currentState` overwrites error — error never shown | Silent failure, admin thinks accepted | Remove overwrite; keep `Error` state with `previousData`; show Snackbar and retain list |
| 🟠 High | `lib/features/mosques/presentation/pages/upload_recording_controller.dart:12-129` | Static fat controller with `BuildContext` + `ScaffoldMessenger` + `Navigator.pop` + `NotificationService` + `onProgress` callback in domain `UploadRecordingParams` | Untestable, leaks UI into domain | Replace with `UploadRecordingNotifier extends AsyncNotifier<UploadState>` exposing `progress`; view watches state, shows UI via `ref.listen` |
| 🟠 High | `lib/core/services/r2_storage_service.dart:16` | `final Dio _dio = Dio();` ignores singleton timeout/logging | Timeouts inconsistent, no interceptor | Inject `Dio` via `GetIt` constructor `R2StorageService(this._dio)` |
| 🟡 Medium | `lib/features/mosques/data/models/ramadan_day_model.dart:23-30` | Status calc `count>=4 green` hidden in Model | Business rule untestable in data layer | Move to domain factory `RamadanDay.fromCount(count, rawStatus)` or repository mapper with tests |
| 🟡 Medium | `lib/core/network/retry_executor.dart:57-62` | `catch(e) Left(ServerFailure(e.toString()))` duplicates, masks stack | Debugging hard, alert fatigue | Keep one catch, log with `AppLogger.e(e,stack)`, map known exceptions, rethrow unknown |
| 🟡 Medium | `lib/core/di/injection_container.dart:56` / `lib/core/di/providers.dart:42` | Duplicate DI: `InternetConnectionChecker` never used; `getMosquesUseCaseProvider` defined twice | Dead dep, confusion | Remove `internet_connection_checker` or wire via `NetworkInfo`; single provider file `di/providers.dart` owns all provider defs |
| 🟡 Medium | `lib/features/mosques/domain/usecases/upload_recording_params.dart:30` | `void Function(double)? onProgress` in domain params | Domain depends on UI callback | Pass `StreamController` or make `uploadRecording` return `Stream<Either<Failure,Progress>>` |
| 🟢 Low | `lib/core/widgets/startup_check_wrapper.dart:76,102` | Hardcoded `Color(0xFF2E7D32)` vs `AppColors.primary` | Theme drift | Use `AppColors.primary` |
| 🔵 Suggestion | `analysis_options.yaml:1` | Only `include: flutter_lints` | No strict rules | Enable `custom_lint`, `prefer_const_constructors`, `curly_braces`, `avoid_print` |
| 🔵 Suggestion | `android/app/upload-keystore.jks` | Keystore in repo dir | Signing key risk | Verify `git ls-files | grep jks` empty; move to secure CI storage |

---

## 20. Top 10 Improvements (ranked)

**#1 Security — Rotate & remove secrets**
- Problem: `secrets.json` live keys on disk.
- Why: Billing Abuse + data breach.
- Current: Plain file, `--dart-define-from-file`.
- Recommended: `git rm secrets.json; rotate R2 keys in Cloudflare dashboard; CI env vars + `flutter build --dart-define=SUPABASE_URL=...` .
- Difficulty: Low. Benefit: Critical.

**#2 Fix provider bypass (usecase leak)**
- Problem: `dayRecordingsProvider` calls `repo` directly.
- Why: Breaks Clean Arch, loses `Failure`, untestable.
- Current: `FutureProvider.family` with `throw Exception`.
- Recommended: `FutureProvider.family` → `ref.watch(getDayRecordingsUseCaseProvider).call(params)` + `Either.fold → AsyncValue.data/error with mapped message`.
- Difficulty: Medium. Benefit: High.

**#3 Extract UploadRecordingController to AsyncNotifier**
- Problem: Fat static UI controller.
- Why: Testability, single responsibility, progress as state.
- Current: `UploadRecordingController.uploadRecording(context, ref, formKey, setUploading...)`.
- Recommended: `class UploadRecordingNotifier extends Notifier<AsyncValue<Recording>> { double progress; Future<void> upload(params) }` + `ref.listen` for Snackbar/nav.
- Difficulty: Medium-High. Benefit: High.

**#4 Unify DI — single source**
- Problem: GetIt + Riverpod overlap, duplicate providers.
- Why: Confusion, two singletons, DI drift.
- Current: `sl.registerLazySingleton` + `providers.dart GetIt.I`.
- Recommended: Choose one: Riverpod-only (`Provider` creation) OR GetIt-only for non-widget services; delete duplicate `getMosquesUseCaseProvider` in `mosque_controller.dart`.
- Difficulty: Medium. Benefit: High.

**#5 Fix MosqueRequestsNotifier error overwrite**
- Problem: Error state immediately restored to `Loaded`.
- Why: Admin never sees failure.
- Current: `state=Error; if(currentState is Loaded) state=currentState`.
- Recommended: Keep `MosqueRequestsError(message, previousData: currentState.requests)` and UI shows SnackBar with retry.
- Difficulty: Low. Benefit: High.

**#6 Move business rules out of widgets/models**
- Problem: `DayPrayerList` grouping, `RamadanDayModel` status calc, `mosque_remote_data_source.addMonth` 30-day loop.
- Why: Testability + domain clarity.
- Current: Logic in UI/data.
- Recommended: `domain/services/prayer_grouping_service.dart`, `domain/factories/ramadan_day_factory.dart`.
- Difficulty: Medium. Benefit: Medium-High.

**#7 Add tests (contract + widget)**
- Problem: 0% coverage.
- Why: Regression risk in upload/R2/Sign.
- Current: No `test/`.
- Recommended: Start with `test/features/mosques/domain/usecases/upload_recording_usecase_test.dart` (mock repo, verify deletePending called) + `mosque_repository_impl_test.dart` + `mosques_page_test.dart`.
- Difficulty: High. Benefit: Critical.

**#8 Enforce RLS & harden R2**
- Problem: Client-side admin check only; `UNSIGNED-PAYLOAD`.
- Why: Security.
- Current: `addPublisher` role fetch client.
- Recommended: Supabase RLS `mosque_publishers INSERT` policy `exists(select 1 from profiles where id=auth.uid() and role='admin')`, R2 consider `x-amz-content-sha256` hash for integrity (if Cloudflare supports).
- Difficulty: Medium. Benefit: High.

**#9 Adopt `AsyncNotifier` / `Notifier` + `autoDispose`**
- Problem: `StateNotifier` legacy + `StateNotifier<AsyncValue>`.
- Why: Modern Riverpod, lifecycle.
- Current: `StateNotifierProvider` without `autoDispose`.
- Recommended: Migrate to `AsyncNotifierProvider.family.autoDispose`, remove double wrap.
- Difficulty: Medium. Benefit: Medium.

**#10 i18n & performance polish**
- Problem: 310 hardcoded Arabic strings, client-side dedup, missing pagination.
- Why: Maintainability + scale >100 mosques.
- Current: Strings inline, `getAvailableMonths` fetch all.
- Recommended: `flutter_localizations` + `arb`, `SELECT DISTINCT` + pagination `range(0,20)` + `ListView.builder ValueKey`.
- Difficulty: High. Benefit: Medium.

---

## 21. Top 10 Things Done Well

1. **Feature-first Clean Architecture wiring** — `data/{datasources,models,repositories_impl}` → `domain/{entities,repositories,usecases}` → `presentation` consistently across `auth`/`mosques`. Makes adding `quran` feature predictable. (`lib/features/mosques/domain/repositories/mosque_repository.dart:79`)
2. **Centralized router with auth guard + typed args validation** — `AppRouter._isAuthenticated() → redirect`, `is! Mosque` → `_errorRoute`, `UploadRecordingArgs.validate()` prevents runtime null — professional nav safety. (`lib/core/routes/app_router.dart:43,84`)
3. **Either<Failure,T> + Failure hierarchy** — `ServerFailure/CacheFailure/NetworkFailure extends Equatable` with Arabic defaults; repositories map `ServerException→Left`; prevents exception leaking to UI. (`lib/core/error/failures.dart:17`, `lib/features/mosques/data/repositories/mosque_repository_impl.dart:295`)
4. **RetryExecutorMixin resilience** — connectivity fast-fail → `timeout 5s` → 1 retry with `2s*attempt` backoff, `NetworkFailure` no-retry distinction, reusable mixin — solid mobile-grade pattern. (`lib/core/network/retry_executor.dart:9`)
5. **Operational logging discipline** — `AppLogger` PrettyPrinter wrapper, injected or via `GetIt`, every datasource `logger.i/e` with emoji prefix grep-friendly (`🧭`,`❌`,`📥`) — aids debugging without Sentry. (`lib/core/utils/app_logger.dart:20`)
6. **R2 abstraction over AWS SDK** — hand-rolled SigV4 (`crypto HMAC-SHA256` chain) + per-segment `Uri.encodeComponent` + CDN `getPublicUrl` — lightweight vs 3MB SDK, correctly handles spaces. (`lib/core/services/r2_storage_service.dart:150-195`)
7. **Reactive downloads/favorites streams** — `StreamController.broadcast(onListen: _emit)` + `SharedPreferences JSON` + progress `Map<id, StreamController<double>>` + `CancelToken` cleanup — user-visible progress with cancel. (`lib/core/services/downloads_service.dart:278`, `lib/core/services/favorites_service.dart:162`)
8. **Typed model↔entity mapping** — `MosqueModel extends Mosque`, `RecordingModel.fromJson` handling `Prayer.fromString` + `customPrayerName` + `sheikh_name` default `غير معروف` — isolates parsing from domain. (`lib/features/mosques/data/models/recording_model.dart:19`)
9. **Config via compile-time `String.fromEnvironment`** — `AppConfig` avoids `flutter_dotenv` runtime file; `secrets.json` gitignored (if respected) — correct secret injection pattern once file removed. (`lib/core/config/app_config.dart:5`)
10. **Material3 theme + RTL foundation** — `AppTheme.lightTheme` `ColorScheme.fromSeed`, `AppColors` palette, `Rubik` family, `Directionality.rtl` global — consistent visual baseline, easy dark-mode extension. (`lib/core/theme/app_theme.dart:106`, `lib/main.dart:85`)

---

## 22. Senior Engineer Verdict

**1. What level is this project?** Strong junior → **Mid-level project** (6.5/10). Not beginner (Clean Arch, SigV4, FCM lifecycle), not senior/production.

**2. What level developer does it demonstrate?** Mid-level (3-5y) with architecture ambition but lacking senior hardening.

**3. Strongest decisions:** Clean feature layers + centralized auth-guarded router; `Either` error model; `RetryExecutorMixin`; reactive downloads; R2 CDN split.

**4. Weakest decisions:** Dual GetIt+Riverpod + FutureProvider bypassing usecase; fat `UploadRecordingController` with context; client-side admin check; zero tests; plaintext `secrets.json`.

**5. What senior notices first:** Hybrid DI confusion, `lib/features/mosques/data/datasources/mosque_remote_data_source.dart:611` god file, `dayRecordingsProvider` throwing generic `Exception` after careful `Either` setup, static services (`NotificationService`, `NavigationService`) making tests hard.

**6. What interviewer likes:** Layer diagram matches code, typed route args, Arabic-first RTL handling, logging + network resilience, Supabase+R2 real-world stack.

**7. What hurts in interview:** “Where are tests?” → 0% ; “Why two DI containers?” ; “Explain RLS” → client check only ; Live secret in repo explanation.

**8. Is architecture appropriate?** Yes for 177 files; keep Clean Arch but **shrink DI to one container** and split `MosqueRemoteDataSource` by aggregate to justify overhead.

**9. Is production-ready?** No — security + error propagation + no tests block store release. With Phase 1 (4-6 days) fixes, releasable to internal TestFlight.

**10. What fix first if my codebase?** Rotate secrets + `git rm secrets.json` (30 min), fix `mosque_requests_provider` bug + `dayRecordingsProvider` usecase bypass (2h), extract `UploadRecordingNotifier` (half day) — unblocks security and testability.

---

## 23. Recommended Roadmap

### Phase 1 — Critical Fixes (2-3 days)
- Rotate R2 keys, delete `secrets.json`, switch CI to ` --dart-define` env (no file) `lib/core/config/app_config.dart:4`.
- Fix `MosqueRequestsNotifier` error overwrite `lib/features/mosques/presentation/providers/mosque_requests_provider.dart`.
- Fix FutureProviders to call usecases (`mosque_data_providers.dart:28, daily_video_providers.dart, day_schedule_provider.dart`).
- Enforce Supabase RLS for `mosque_publishers` admin + `mosque_requests` policies; remove client sole reliance `mosque_remote_data_source.dart:354`.
- Inject `Dio` into `R2StorageService` constructor.
- Add `flutter analyze` to CI with `analysis_options.yaml` strict rules.

### Phase 2 — Architecture & Code Quality (1 week)
- Unify DI: single `providers.dart` source, remove `InternetConnectionChecker` dead dep, deduplicate `getMosquesUseCaseProvider`.
- Split `MosqueRemoteDataSourceImpl:611` into `MosqueDataSource`, `RecordingDataSource`, `ScheduleDataSource`, `MosqueRequestDataSource`.
- Move business logic: `RamadanDayFactory`, `PrayerGroupingService`, `AddMonth` domain service; remove `upload_recording_params.onProgress` from domain.
- Migrate `StateNotifier` → `Notifier`/`AsyncNotifier.autoDispose`, delete `bloc/mosque_state_event.dart` dead code, use `AppColors` everywhere.

### Phase 3 — Performance (3 days)
- Pagination `getMosques` `range`/infinite scroll; `getAvailableMonths` `distinct` server-side.
- `ListView.builder` `ValueKey`, `const` sweep, `select` on search filter, memoize prayer grouping via `provider.select`/`compute` isolate for large days.
- Verify `on_audio_query` usage or remove; cleanup unused `google_fonts` if replaced by asset Rubik.

### Phase 4 — Testing (1-2 weeks)
- Add `mocktail`, `fake_async`. Unit: usecases, `RamadanDayFactory`, `RetryExecutorMixin`, `RecordingModel.fromJson`. Contract: `MosqueRepositoryImpl` mock datasource. Widget: `MosquesPage` (loading/error/list + search), `UploadRecordingPage` validation. Integration: upload→R2 mock→DB insert.
- Coverage goal 40% → then 70%.

### Phase 5 — Polish & Production Readiness (1 week)
- `flutter_localizations` + `arb` replace 310 hardcoded Arabic strings; add `Semantics` + 48dp tap.
- Dark theme variant `AppTheme.darkTheme`; responsive `GridView` on tablet.
- Add `Sentry`/`Crashlytics` + `Firebase Analytics`; `ErrorWidget.builder`; enforce `minify+shrink` ProGuard keep rules.
- Supply `test/` CI badge, `docs/ARCHITECTURE.md` accurate diagram, remove `docs/tec_documentation.md` typo.

---
*Audit generated from read-only inspection of 177 `lib/` files, `pubspec.yaml`, `lib/main.dart:93`, `lib/core/di/injection_container.dart:105`, `lib/core/services/r2_storage_service.dart:220`, `lib/features/mosques/data/datasources/mosque_remote_data_source.dart:611`, providers, and plan docs on 2026-09-04.*
