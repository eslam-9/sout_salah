# 🍳 Sout Salah — Implementation Cookbook (Phases 1–9)

> **Phase 0 (Security) is ALREADY DONE.**
> This cookbook covers Phases 1–9 in exact, step-by-step detail.
> Each phase ends with a `Verification` command. Run it. If it fails, fix it before moving on.

## Ground Rules for the Implementing Agent

1. **Run `flutter analyze` after every phase.** Zero new warnings/errors must be introduced.
2. **Run `flutter test` after every phase.** All 31 existing tests must still pass.
3. **Never change business logic** unless explicitly told to in a step.
4. **Exact file paths are given.** Do not create files in other locations.
5. **When you see `// EXISTING CODE — DO NOT CHANGE`, leave it exactly as is.**
6. After editing any Dart file, attempt to connect via `dtd` and hot-reload. If no app is running, skip hot-reload and continue.

---

## PHASE 1 — Consolidate DI (Dual GetIt + Riverpod → Single Riverpod)

**Why:** `GetIt` and `Riverpod` both register the same objects. `AppRouter` calls `GetIt.I<X>()` directly — bypassing Riverpod. This makes testing impossible and causes subtle order-of-initialization bugs.

**What changes:** Move `AppLogger` and `NavigationService` registration out of `GetIt` into pure Riverpod. Keep `GetIt` only as a bootstrap bridge for the early-init window before `ProviderScope` exists.

---

### Step 1.1 — Add `keepAlive` and fix `AudioPlayerService` provider

**File:** `lib/core/di/riverpod_providers.dart`

Find this exact line:
```dart
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) => AudioPlayerService());
```

Replace it with:
```dart
// AudioPlayerService holds mutable AudioPlayer state — keep alive for the app lifetime
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});
```

Find this exact line:
```dart
final downloadsServiceProvider = Provider<DownloadsService>((ref) {
```

Replace the entire provider block (it ends at the `});` after `appLoggerProvider`) with:
```dart
// DownloadsService holds StreamControllers — keep alive and dispose properly
final downloadsServiceProvider = Provider<DownloadsService>((ref) {
  final service = DownloadsService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(dioProvider),
    ref.watch(appLoggerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
```

Find this exact line:
```dart
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
```

Replace the entire provider block with:
```dart
// FavoritesService holds StreamControllers — keep alive and dispose properly
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final service = FavoritesService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(appLoggerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
```

---

### Step 1.2 — Remove `AppRouter`'s direct `GetIt` calls

**File:** `lib/core/routes/app_router.dart`

At the top of the file, find:
```dart
import 'package:get_it/get_it.dart';
import '../utils/app_logger.dart';
```

Replace with:
```dart
import '../utils/app_logger.dart';
```

Find this method:
```dart
static bool _isAuthenticated() {
  try {
    final user = GetIt.I<SupabaseClient>().auth.currentUser;
    return user != null;
  } catch (_) {
    // Return false if Supabase throws (e.g., offline)
    return false;
  }
}
```

Replace with:
```dart
static bool _isAuthenticated() {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  } catch (_) {
    return false;
  }
}
```

Find every instance of:
```dart
GetIt.I<AppLogger>().i(
```
Replace each with a `// ignore: avoid_print` + `debugPrint` call temporarily:
```dart
debugPrint(
```

> **Note:** These log calls in the router are low-value (route logging). Using `debugPrint` is fine here because `AppLogger` cannot be injected into a static class without major refactor. Leave them as `debugPrint` for now.

Specifically, here are all the occurrences to replace in `app_router.dart`:

1. Line ~44: `GetIt.I<AppLogger>().i('🧭 AppRouter: Navigating to ${settings.name}');` → `debugPrint('AppRouter: Navigating to ${settings.name}');`
2. Line ~52: `GetIt.I<AppLogger>().w('⚠️ AppRouter: Route requires auth...');` → `debugPrint('AppRouter: Route requires auth, redirecting to login');`
3. Line ~67: `GetIt.I<AppLogger>().i('Redirecting home to login...');` → `debugPrint('AppRouter: Redirecting home to login (not authenticated)');`
4. Line ~87,100,114,132,...: All `GetIt.I<AppLogger>().e('❌ AppRouter: Invalid arguments...`)` → `debugPrint('AppRouter: Invalid arguments for ...');`
5. Line ~226: `GetIt.I<AppLogger>().e('❌ AppRouter: Unknown route...')` → `debugPrint('AppRouter: Unknown route ${settings.name}');`
6. Line ~240: same pattern

Also add `import 'package:flutter/foundation.dart';` to the imports if `debugPrint` is not already available.

After your replacements, verify `get_it` import is removed and `supabase_flutter` is still imported.

---

### Step 1.3 — Clean up `injection_container.dart`

**File:** `lib/core/di/injection_container.dart`

The entire file currently registers `AppLogger` and `NavigationService` into GetIt. These are also available via Riverpod. We keep GetIt registration ONLY because `main.dart` calls `di.setupServiceLocator()` before `ProviderScope` is created, so `FlutterError.onError` needs `GetIt.I<AppLogger>()` to work.

**No changes needed** to this file — keep it exactly as is. The dual registration is intentional for the bootstrap window. Add this comment at the top of the file:

```dart
// NOTE: GetIt is used ONLY as a bootstrap bridge.
// AppLogger and NavigationService are registered here so that main.dart's
// global error handlers can access them before ProviderScope is initialized.
// All feature code must use Riverpod providers, not GetIt.
```

---

### Step 1.4 — Add `NavigationService` to Riverpod providers

**File:** `lib/core/di/riverpod_providers.dart`

Add at the bottom of the file:
```dart
// Navigation service available via Riverpod for feature code
// (main.dart bootstrap uses GetIt directly)
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});
```

Add the import at the top:
```dart
import '../services/navigation_service.dart';
```

---

### Phase 1 Verification

```bash
flutter analyze
flutter test
```

Expected: 0 new errors. All 31 tests pass.

---

## PHASE 2 — Error Handling Hardening

**Why:** Data sources throw `ServerException()` without preserving HTTP/Supabase error codes. `addPublisher` mixes Arabic user-facing text into the data layer. `AudioPlayerService` throws generic `Exception`.

---

### Step 2.1 — Add error code to `ServerException`

**File:** `lib/core/error/exceptions.dart`

Replace the entire file content with:

```dart
class ServerException implements Exception {
  final String? message;
  final int? statusCode;
  ServerException([this.message, this.statusCode]);
}

