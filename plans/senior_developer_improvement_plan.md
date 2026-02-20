# Sout Salah - Senior Developer Improvement Plan

## Overview

This plan outlines specific, actionable steps to transform the Sout Salah project from its current mid-level quality to senior-level professional standards. Each task includes specific files to modify, create, or refactor.

---

## Phase 1: Critical Fixes (Priority: Immediate)

### Task 1.1: Fix Compilation Errors

**Files to Modify:**
- [`lib/core/routes/route_args.dart`](lib/core/routes/route_args.dart)
- [`lib/features/mosques/data/models/recording_model.dart`](lib/features/mosques/data/models/recording_model.dart)

**Actions:**
1. Add missing import for Prayer class in route_args.dart
2. Fix RecordingModel constructor to include customPrayerName parameter

**Code Changes:**
```dart
// route_args.dart - Add import
import '../../features/mosques/domain/entities/prayer.dart';

// recording_model.dart - Fix constructor
const RecordingModel({
  required super.id,
  required super.mosqueId,
  required super.dayId,
  super.publisherId,
  required super.prayer,
  super.customPrayerName,  // Add this
  required super.sheikhName,
  required super.audioUrl,
  super.fileSize,
  super.duration,
  required super.createdAt,
});
```

---

### Task 1.2: Fix Deprecated API Usage

**Files to Modify:**
- [`lib/features/mosques/presentation/pages/day_detail_page.dart`](lib/features/mosques/presentation/pages/day_detail_page.dart)
- [`lib/features/mosques/presentation/pages/upload_recording_page.dart`](lib/features/mosques/presentation/pages/upload_recording_page.dart)
- [`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart)

**Actions:**
1. Replace `withOpacity()` with `withValues(alpha: x)`
2. Replace `value` with `initialValue` in FormField

---

### Task 1.3: Fix Style Warnings

**Files to Modify:**
- [`lib/features/mosques/presentation/pages/day_detail_page.dart`](lib/features/mosques/presentation/pages/day_detail_page.dart)

**Actions:**
1. Add curly braces to all if statements
2. Enclose single-line if bodies in blocks

---

## Phase 2: Testing Infrastructure (Priority: High)

### Task 2.1: Setup Test Infrastructure

**Files to Create:**
```
test/
├── test_utils/
│   ├── mock_supabase_client.dart
│   ├── mock_storage_service.dart
│   └── test_helpers.dart
├── core/
│   └── services/
│       ├── downloads_service_test.dart
│       └── favorites_service_test.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── repositories/
    │   │       └── auth_repository_impl_test.dart
    │   └── domain/
    │       └── usecases/
    │           └── auth_usecases_test.dart
    └── mosques/
        ├── data/
        │   └── repositories/
        │       └── mosque_repository_impl_test.dart
        └── domain/
            └── usecases/
                ├── get_mosques_usecase_test.dart
                └── upload_recording_usecase_test.dart
```

**Dependencies to Add (pubspec.yaml):**
```yaml
dev_dependencies:
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
  flutter_test:
    sdk: flutter
```

### Task 2.2: Write Unit Tests for Core Services

**Priority Files:**
1. [`test/core/services/downloads_service_test.dart`](test/core/services/downloads_service_test.dart)
2. [`test/core/services/favorites_service_test.dart`](test/core/services/favorites_service_test.dart)

**Test Coverage Goals:**
- DownloadsService: 90% coverage
- FavoritesService: 90% coverage
- All use cases: 100% coverage

### Task 2.3: Write Widget Tests

**Files to Create:**
```
test/features/
├── auth/
│   └── presentation/
│       └── pages/
│           ├── login_page_test.dart
│           └── sign_up_page_test.dart
└── mosques/
    └── presentation/
        └── pages/
            ├── mosque_detail_page_test.dart
            └── day_detail_page_test.dart
```

---

## Phase 3: Architecture Refactoring (Priority: High)

### Task 3.1: Unify State Management

**Decision: Use Riverpod for All DI**

**Files to Modify:**
- [`lib/core/di/injection_container.dart`](lib/core/di/injection_container.dart) - Deprecate GetIt
- [`lib/core/di/providers.dart`](lib/core/di/providers.dart) - Expand to all services

**Actions:**
1. Create Riverpod providers for all services currently in GetIt
2. Migrate all GetIt.I<T>() calls to ref.read(provider)
3. Remove GetIt dependency after migration

**New Provider Structure:**
```dart
// core/di/providers.dart

// External
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));
});

// Services
final downloadsServiceProvider = Provider<DownloadsService>((ref) {
  return DownloadsService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(dioProvider),
    ref.watch(loggerProvider),
  );
});

// Repositories
final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepositoryImpl(
    remoteDataSource: ref.watch(mosqueRemoteDataSourceProvider),
  );
});

