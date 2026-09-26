# UI Guidelines

## Stack
- Material 3, `AppTheme.lightTheme` only (`app_theme.dart:106`): seed primary `0xFF2E7D32`, accent `0xFFEF6C00`, scaffold `0xFFF9FAFB`, Rubik font, custom AppBar/Button/Input/Slider themes.
- RTL forced at root (`main.dart:85-88`) + per-field `TextDirection.rtl`. No localization infra — keep Arabic-first layouts mirrored-safe.

## Navigation (Navigator 1.0, no go_router)
- `main.dart:78-81` `navigatorKey` + `onGenerateRoute` + `initialRoute: splash`.
- `app_router.dart:243` central switch with auth guard (`Supabase auth.currentUser`, `authRequiredRoutes`) and typed args validation (`route_args.dart`: `DayDetailArgs`, `UploadRecordingArgs.validate()`, etc.); `route_transitions.dart` fade/slide; `navigation_service.dart:132` context-free `pushNamed/pushReplacementNamed/removeUntil`.
- `showDialog ~10x`, `showModalBottomSheet 3x` (schedule table, daily video, mosque detail). `MaterialPageRoute` only for daily-video + error fallback.

## Shared UI — reuse, don't rebuild
- States: `core/presentation/widgets/app_loading_indicator|app_empty_state|app_error_view.dart`.
- Audio: `features/shared/widgets/base_audio_sheet + audio_player_widget + base_audio_sheet_components/`.
- Startup gate: `core/widgets/startup_check_wrapper.dart (ConsumerStatefulWidget)` around app builder.

## Rules
- New screens: register route + args in `app_routes.dart`/`route_args.dart`/`app_router.dart` with validation + error route; use slide/fade transitions.
- Decompose into `*_components/`; keep pages <300 lines (current max page ~218).
- Lists: `ListView.builder`/`GridView.builder` (26 hits, no slivers needed at current scale).
- No `cached_network_image` in deps; only local assets (`icon`, `splash`, `animations/`) — do not add network-image caching without a measured need.
- Guards: auth-required routes redirect to login; argument errors go to `ErrorPage`, never crash.
