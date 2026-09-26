# Architecture

## Layer Structure

```
lib/
├── core/                    # Shared infrastructure
│   ├── config/             # AppConfig (env vars via --dart-define-from-file)
│   ├── constants/          # App-wide constants
│   ├── di/                 # DI: injection_container.dart (GetIt bootstrap)
│   │                       #     riverpod_providers.dart (Riverpod — use this)
│   ├── error/              # Failure/Exception hierarchy + repository_error_handler
│   ├── models/             # Shared data models (DownloadedRecording, FavoriteRecording)
│   ├── network/            # NetworkInfo, RetryExecutorMixin, NetworkPolicy
│   ├── presentation/       # Shared widgets (AppLoadingIndicator, AppErrorView, etc.)
│   ├── routes/             # AppRouter, AppRoutes, RouteArgs, RouteTransitions
│   ├── services/           # AudioPlayerService, DownloadsService, FavoritesService,
│   │                       #   NavigationService, NotificationService
│   ├── theme/              # AppTheme, AppColors, AppTextStyles
│   ├── usecases/           # UseCase<Type, Params> base interface
│   └── utils/              # AppLogger, FailureMapper, PermissionChecker
│
└── features/
    ├── auth/
    │   ├── data/           # Supabase datasource, AuthModel, AuthRepositoryImpl
    │   ├── domain/         # User entity, AuthRepository contract, UseCases,
    │   │                   #   UserPermissionService
    │   └── presentation/   # AuthNotifier (Riverpod), AuthState, pages, widgets
    │
    └── mosques/
        ├── data/           # Remote datasources (Supabase), models, repository impls
        ├── domain/         # Entities, repository contracts, use cases
        └── presentation/   # Providers (Riverpod notifiers), pages, widgets
```

## DI Strategy

- **GetIt** (`core/di/injection_container.dart`): Bootstrap bridge ONLY. Used by `main.dart`'s global error handler before `ProviderScope` is mounted. Do NOT use in feature code.
- **Riverpod** (`core/di/riverpod_providers.dart` + feature-level providers): All feature code uses `ref.watch` / `ref.read`. This is the single source of truth.

## Navigation

- `AppRouter.onGenerateRoute` — imperative Navigator 1.0 with auth guard and argument validation.
- `NavigationService.navigatorKey` — allows navigation from non-widget code (e.g., NotificationService).

## Error Handling

- Data layer throws `AppException` subclasses (e.g., `ServerException`, `UserNotFoundException`).
- `repository_error_handler.dart` `executeWithCatch()` maps exceptions → `Failure` subclasses.
- Use cases propagate `Either<Failure, T>` to the presentation layer.
- Notifiers unwrap `Either` and set state accordingly.

## State Management

- Riverpod `AsyncNotifier` / `Notifier` for all stateful features.
- `AsyncValue` — always use `copyWithPrevious` when transitioning to loading to avoid wiping existing data.
