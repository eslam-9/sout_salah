# Feature: Auth

## Purpose
Supabase email/password + anonymous auth, session restore, profile view/edit, sign-out with FCM cleanup, guest-mode flag.

## Entry Points
- `lib/features/auth/presentation/pages/login_page.dart:10` (`LoginPage`)
- `lib/features/auth/presentation/pages/profile_page.dart:13` (`ProfilePage`)
- `lib/features/auth/presentation/providers/auth_controller.dart:36` (`authProvider: NotifierProvider<AuthNotifier, AuthState>`)
- `lib/features/auth/presentation/providers/auth_data_providers.dart:7,14` (DI: datasource + repository providers)

## User Flows
1. Cold start → `checkAuthStatus()` → Loading → `GetCurrentUserUseCase` → Authenticated (+`registerToken`) or Unauthenticated (`auth_controller.dart:47-54`).
2. signIn → Loading → success clears `is_guest_mode` + registers token; fail → `AuthError` (`:60-73`).
3. signUp / signInAnonymously — same pattern; anon sets `is_guest_mode=true` (`:75-105`).
4. signOut → `removeToken` fire-and-forget (`:111`) → `SignOutUseCase` → Unauthenticated; fail → `AuthError` (`:107-122`).
5. `updateUsername` → success replaces user; fail → `AuthError` clobbering session (`:138-155`).
6. `LoginPage:19-40` listens: Authenticated → snackbar + home; AuthError → snackbar; `previous is AuthLoading` → sets `initialCheckDoneProvider`.

## Screens
- `login_page.dart`: Initial/Unauthenticated → `AuthHeader+LoginForm`; Loading → bare spinner; Error → full-screen error + retry (destroys form input); Authenticated → spinner + forced nav.
- `profile_page.dart:36-154`: avatar + ProfileItem rows (email/username/role/mosqueId) + edit dialog + admin button (`role admin → MosqueRequestsPage:124`).
- `sign_up_page.dart`, `login_form.dart`, `edit_profile_dialog.dart` (present, not deep-read).

## Architecture
- Clean claim holds for structure: `data/{auth_remote_data_source, user_model, profile_model, auth_repository_impl}` → `domain/{user, profile, auth_repository, auth_usecases, sign_up_usecase, sign_in_anonymously_usecase, sign_up_params}` → `presentation/{pages, providers, bloc/auth_state, widgets}`.
- Violation: `auth_data_providers.dart:3` imports datasource directly in presentation (DI-in-UI). Domain itself is import-clean.

## Presentation
- `LoginPage`/`ProfilePage`: `ConsumerWidget`. Shared `AppLoadingIndicator`/`AppErrorView`/`AppEmptyState`. Hard-coded Arabic strings, no localization abstraction.

## State Management
- `Notifier<AuthState>`; states `Initial/Loading/Authenticated(user)/Unauthenticated/Error(message)` (`bloc/auth_state.dart:11-32`). No `isGuest` field — guest derived from SharedPreferences (split source of truth).
- **Duplicate `initialCheckDoneProvider`**: `auth_controller.dart:34` vs `login_page.dart:120` — two instances, stale-check bug. `ref.listen` captures stale `hasDoneInitialCheck` (`login_page.dart:16,21`).

## Domain
- Entities `user.dart`, `profile.dart`; contract `auth_repository.dart`; use cases in `auth_usecases.dart` + `sign_in_anonymously_usecase.dart` + `sign_up_usecase.dart`.
- **Use-case audit: 7 of 8 are Thin Wrappers** (1-line passthroughs); **`SignUpUseCase` defined TWICE** with incompatible returns (`Either<Failure,User>` in `auth_usecases.dart:57` vs `Either<Failure,void>` in `sign_up_usecase.dart:7`) — Critical.

## Entities
`User`, `Profile` (id, email, role, publisher_name, mosque_id).

## Use Cases
`UpdateProfile, SignIn, SignUp (×2), SignOut, GetCurrentUser, SignInAnonymously` — all Thin Wrappers except none meaningful. Missing: none demanded (thinness is the finding, not absence).

## Repositories
`AuthRepository` contract; `AuthRepositoryImpl` wraps datasource in try/catch → `Left(ServerFailure)` — but collapses all types, dead `_mapFailureToMessage` branches for `Cache/Network/AuthFailure` never returned.