class CacheException implements Exception {}

class NetworkException implements Exception {
  final String? message;
  NetworkException([this.message]);
}

class AppAuthException implements Exception {
  final String? message;
  AppAuthException([this.message]);
}

class NotFoundException implements Exception {
  final String? message;
  NotFoundException([this.message]);
}

class ValidationException implements Exception {
  final String? message;
  ValidationException([this.message]);
}

class StorageException implements Exception {
  final String? message;
  StorageException([this.message]);
}

// NEW: typed exception for when a user lookup fails
class UserNotFoundException implements Exception {
  final String email;
  UserNotFoundException(this.email);
}

// NEW: typed exception for audio playback failures
class AudioPlaybackException implements Exception {
  final String? message;
  final Object? cause;
  AudioPlaybackException([this.message, this.cause]);
}

class LocationPermissionDeniedException implements Exception {}
class LocationPermissionPermanentlyDeniedException implements Exception {}
class LocationServiceDisabledException implements Exception {}
class LocationUnavailableException implements Exception {}
class MapLaunchException implements Exception {}
```

---

### Step 2.2 — Handle `UserNotFoundException` in repository error handler

**File:** `lib/core/error/repository_error_handler.dart`

Find:
```dart
  } on NotFoundException catch (e) {
    return Left(NotFoundFailure(message: e.message ?? 'العنصر غير موجود'));
  }
```

Replace with:
```dart
  } on UserNotFoundException catch (e) {
    return Left(NotFoundFailure(message: 'المستخدم ${e.email} غير موجود'));
  } on NotFoundException catch (e) {
    return Left(NotFoundFailure(message: e.message ?? 'العنصر غير موجود'));
  }
```

Add the import at the top of the file:
```dart
import 'exceptions.dart';
```
(It should already be there — verify.)

---

### Step 2.3 — Fix `addPublisher` in data source

**File:** `lib/features/mosques/data/datasources/mosque_remote_data_source.dart`

Find this block (lines ~102–128):
```dart
      if (userResponse == null) {
        logger.w('User with email $email not found');
        throw Exception('User not found');
      }
```

Replace `throw Exception('User not found');` with:
```dart
        throw UserNotFoundException(email);
```

Find:
```dart
    } catch (e) {
      logger.e('Error adding publisher', e);
      if (e.toString().contains('User not found') ||
          e.toString().contains('User with email')) {
        throw Exception('المستخدم غير موجود');
      }
      if (e.toString().contains('Only Super Admin')) {
        throw Exception('فقط مدير النظام يمكنه إضافة ناشرين');
      }
      throw ServerException();
    }
```

Replace with:
```dart
    } catch (e) {
      logger.e('Error adding publisher', e);
      if (e is UserNotFoundException) {
        rethrow; // let repository_error_handler map it to NotFoundFailure
      }
      if (e.toString().contains('Only Super Admin')) {
        throw AppAuthException('فقط مدير النظام يمكنه إضافة ناشرين');
      }
      throw ServerException(e.toString());
    }
```

Add import at top of file:
```dart
import '../../../../core/error/exceptions.dart';
```
(verify it's already there)

---

### Step 2.4 — Fix `AudioPlayerService` to use typed exception

**File:** `lib/core/services/audio_player_service.dart`

Add import at the top:
```dart
import '../error/exceptions.dart';
```

Find:
```dart
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
```

Replace with:
```dart
    } catch (e) {
      throw AudioPlaybackException('Failed to play audio', e);
    }
```

---

### Step 2.5 — Preserve `statusCode` in data source

**File:** `lib/features/mosques/data/datasources/mosque_remote_data_source.dart`

In `getMosques`, find:
```dart
    } catch (e) {
      logger.e('Error fetching mosques', e);
      throw ServerException();
    }
```

Replace with:
```dart
    } catch (e) {
      logger.e('Error fetching mosques', e);
      throw ServerException(e.toString());
    }
```

In `addMosque`, find:
```dart
    } catch (e, stackTrace) {
      logger.e('Error adding mosque', e, stackTrace);
      throw ServerException();
    }
```

Replace with:
```dart
    } catch (e, stackTrace) {
      logger.e('Error adding mosque', e, stackTrace);
      throw ServerException(e.toString());
    }
```

Do the same in ALL other data source files:
- `lib/features/mosques/data/datasources/ramadan_days_remote_data_source.dart`
- `lib/features/mosques/data/datasources/recordings_remote_data_source.dart`
- `lib/features/mosques/data/datasources/mosque_requests_remote_data_source.dart`
- `lib/features/mosques/data/datasources/day_schedule_remote_data_source.dart`
- `lib/features/auth/data/datasources/` (all files inside)

In each file, find every `throw ServerException();` and replace with `throw ServerException(e.toString());`

---

### Phase 2 Verification

```bash
flutter analyze
flutter test
```

Expected: 0 new errors. All 31 tests pass.

---

## PHASE 3 — State Management Quality

**Why:** `loadMore()` wipes the entire list on every pagination trigger. `_mapFailureToMessage` is duplicated. `AuthState` is in the wrong folder. `ref.read` used inside `build()` for stateful data. No `copyWith` on entities.

---

### Step 3.1 — Fix `loadMore()` pagination flash

**File:** `lib/features/mosques/presentation/providers/mosque_controller.dart`

Find this block inside `loadMore()`:
```dart
    final currentState = state;
    if (currentState.hasValue) {
      final currentList = currentState.value!;
      state = const AsyncValue.loading();

      try {
        _currentPage++;
        final newMosques = await _fetchMosques(
          page: _currentPage,
          pageSize: _pageSize,
        );
        state = AsyncValue.data([...currentList, ...newMosques]);
      } catch (e, st) {
        _currentPage--;
        state = AsyncValue<List<Mosque>>.error(
          e,
          st,
        ).copyWithPrevious(currentState);
      }
    }
