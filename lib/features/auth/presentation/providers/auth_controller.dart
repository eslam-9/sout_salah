import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/riverpod_providers.dart';

import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import 'auth_data_providers.dart';
import '../state/auth_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/usecases/sign_up_params.dart';
import '../../../../core/services/notification_service.dart';

// UseCases Providers (or direct usage)
final signInUseCaseProvider = Provider(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);
final signUpUseCaseProvider = Provider(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);
final signInAnonymouslyUseCaseProvider = Provider(
  (ref) => SignInAnonymouslyUseCase(ref.watch(authRepositoryProvider)),
);
final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);
final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
);
final updateProfileUseCaseProvider = Provider(
  (ref) => UpdateProfileUseCase(ref.watch(authRepositoryProvider)),
);

// Provider to track if initial auth check has been completed
final initialCheckDoneProvider = StateProvider<bool>((ref) => false);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthInitial();
  }

  Future<void> checkAuthStatus() async {
    state = AuthLoading();
    final result = await ref.read(getCurrentUserUseCaseProvider)(NoParams());

    result.fold((failure) => state = AuthUnauthenticated(), (user) {
      NotificationService.registerToken(user.id);
      state = AuthAuthenticated(user: user);
    });
  }

  void reset() {
    state = AuthInitial();
  }

  Future<void> signIn(String email, String password) async {
    state = AuthLoading();
    final result = await ref.read(signInUseCaseProvider)(
      SignInParams(email: email, password: password),
    );
    result.fold(
      (failure) => state = AuthError(message: mapFailureToMessage(failure)),
      (user) {
        ref.read(sharedPreferencesProvider).setBool('is_guest_mode', false);
        NotificationService.registerToken(user.id);
        state = AuthAuthenticated(user: user);
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    state = AuthLoading();
    final result = await ref.read(signUpUseCaseProvider)(
      SignUpParams(email: email, password: password, username: username),
    );
    result.fold(
      (failure) => state = AuthError(message: mapFailureToMessage(failure)),
      (user) {
        ref.read(sharedPreferencesProvider).setBool('is_guest_mode', false);
        NotificationService.registerToken(user.id);
        state = AuthAuthenticated(user: user);
      },
    );
  }

  Future<void> signInAnonymously() async {
    state = AuthLoading();
    final result = await ref.read(signInAnonymouslyUseCaseProvider)(NoParams());
    result.fold(
      (failure) => state = AuthError(message: mapFailureToMessage(failure)),
      (user) {
        ref.read(sharedPreferencesProvider).setBool('is_guest_mode', true);
        NotificationService.registerToken(user.id);
        state = AuthAuthenticated(user: user);
      },
    );
  }

  Future<void> signOut() async {
    // Remove token before logging out
    if (state is AuthAuthenticated) {
      final userId = (state as AuthAuthenticated).user.id;
      unawaited(NotificationService.removeToken(userId));
    }

    final result = await ref.read(signOutUseCaseProvider)(NoParams());
    result.fold(
      (failure) => state = AuthError(message: mapFailureToMessage(failure)),
      (_) {
        ref.read(sharedPreferencesProvider).setBool('is_guest_mode', false);
        state = AuthUnauthenticated();
      },
    );
  }

  Future<bool> updateUsername(String username) async {
    if (state is! AuthAuthenticated) return false;
    final userId = (state as AuthAuthenticated).user.id;

    final result = await ref.read(updateProfileUseCaseProvider)(
      UpdateProfileParams(userId: userId, username: username),
    );
    return result.fold(
      (failure) {
        state = AuthError(message: mapFailureToMessage(failure));
        return false;
      },
      (user) {
        state = AuthAuthenticated(user: user);
        return true;
      },
    );
  }
}
