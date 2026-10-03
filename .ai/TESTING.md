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