## Data Sources
`AuthRemoteDataSourceImpl(supabaseClient, logger)`: signIn/signUp/anon/signOut + `profiles.select().eq(id).maybeSingle()` (`:141-145`). **Swallows all errors to bare `ServerException()`** (`:42-44,70-73,87-95,103,116,133-136`) — original Supabase message lost. `_getUserWithProfile` silently returns user-without-profile on fetch error (masks RLS denial).

## Models
`UserModel.fromSupabase(user, profileData)`.

## External Dependencies
`supabase_flutter`, `flutter_riverpod`, `dartz`, `shared_preferences`, static `NotificationService`/`NavigationService`, `AppLogger`.

## Business Rules
- Guest = anonymous Supabase user + `is_guest_mode=true`. Sign-in/up clears flag; anon sets; sign-out clears. Role translation in `profile_page.dart:16-30`.

## UI Rules
- White login scaffold, red error icon + retry; profile `0xFFF9FAFB`, green avatar, primary edit button, orange admin button.

## Error States
- Handled: `AuthError` full screen + retry; snackbar post-initial-check; repo maps to `Left`.
- Missing/broken: swallowed Supabase messages (generic errors forever); `updateUsername`/`signOut` failures destroy session; `ProfilePage` ignores Error/Unauthenticated; token failures silent.

## Loading States
- Bare `CircularProgressIndicator`; error screen replaces form (input lost); `checkAuthStatus` always emits Loading.

## Empty States
- Profile nulls → `'غير محدد'`; `mosqueId` shows raw ID or hides row.

## Edge Cases
| Case | Status | Evidence |
|---|---|---|
| Offline | Not Covered | No connectivity check; generic `ServerException` |
| Auth-fail message | Not Covered | Message swallowed at datasource |
| Empty profile update `{}` | Not Covered | `updateProfile` sends `{}` when username null (`:124-127`) |
| Permission/RLS denial | Not Covered | Silent fallback (`:149-151`) |
| Rapid-tap sign-in | Not Covered | No in-flight guard, last-wins race |
| Token failure | Partially | Logged, flow proceeds |

## Tests
- Present: `auth_notifier_test.dart` (4 unit: signIn/signOut paths), `auth_repository_test.dart` (4 unit). No widget tests for Login/Profile. Coverage (measured 2026-09-24): `features/auth/data 9.4%`, `domain 27.0%`, `presentation 32.7%`.

## Missing Tests
`AuthRemoteDataSource` (PII log, swallowing, fallback, `{}` update), login navigation/snackbar/stale-check, profile role/mosqueId/admin gate, destructive `updateUsername`/`signOut` transitions, guest-flag persistence, signUp/anon/checkAuthStatus, offline/timeout.

## Performance
- Extra `profiles` SELECT per auth op, no cache (`:141`); `registerToken` network on every login. Minor at current scale.

## Security
- **PII in logs**: emails (`:30,:54`), user IDs, FCM token plaintext (`notification_service.dart:112,134`). **Client-supplied `role:user` on signUp** (`:56`) — privilege escalation if server trusts it. Raw `e.toString()` may leak internals to snackbar.

## Technical Debt
Duplicate provider; static fire-and-forget NotificationService; unawaited `setBool`; failure-type collapse; dead mapper branches; silent profile fallback; duplicate `SignUpUseCase`.

## Refactor Requirements
1. Preserve `AuthException.message/statusCode` → `AuthFailure`; `null` user → Unauthenticated, not failure. (CRITICAL)
2. Delete duplicate `SignUpUseCase`; keep one contract. (CRITICAL)
3. Dedupe `initialCheckDoneProvider`; inline error instead of full-screen replacement; non-destructive `updateUsername`/`signOut` failures. (HIGH)
4. Remove PII/token logging; server-enforce role; await prefs/token ops; inject NotificationService. (HIGH)
5. Tests for datasource + destructive transitions + guest flag. (HIGH)

## Engineering Assessment
Architecture PARTIAL (structure clean, DI-in-UI + duplicate UC), Code Quality WEAK (error swallowing, destructive transitions), Testing PARTIAL (31% presentation, 0 widget), Security WEAK (PII logs, client role).

## Last Reviewed
2026-09-24 (full engineering audit; `flutter test --coverage` measured).