// Use Cases
final getMosquesUseCaseProvider = Provider<GetMosquesUseCase>((ref) {
  return GetMosquesUseCase(ref.watch(mosqueRepositoryProvider));
});
```

### Task 3.2: Break Down Large Widget Files

**Files to Refactor:**
- [`lib/features/mosques/presentation/pages/day_detail_page.dart`](lib/features/mosques/presentation/pages/day_detail_page.dart) (38,814 chars)

**New Structure:**
```
features/mosques/presentation/
├── pages/
│   └── day_detail_page.dart (simplified, ~150 lines)
├── widgets/
│   ├── prayer_card.dart
│   ├── prayer_section.dart
│   ├── recording_list_tile.dart
│   ├── add_prayer_dialog.dart
│   └── upload_button.dart
```

**Refactoring Steps:**
1. Extract `_buildPrayerCard` to `widgets/prayer_card.dart`
2. Extract `_AddPrayerDialog` to `widgets/add_prayer_dialog.dart`
3. Extract recording list tile to `widgets/recording_list_tile.dart`
4. Create `widgets/prayer_section.dart` for grouped prayers

### Task 3.3: Fix Circular Dependency

**Files to Modify:**
- [`lib/features/mosques/domain/entities/prayer.dart`](lib/features/mosques/domain/entities/prayer.dart)
- [`lib/features/mosques/domain/entities/recording.dart`](lib/features/mosques/domain/entities/recording.dart)

**Actions:**
1. Remove Recording import from prayer.dart
2. Move PrayerWithRecordings to a separate file or remove if unused

---

## Phase 4: Internationalization (Priority: Medium)

### Task 4.1: Setup l10n

**Files to Create:**
```
lib/
├── l10n/
│   └── app_localizations.dart
l10n.yaml
lib/l10n/
├── app_en.arb
└── app_ar.arb
```

**l10n.yaml:**
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

**pubspec.yaml additions:**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

### Task 4.2: Extract Hardcoded Strings

**Priority Files:**
- All files in `features/*/presentation/pages/`

**Example Migration:**
```dart
// Before
Text('إنشاء حساب جديد')

// After
Text(AppLocalizations.of(context)!.createAccount)
```

**app_ar.arb:**
```json
{
  "@@locale": "ar",
  "createAccount": "إنشاء حساب جديد",
  "login": "تسجيل الدخول",
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور"
}
```

---

## Phase 5: Professional Features (Priority: Medium)

### Task 5.1: Add Dark Theme

**Files to Modify:**
- [`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart)

**New Structure:**
```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(...);
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      // Dark theme configuration
    );
  }
}
```

**Files to Create:**
```
lib/core/theme/
├── app_colors.dart
├── app_text_styles.dart
└── theme_provider.dart
```

### Task 5.2: Add Theme Provider

**Files to Create:**
- [`lib/core/theme/theme_provider.dart`](lib/core/theme/theme_provider.dart)

```dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);
  
  void setTheme(ThemeMode mode) {
    state = mode;
    // Persist to SharedPreferences
  }
}
```

### Task 5.3: Add Error Tracking (Sentry)

**Files to Modify:**
- [`lib/main.dart`](lib/main.dart)

**pubspec.yaml additions:**
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

**main.dart changes:**
```dart
Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_DSN';
    },
    appRunner: () => runApp(const ProviderScope(child: MyApp())),
  );
}
```

### Task 5.4: Add Analytics

**pubspec.yaml additions:**
```yaml
dependencies:
  firebase_analytics: ^10.0.0
  firebase_core: ^2.0.0
```

**Files to Create:**
- [`lib/core/services/analytics_service.dart`](lib/core/services/analytics_service.dart)

---

## Phase 6: Code Quality Improvements (Priority: Low)

### Task 6.1: Add Code Documentation

**Actions:**
1. Add dartdoc comments to all public APIs
2. Document architecture decisions
3. Create ADR (Architecture Decision Records)

**Files to Create:**
```
docs/
├── architecture/
│   ├── ADR-001-state-management.md
│   ├── ADR-002-backend-choice.md
│   └── ADR-003-audio-player.md
└── API.md
```

### Task 6.2: Improve Error Handling

**Files to Create:**
- [`lib/core/errors/error_handler.dart`](lib/core/errors/error_handler.dart)

```dart
class ErrorHandler {
  static String mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ServerFailure() => 'Server error occurred',
      CacheFailure() => 'Cache error occurred',
      NetworkFailure() => 'Network error occurred',
      _ => 'Unexpected error occurred',
    };
  }
}
```

### Task 6.3: Add Constants File

**Files to Create:**
- [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart)

```dart
class AppConstants {
  static const String appName = 'Sout Salah';
  static const int maxFileSizeMB = 100;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 5);
}
```

---

## Implementation Timeline

| Phase | Tasks | Priority |
|-------|-------|----------|
| Phase 1 | Critical Fixes | Immediate |
| Phase 2 | Testing Infrastructure | High |
| Phase 3 | Architecture Refactoring | High |
| Phase 4 | Internationalization | Medium |
| Phase 5 | Professional Features | Medium |
| Phase 6 | Code Quality | Low |

---

## Success Metrics

After completing this plan, the project should achieve:

1. **Zero compilation errors**
2. **80%+ test coverage**
3. **No file over 300 lines**
4. **Full internationalization support**
5. **Dark theme support**
6. **Error tracking and analytics**
7. **Consistent state management**
8. **Professional documentation**

---

## Quick Start Checklist

For immediate improvements, start with:

- [ ] Fix Prayer import in route_args.dart
- [ ] Fix RecordingModel constructor
- [ ] Replace deprecated withOpacity calls
- [ ] Add curly braces to if statements
- [ ] Create first unit test file
- [ ] Setup l10n configuration
- [ ] Create theme provider

---

*Plan created: 2026-02-14*