```

Replace with:
```dart
    final currentState = state;
    if (currentState.hasValue) {
      final currentList = currentState.value!;
      // Use copyWithPrevious so the existing list stays visible while loading
      state = const AsyncValue<List<Mosque>>.loading().copyWithPrevious(currentState);

      try {
        _currentPage++;
        final newMosques = await _fetchMosques(
          page: _currentPage,
          pageSize: _pageSize,
        );
        state = AsyncValue.data([...currentList, ...newMosques]);
      } catch (e, st) {
        _currentPage--;
        state = AsyncValue<List<Mosque>>.error(e, st).copyWithPrevious(currentState);
      }
    }
```

---

### Step 3.2 — Fix `ref.read` for `hasMore` inside `build()`

**File:** `lib/features/home/presentation/pages/mosques_page.dart`

Find:
```dart
                          itemCount:
                              mosques.length +
                              (ref.read(mosqueProvider.notifier).hasMore
                                  ? 1
                                  : 0),
```

Replace with:
```dart
                          itemCount:
                              mosques.length +
                              (ref.watch(mosqueProvider.notifier).hasMore
                                  ? 1
                                  : 0),
```

---

### Step 3.3 — Fix case-insensitive search

**File:** `lib/features/home/presentation/pages/mosques_page.dart`

Find:
```dart
                        final mosques = mosquesList
                            .where((m) => m.name.contains(_searchQuery))
                            .toList();
```

Replace with:
```dart
                        final query = _searchQuery.toLowerCase();
                        final mosques = mosquesList
                            .where(
                              (m) => m.name.toLowerCase().contains(query),
                            )
                            .toList();
```

---

### Step 3.4 — Extract `FailureMapper` utility

**Create new file:** `lib/core/utils/failure_mapper.dart`

```dart
import '../error/failures.dart';

/// Maps a [Failure] to a user-facing Arabic error message.
/// Use this single source of truth instead of duplicating _mapFailureToMessage.
String mapFailureToMessage(Failure failure) {
  if (failure is NetworkFailure) return failure.message;
  if (failure is ServerFailure) return failure.message;
  if (failure is AuthFailure) return failure.message;
  if (failure is NotFoundFailure) return failure.message;
  if (failure is ValidationFailure) return failure.message;
  if (failure is StorageFailure) return failure.message;
  if (failure is CacheFailure) return 'خطأ في التخزين المؤقت';
  return failure.message;
}
```

**Now update `auth_controller.dart`** to use it:

**File:** `lib/features/auth/presentation/providers/auth_controller.dart`

Add import at the top:
```dart
import '../../../../core/utils/failure_mapper.dart';
```

Delete the entire private method:
```dart
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return 'Cache Failure';
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is AuthFailure) {
      return failure.message;
    } else {
      return 'Unexpected Error';
    }
  }
```

Replace every call to `_mapFailureToMessage(failure)` with `mapFailureToMessage(failure)` (4 occurrences in the same file).

---

### Step 3.5 — Rename `bloc` folder to `state`

> This is a folder rename. It affects import paths in multiple files.

**Commands:**
```bash
mv "lib/features/auth/presentation/bloc" "lib/features/auth/presentation/state"
```

**Then find-and-replace in the entire codebase** (every `.dart` file):

Search for: `presentation/bloc/auth_state.dart`
Replace with: `presentation/state/auth_state.dart`

And: `features/auth/presentation/bloc/`
Replace with: `features/auth/presentation/state/`

Files that import this path (search the project):
- `lib/features/auth/presentation/providers/auth_controller.dart`
- `lib/features/home/presentation/pages/home_layout.dart`
- `lib/features/home/presentation/pages/settings_page.dart`
- `lib/features/mosques/presentation/pages/mosque_detail_page.dart`
- `lib/core/routes/app_router.dart`

Update the import in each of these files:
```dart
// OLD:
import '../../../auth/presentation/bloc/auth_state.dart';
// NEW:
import '../../../auth/presentation/state/auth_state.dart';
```

(The exact relative path prefix differs per file — adjust accordingly.)

---

### Step 3.6 — Add `copyWith` to domain entities

**File:** `lib/features/mosques/domain/entities/mosque.dart`

Add this method inside the `Mosque` class, after the constructor:
```dart
  Mosque copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? adminId,
    int? recordingCount,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adminId: adminId ?? this.adminId,
      recordingCount: recordingCount ?? this.recordingCount,
    );
  }
