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
