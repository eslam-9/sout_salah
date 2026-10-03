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