```

**File:** `lib/features/mosques/domain/entities/recording.dart`

Add inside `Recording` class after constructor:
```dart
  Recording copyWith({
    String? id,
    String? mosqueId,
    String? dayId,
    String? publisherId,
    Prayer? prayer,
    String? customPrayerName,
    String? sheikhName,
    String? audioUrl,
    int? fileSize,
    int? duration,
    DateTime? createdAt,
  }) {
    return Recording(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      dayId: dayId ?? this.dayId,
      publisherId: publisherId ?? this.publisherId,
      prayer: prayer ?? this.prayer,
      customPrayerName: customPrayerName ?? this.customPrayerName,
      sheikhName: sheikhName ?? this.sheikhName,
      audioUrl: audioUrl ?? this.audioUrl,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
```

**File:** `lib/features/mosques/domain/entities/ramadan_day.dart`

Add inside `RamadanDay` class after constructor:
```dart
  RamadanDay copyWith({
    String? id,
    String? mosqueId,
    int? dayNumber,
    String? status,
    bool? active,
    int? month,
    int? year,
  }) {
    return RamadanDay(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      dayNumber: dayNumber ?? this.dayNumber,
      status: status ?? this.status,
      active: active ?? this.active,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
```

---

### Phase 3 Verification

```bash
flutter analyze
flutter test
```

Expected: 0 new errors. All 31 tests pass.

---

## PHASE 4 — Authorization Cleanup

**Why:** UI pages contain raw role string comparisons (`authState.user.role == 'admin'`). Business rules belong in the domain layer.

---

### Step 4.1 — Create `UserPermissionService`

**Create new file:** `lib/features/auth/domain/services/user_permission_service.dart`

```dart
import '../entities/user.dart';
import '../../data/../../mosques/domain/entities/mosque.dart';

/// Pure domain service — no Flutter, no Supabase, no GetIt.
/// All permission logic lives here so UI never contains raw role strings.
class UserPermissionService {
  const UserPermissionService();

  static const _adminRole = 'admin';
  static const _superAdminRole = 'super_admin';
  static const _publisherRole = 'publisher';

  /// Can the user add a new Ramadan month to this mosque?
  bool canAddMonth(User user, Mosque mosque) {
    return _isAdmin(user) || _isSuperAdmin(user) || user.id == mosque.adminId;
  }

  /// Can the user upload recordings to this mosque?
  bool canUploadRecording(User user, Mosque mosque) {
    return _isPublisher(user) || _isAdmin(user) || _isSuperAdmin(user) ||
        user.mosqueId == mosque.id;
  }

  /// Can the user manage publishers for this mosque?
  bool canManagePublishers(User user, Mosque mosque) {
    return _isAdmin(user) || _isSuperAdmin(user) || user.id == mosque.adminId;
  }

  /// Can the user add a new mosque to the app?
  /// (All authenticated non-guest users can — guest check done in PermissionChecker)
  bool canAddMosque(User user) => true;

  /// Is this user a global super admin?
  bool isSuperAdmin(User user) => _isSuperAdmin(user);

  bool _isAdmin(User user) => user.role == _adminRole;
  bool _isSuperAdmin(User user) => user.role == _superAdminRole;
  bool _isPublisher(User user) => user.role == _publisherRole;
}
```

---

### Step 4.2 — Register `UserPermissionService` as a Riverpod provider

**File:** `lib/features/auth/presentation/providers/auth_data_providers.dart`

Open that file and add at the bottom:
```dart
import '../../domain/services/user_permission_service.dart';

final userPermissionServiceProvider = Provider<UserPermissionService>((ref) {
  return const UserPermissionService();
});
```

---

### Step 4.3 — Fix `MosqueDetailPage` inline role check

**File:** `lib/features/mosques/presentation/pages/mosque_detail_page.dart`

Add imports at the top:
```dart
import '../../../../features/auth/presentation/providers/auth_data_providers.dart';
import '../../../../features/auth/domain/services/user_permission_service.dart';
```

Find this block in `build()`:
```dart
      floatingActionButton: (authState is AuthAuthenticated &&
              (authState.user.role == 'admin' ||
               authState.user.role == 'super_admin' ||
               authState.user.id == widget.mosque.adminId))
          ? FloatingActionButton(
```

Replace with:
```dart
      floatingActionButton: (authState is AuthAuthenticated &&
              ref.read(userPermissionServiceProvider).canAddMonth(
                    authState.user,
                    widget.mosque,
                  ))
          ? FloatingActionButton(
```

---

### Step 4.4 — Search the codebase for any remaining inline role checks

Run this in the terminal:
```bash
grep -rn "user.role ==" lib/
```

For any occurrence found, replace the inline check with a call to `userPermissionServiceProvider`:
```dart
ref.read(userPermissionServiceProvider).canAddMonth(user, mosque)
// or canUploadRecording / canManagePublishers / isSuperAdmin
```

---

### Phase 4 Verification

```bash
grep -rn "user.role ==" lib/
# Should return 0 results

flutter analyze
flutter test
```

---

## PHASE 5 — Testing Foundation

**Why:** Only 10 test files exist. Zero coverage for the core services. 14 analyzer warnings in existing tests.

---

### Step 5.1 — Fix existing test warnings

**File:** `test/features/mosques/presentation/pages/add_mosque_page_test.dart`

The `@override` annotations on non-overriding methods are because the mock class doesn't extend the right interface.

Open the file and find mock class definitions that look like:
```dart
class MockSomething {
  @override
  Future<X> methodName(...) async { ... }
}
```

If using manual mocks, the `@override` annotation is wrong (those methods don't exist on `Object`). Remove the `@override` annotation from any method that isn't actually overriding a parent class method.

If the mock class is meant to implement an interface, add `implements InterfaceName` to the class declaration.

Do the same for `test/features/mosques/presentation/pages/mosque_info_page_test.dart`.

**Fix duplicate test names:**

In `mosque_info_page_test.dart`, each `test(...)` call has the identical name `'displays mosque name correctly'`. Give each test a unique name describing what variant it tests, for example:
- `'displays mosque name with recording count'`
- `'displays mosque name without description'`
- etc.

---

### Step 5.2 — Unit tests for `DownloadsService`

**Create new file:** `test/features/mosques/data/services/downloads_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sout_salah/core/services/downloads_service.dart';
import 'package:sout_salah/core/utils/app_logger.dart';

class MockDio extends Mock implements Dio {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late DownloadsService sut;
  late MockDio mockDio;
  late MockAppLogger mockLogger;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockDio = MockDio();
    mockLogger = MockAppLogger();

    // Stub logger methods to do nothing
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.e(any(), any(), any())).thenReturn(null);
    when(() => mockLogger.w(any())).thenReturn(null);

    sut = DownloadsService(prefs, mockDio, mockLogger);
  });

  tearDown(() => sut.dispose());

  group('getDownloads', () {
    test('returns empty list when no downloads stored', () async {
      final result = await sut.getDownloads();
      expect(result, isEmpty);
    });

    test('returns empty list when JSON is corrupt', () async {
      await prefs.setString('downloaded_recordings', 'not-valid-json');
      final result = await sut.getDownloads();
      expect(result, isEmpty);
    });
  });

  group('isDownloaded', () {
    test('returns false when recording not downloaded', () async {
      final result = await sut.isDownloaded('non-existent-id');
      expect(result, isFalse);
    });
  });

  group('cancelDownload', () {
    test('does nothing if recording is not downloading', () {
      // Should not throw
      expect(() => sut.cancelDownload('some-id'), returnsNormally);
    });
  });

  group('downloadsStream', () {
    test('emits a list when listened', () async {
      expectLater(sut.downloadsStream, emits(isA<List>()));
    });
  });

  group('removeDownload', () {
    test('throws when recording not found', () async {
      await expectLater(
        sut.removeDownload('non-existent'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

---

### Step 5.3 — Unit tests for `FavoritesService`

**Create new file:** `test/features/mosques/data/services/favorites_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sout_salah/core/services/favorites_service.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:sout_salah/features/mosques/domain/entities/recording.dart';
import 'package:sout_salah/features/mosques/domain/entities/prayer.dart';

class MockAppLogger extends Mock implements AppLogger {}

Recording _makeRecording({String id = 'rec-1'}) => Recording(
  id: id,
  mosqueId: 'mosque-1',
  dayId: 'day-1',
  prayer: Prayer.fajr,
  sheikhName: 'Test Sheikh',
  audioUrl: 'https://example.com/audio.mp3',
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  late FavoritesService sut;
  late MockAppLogger mockLogger;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockLogger = MockAppLogger();
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.e(any(), any(), any())).thenReturn(null);
    sut = FavoritesService(prefs, mockLogger);
  });

  tearDown(() => sut.dispose());

  group('getFavorites', () {
    test('returns empty list initially', () async {
      expect(await sut.getFavorites(), isEmpty);
    });
  });

  group('isFavorite', () {
    test('returns false when not favorited', () async {
      expect(await sut.isFavorite('rec-1'), isFalse);
    });
  });

  group('addFavorite', () {
    test('adds a recording to favorites', () async {
      await sut.addFavorite(_makeRecording());
      expect(await sut.isFavorite('rec-1'), isTrue);
      expect(await sut.getFavorites(), hasLength(1));
    });

    test('does not add duplicate favorites', () async {
      await sut.addFavorite(_makeRecording());
      await sut.addFavorite(_makeRecording()); // same id
      expect(await sut.getFavorites(), hasLength(1));
    });
  });

  group('removeFavorite', () {
    test('removes an existing favorite', () async {
      await sut.addFavorite(_makeRecording());
      await sut.removeFavorite('rec-1');
      expect(await sut.isFavorite('rec-1'), isFalse);
    });

    test('throws when recording not in favorites', () async {
      await expectLater(
        sut.removeFavorite('non-existent'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('favoritesStream', () {
    test('emits list when listened', () {
      expectLater(sut.favoritesStream, emits(isA<List>()));
    });
  });
}
```

> **Note:** You need to know what `Prayer.fajr` is. Check `lib/features/mosques/domain/entities/prayer.dart` and use a valid value from that file.

---

### Step 5.4 — Unit tests for `MosqueNotifier`

**Create new file:** `test/features/mosques/presentation/providers/mosque_notifier_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';
import 'package:sout_salah/features/mosques/domain/repositories/mosque_repository.dart';
import 'package:sout_salah/features/mosques/domain/usecases/get_mosques_usecase.dart';
import 'package:sout_salah/features/mosques/presentation/providers/mosque_controller.dart';
import 'package:sout_salah/features/mosques/presentation/providers/mosque_data_providers.dart';

class MockMosqueRepository extends Mock implements MosqueRepository {}

Mosque _makeMosque(String id) => Mosque(id: id, name: 'Mosque $id');

void main() {
  late MockMosqueRepository mockRepo;

  setUp(() {
    mockRepo = MockMosqueRepository();
    registerFallbackValue(const Right<Failure, List<Mosque>>([]));
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        mosqueRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('MosqueNotifier', () {
    test('initial state is loading then returns mosques', () async {
      when(() => mockRepo.getMosques(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => Right(List.generate(20, (i) => _makeMosque('$i'))));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(mosqueProvider.future);
      expect(state, hasLength(20));
    });

    test('returns NetworkFailure when offline', () async {
      when(() => mockRepo.getMosques(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(mosqueProvider);
      await Future.delayed(Duration.zero);
      expect(container.read(mosqueProvider).hasError, isTrue);
    });

    test('hasMore is false when result < pageSize', () async {
      when(() => mockRepo.getMosques(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => Right([_makeMosque('1')]));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(mosqueProvider.future);
      expect(container.read(mosqueProvider.notifier).hasMore, isFalse);
    });
  });
}
```

---

### Step 5.5 — Unit tests for `FailureMapper`

**Create new file:** `test/core/utils/failure_mapper_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/utils/failure_mapper.dart';

void main() {
  group('mapFailureToMessage', () {
    test('maps NetworkFailure', () {
      expect(
        mapFailureToMessage(const NetworkFailure()),
        equals('لا يوجد اتصال بالإنترنت'),
      );
    });

    test('maps ServerFailure with custom message', () {
      expect(
        mapFailureToMessage(const ServerFailure(message: 'custom error')),
        equals('custom error'),
      );
    });

    test('maps AuthFailure', () {
      expect(
        mapFailureToMessage(const AuthFailure()),
        equals('خطأ في المصادقة'),
      );
    });

    test('maps CacheFailure', () {
      expect(
        mapFailureToMessage(const CacheFailure()),
        equals('خطأ في التخزين المؤقت'),
      );
    });
  });
}
```

---

### Step 5.6 — Unit tests for `UserPermissionService`

**Create new file:** `test/features/auth/domain/services/user_permission_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/features/auth/domain/entities/user.dart';
import 'package:sout_salah/features/auth/domain/services/user_permission_service.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';

void main() {
  const sut = UserPermissionService();

  User makeUser({String role = 'user', String id = 'user-1', String? mosqueId}) =>
      User(id: id, email: 'test@test.com', role: role, mosqueId: mosqueId);

  Mosque makeMosque({String adminId = 'admin-1'}) =>
      Mosque(id: 'mosque-1', name: 'Test Mosque', adminId: adminId);

  group('canAddMonth', () {
    test('returns true for admin', () {
      expect(sut.canAddMonth(makeUser(role: 'admin'), makeMosque()), isTrue);
    });
    test('returns true for super_admin', () {
      expect(sut.canAddMonth(makeUser(role: 'super_admin'), makeMosque()), isTrue);
    });
    test('returns true when user is mosque admin', () {
      expect(sut.canAddMonth(makeUser(id: 'admin-1'), makeMosque(adminId: 'admin-1')), isTrue);
    });
    test('returns false for regular user', () {
      expect(sut.canAddMonth(makeUser(), makeMosque()), isFalse);
    });
  });

  group('canUploadRecording', () {
    test('returns true for publisher', () {
      expect(sut.canUploadRecording(makeUser(role: 'publisher'), makeMosque()), isTrue);
    });
    test('returns false for regular user', () {
      expect(sut.canUploadRecording(makeUser(), makeMosque()), isFalse);
    });
  });
}
```

---

### Phase 5 Verification

```bash
flutter test
```

Expected: All new tests pass. Total test count increases from 31.

```bash
flutter analyze
```

Expected: 0 errors, warnings only in test files ≤ 5.

---

## PHASE 6 — UI & Theme Polish

**Why:** Hardcoded color values, missing theme tokens, case-sensitive search, no accessibility labels.

---

### Step 6.1 — Replace hardcoded background colors

**Files to change:**

1. `lib/features/home/presentation/pages/mosques_page.dart`
   - Find: `backgroundColor: const Color(0xFFF9FAFB),`
   - Replace: `backgroundColor: AppColors.greyLight,`

2. `lib/features/mosques/presentation/pages/mosque_detail_page.dart`
   - Find: `backgroundColor: const Color(0xFFF9FAFB),`
   - Replace: `backgroundColor: AppColors.greyLight,`

3. `lib/features/mosques/presentation/pages/day_detail_page.dart`
   - Find: `backgroundColor: const Color(0xFFF5F5F5),`
   - Replace: `backgroundColor: AppColors.greyMedium,`

4. `lib/features/mosques/presentation/pages/day_schedule_page.dart`
   - Find ALL occurrences of: `backgroundColor: const Color(0xFFF5F5F5),`
   - Replace ALL with: `backgroundColor: AppColors.greyMedium,`
   - Add import at top: `import '../../../../core/theme/app_theme.dart';`

5. Run this search for any remaining hardcoded greys:
   ```bash
   grep -rn "Color(0xFFF9FAFB)\|Color(0xFFF5F5F5)" lib/
   ```
   Fix any remaining occurrences the same way.

---

### Step 6.2 — Fix `HomeLayout` nav bar colors

**File:** `lib/features/home/presentation/pages/home_layout.dart`

Find:
```dart
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
```

Replace with:
```dart
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey,
```

---

### Step 6.3 — Add search debounce

**File:** `lib/features/home/presentation/pages/mosques_page.dart`

Add import at the top:
```dart
import 'dart:async';
```

In `_MosquesPageState`, add a field:
```dart
Timer? _debounceTimer;
```

In `dispose()`, add:
```dart
    _debounceTimer?.cancel();
```

Find the `onSearchChanged` handler:
```dart
              onSearchChanged: (query) => setState(() => _searchQuery = query),
```

Replace with:
```dart
              onSearchChanged: (query) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _searchQuery = query);
                });
              },
```

---

### Step 6.4 — Add `Semantics` to key interactive elements

**File:** `lib/features/home/presentation/pages/home_layout.dart`

Wrap the `FloatingActionButton.extended` in `MosquesPage` with a `Semantics` label (this is in `mosques_page.dart`):

**File:** `lib/features/home/presentation/pages/mosques_page.dart`

Find:
```dart
      floatingActionButton: _canAddMosque
          ? FloatingActionButton.extended(
              onPressed: () =>
                  NavigationService.navigateTo(AppRoutes.addMosque),
              backgroundColor: AppColors.primary,
              icon: const Icon(LucideIcons.plus),
              label: const Text(
                'إضافة مسجد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
```

Replace with:
```dart
      floatingActionButton: _canAddMosque
          ? Semantics(
              label: 'إضافة مسجد جديد',
              button: true,
              child: FloatingActionButton.extended(
                onPressed: () =>
                    NavigationService.navigateTo(AppRoutes.addMosque),
                backgroundColor: AppColors.primary,
                icon: const Icon(LucideIcons.plus),
                label: const Text(
                  'إضافة مسجد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
```

---

### Phase 6 Verification

```bash
grep -rn "Color(0xFFF9FAFB)\|Color(0xFFF5F5F5)\|Colors.grey\[400\]" lib/features/home/ lib/features/mosques/presentation/pages/
# Should return 0 results

flutter analyze
flutter test
```

---

## PHASE 7 — Performance

**Why:** `isDownloaded()` reads full JSON on every render. No image caching. `firstWhere` uses try/catch instead of null-safe alternative.

---

### Step 7.1 — Add `collection` package (for `firstWhereOrNull`)

**File:** `pubspec.yaml`

In the `dependencies:` section, add:
```yaml
  collection: ^1.18.0
```

Then run:
```bash
flutter pub get
```

---

### Step 7.2 — Fix `getDownload()` to use `firstWhereOrNull`

**File:** `lib/core/services/downloads_service.dart`

Add import at the top:
```dart
import 'package:collection/collection.dart';
```

Find:
```dart
  /// Get a specific download by recording ID
  Future<DownloadedRecording?> getDownload(String recordingId) async {
    final downloads = await getDownloads();
    try {
      return downloads.firstWhere((d) => d.recordingId == recordingId);
    } catch (e) {
      return null;
    }
  }
```

Replace with:
```dart
  /// Get a specific download by recording ID
  Future<DownloadedRecording?> getDownload(String recordingId) async {
    final downloads = await getDownloads();
    return downloads.firstWhereOrNull((d) => d.recordingId == recordingId);
  }
```

---

### Step 7.3 — Add in-memory cache to `DownloadsService`

**File:** `lib/core/services/downloads_service.dart`

In the class body, add a new field after the existing fields:
```dart
  // In-memory cache — invalidated on every write to avoid stale reads
  List<DownloadedRecording>? _cachedDownloads;
```

Replace the `getDownloads()` method:
```dart
  /// Get all downloaded recordings (uses in-memory cache)
  Future<List<DownloadedRecording>> getDownloads() async {
    if (_cachedDownloads != null) return List.unmodifiable(_cachedDownloads!);
    try {
      final jsonString = _prefs.getString(_downloadsKey);
      if (jsonString == null) {
        _cachedDownloads = [];
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedDownloads = jsonList
          .map((json) => DownloadedRecording.fromJson(json as Map<String, dynamic>))
          .toList();
      return List.unmodifiable(_cachedDownloads!);
    } catch (e) {
      _logger.e('Error loading downloads: $e');
      return [];
    }
  }
```

Replace the `_saveAllDownloads()` method to invalidate the cache:
```dart
  Future<void> _saveAllDownloads(List<DownloadedRecording> downloads) async {
    _cachedDownloads = List.of(downloads); // update cache
    final jsonList = downloads.map((d) => d.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs.setString(_downloadsKey, jsonString);
  }
```

---

### Step 7.4 — Add `cached_network_image`

**File:** `pubspec.yaml`

Add in `dependencies:`:
```yaml
  cached_network_image: ^3.4.1
```

Run:
```bash
flutter pub get
```

Search for any `Image.network(` calls in the codebase:
```bash
grep -rn "Image.network(" lib/
```

For each occurrence found, replace:
```dart
// BEFORE
Image.network(url)

// AFTER
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)
```

Add the import where needed:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

---

### Phase 7 Verification

```bash
flutter pub get
flutter analyze
flutter test
```

---

## PHASE 8 — Lint Strictness

**Why:** `analysis_options.yaml` only has 2 lines. Many bad patterns (unclosed sinks, unawaited futures) are not caught.

---

### Step 8.1 — Replace `analysis_options.yaml`

**File:** `analysis_options.yaml`

Replace the entire file content with:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Correctness
    - cancel_subscriptions
    - close_sinks
    - unawaited_futures
    - avoid_dynamic_calls
    - avoid_type_to_string
    # Style
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_single_quotes
    - sort_constructors_first
    # Flutter
    - use_colored_box
    - use_decorated_box
    - sized_box_for_whitespace

analyzer:
  errors:
    avoid_dynamic_calls: warning
    unawaited_futures: warning
    cancel_subscriptions: error
    close_sinks: error
```

---

### Step 8.2 — Fix all new lint violations

After saving `analysis_options.yaml`, run:

```bash
flutter analyze 2>&1 | head -60
```

For each new warning/error:

- **`cancel_subscriptions`** — Find any `StreamSubscription` that is stored but never cancelled in `dispose()`. Add `.cancel()` in `dispose()`.
- **`close_sinks`** — Find any `StreamController` that is never closed. Add `.close()` in `dispose()`.
- **`unawaited_futures`** — Find any `Future` returned from a method call that is not `await`ed. Add `await` or `unawaited(...)` from `dart:async`.
- **`always_declare_return_types`** — Add explicit return types to any function/method missing them.
- **`prefer_single_quotes`** — Change `"string"` to `'string'` where flagged (you can run `dart fix --apply` to handle this automatically).

Run `dart fix --apply` to auto-fix mechanical issues:
```bash
dart fix --apply
```

Then re-run `flutter analyze` and fix remaining issues manually.

---

### Phase 8 Verification

```bash
flutter analyze
# Target: 0 errors, < 5 warnings (all in test files only)
flutter test
```

---

## PHASE 9 — Documentation

**Why:** `.ai/` folder exists but is incomplete. No `CHANGELOG.md`. No formal conventions documented.

---

### Step 9.1 — Create `.ai/ARCHITECTURE.md`

**Create file:** `.ai/ARCHITECTURE.md`

```markdown
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
```

---

### Step 9.2 — Create `.ai/STATE_MANAGEMENT.md`

**Create file:** `.ai/STATE_MANAGEMENT.md`

```markdown
# State Management

## Library: flutter_riverpod ^2.6.1

## Conventions

### Notifiers
- Feature notifiers extend `AsyncNotifier<T>` (for async data) or `Notifier<T>` (for sync state).
- Providers are declared at file scope, not inside classes.
- Notifier files are co-located with their providers in `presentation/providers/`.

### Pagination Pattern
When loading more pages, always preserve the existing list:
```dart
// CORRECT — keeps list visible during load
state = const AsyncValue<List<X>>.loading().copyWithPrevious(state);

// WRONG — wipes list, causes flash
state = const AsyncValue.loading();
```

### Error Recovery
Always attach previous value to error state so UI can show stale data:
```dart
state = AsyncValue<List<X>>.error(e, st).copyWithPrevious(previousState);
```

### `ref.watch` vs `ref.read`
- In `build()` or reactive contexts: always `ref.watch`.
- In event handlers (`onPressed`, `onTap`): `ref.read`.
- **Never** `ref.read` inside `build()` for a value that can change.

## AuthState
Location: `lib/features/auth/presentation/state/auth_state.dart`
States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`
```

---

### Step 9.3 — Create `.ai/CONVENTIONS.md`

**Create file:** `.ai/CONVENTIONS.md`

```markdown
# Conventions

## Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `camelCase` (Dart convention, not SCREAMING_SNAKE)
- Providers: `<noun>Provider` (e.g., `mosqueRepositoryProvider`)
- Notifiers: `<Noun>Notifier` (e.g., `MosqueNotifier`)

## Errors
- Data layer throws typed `AppException` subclasses (from `core/error/exceptions.dart`).
- Never throw `Exception('some message')` — always use a typed exception.
- Never put Arabic user-facing strings in data sources. Map to Failure in the repository.
- Use `executeWithCatch()` in all repository implementations.

## Logging
- Use `AppLogger` (injected via Riverpod or GetIt bootstrap).
- Level guide:
  - `d()` = debug (dev only)
  - `i()` = significant lifecycle event (init, success)
  - `w()` = recoverable non-critical issue
  - `e()` = error with exception and stack trace
- Do NOT log FCM tokens, passwords, or personal data at any level.

## Imports
- Use relative imports within the same feature.
- Use package imports (`package:sout_salah/...`) across features.

## Single Quotes
- All Dart string literals use single quotes: `'text'`, not `"text"`.

## No `dynamic`
- Never use `dynamic` as a return type or variable type. Use specific types or generics.

## Permissions / Roles
- Never write `user.role == 'admin'` in UI code.
- Always use `UserPermissionService` methods.
```

---

### Step 9.4 — Create `.ai/TESTING.md`

**Create file:** `.ai/TESTING.md`

```markdown
# Testing

## Framework
- `flutter_test` for unit and widget tests
- `mocktail` for mocking (NOT `mockito`)

## Coverage Targets
| Layer | Target |
|---|---|
| Domain entities | 100% |
| Domain use cases | 100% |
| Domain services (UserPermissionService) | 100% |
| Data repositories | 80%+ |
| Core services (Downloads, Favorites) | 80%+ |
| Riverpod notifiers | 70%+ |
| Widgets/pages | 60%+ |

## Test File Location
Mirror the `lib/` structure under `test/`:
```
test/
├── core/
│   └── utils/
│       └── failure_mapper_test.dart
└── features/
    ├── auth/
    │   ├── data/repositories/auth_repository_test.dart
    │   ├── domain/services/user_permission_service_test.dart
    │   └── presentation/providers/auth_notifier_test.dart
    └── mosques/
        ├── data/
        │   ├── repositories/mosque_repository_test.dart
        │   └── services/
        │       ├── downloads_service_test.dart
        │       └── favorites_service_test.dart
        ├── domain/
        │   ├── entities/prayer_test.dart
        │   └── usecases/...
        └── presentation/
            ├── pages/...
            └── providers/
                ├── mosque_notifier_test.dart
                └── upload_recording_notifier_test.dart
```

## Mock Convention
Always use `mocktail`:
```dart
class MockMosqueRepository extends Mock implements MosqueRepository {}
// In setUp:
registerFallbackValue(const Right<Failure, List<Mosque>>([]));
```

## Test Name Convention
Format: `'<method/scenario> <condition> <expected result>'`
Example: `'getDownloads returns empty list when SharedPreferences has no data'`
```

---

### Step 9.5 — Create `CHANGELOG.md`

**Create file:** `CHANGELOG.md` (at the project root)

```markdown
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
```

---

### Phase 9 Verification

```bash
# All files should exist:
ls .ai/ARCHITECTURE.md .ai/STATE_MANAGEMENT.md .ai/CONVENTIONS.md .ai/TESTING.md CHANGELOG.md

flutter analyze
flutter test
```

---

## Final Verification (Run After All Phases)

```bash
cd "/home/eslam/flutter dev/sout_salah"

# 1. No secrets in git
git log --all --oneline -- secrets.json
# Expected: (empty)

# 2. No inline role checks in UI
grep -rn "user.role ==" lib/
# Expected: 0 results

# 3. No hardcoded grey background colors
grep -rn "Color(0xFFF9FAFB)\|Color(0xFFF5F5F5)" lib/
# Expected: 0 results

# 4. Static analysis clean
flutter analyze
# Expected: 0 errors, warnings only

# 5. All tests pass
flutter test --reporter=expanded
# Expected: All tests pass, count > 31

# 6. Commit everything
git add -A
git status
```

## Commit Message for Final Commit

```
feat: senior-level codebase upgrade (Phases 1-9)

Architecture:
- Consolidate DI: AppRouter no longer uses GetIt
- AudioPlayerService, DownloadsService, FavoritesService properly disposed
- Add NavigationService Riverpod provider

Error Handling:
- Add UserNotFoundException, AudioPlaybackException typed exceptions
- addPublisher no longer puts Arabic text in data layer
- All data sources preserve error messages in ServerException

State Management:
- Fix loadMore() to use copyWithPrevious (no pagination list flash)
- Add FailureMapper utility (single source of truth)
- Rename auth state folder: bloc/ -> state/
- Fix ref.read -> ref.watch for hasMore in build()
- Add copyWith to Mosque, Recording, RamadanDay

Authorization:
- Add UserPermissionService in domain layer
- Remove all inline user.role == 'admin' checks from UI

Testing:
- Fix 14 existing analyzer warnings in test files
- Add DownloadsService unit tests
- Add FavoritesService unit tests
- Add MosqueNotifier unit tests
- Add FailureMapper unit tests
- Add UserPermissionService unit tests

UI:
- Replace all hardcoded Color(0xFFF9FAFB) with AppColors.greyLight
- Replace nav bar Colors.white with AppColors.white
- Add 300ms search debounce
- Case-insensitive mosque search
- Add Semantics to FAB

Performance:
- Add in-memory cache to DownloadsService
- Add cached_network_image package
- Fix firstWhere -> firstWhereOrNull

Lint:
- Upgrade analysis_options.yaml with stricter rules
- Run dart fix --apply

Docs:
- Add .ai/ARCHITECTURE.md
- Add .ai/STATE_MANAGEMENT.md
- Add .ai/CONVENTIONS.md
- Add .ai/TESTING.md
- Add CHANGELOG.md
```
