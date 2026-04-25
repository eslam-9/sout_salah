import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/providers.dart';

import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import 'auth_data_providers.dart';
import '../bloc/auth_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signInUseCase: ref.watch(signInUseCaseProvider),
    signUpUseCase: ref.watch(signUpUseCaseProvider),
    signInAnonymouslyUseCase: ref.watch(signInAnonymouslyUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignInAnonymouslyUseCase signInAnonymouslyUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  final SharedPreferences sharedPreferences;

  AuthNotifier({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signInAnonymouslyUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.updateProfileUseCase,
    required this.sharedPreferences,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    state = AuthLoading();

    final result = await getCurrentUserUseCase(NoParams());
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
    final result = await signInUseCase(
      SignInParams(email: email, password: password),
    );
    result.fold(
      (failure) => state = AuthError(message: _mapFailureToMessage(failure)),
      (user) {
        sharedPreferences.setBool('is_guest_mode', false);
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
    final result = await signUpUseCase(
      SignUpParams(email: email, password: password, username: username),
    );
    result.fold(
      (failure) => state = AuthError(message: _mapFailureToMessage(failure)),
      (user) {
        sharedPreferences.setBool('is_guest_mode', false);
        NotificationService.registerToken(user.id);
        state = AuthAuthenticated(user: user);
      },
    );
  }

  Future<void> signInAnonymously() async {
    state = AuthLoading();
    final result = await signInAnonymouslyUseCase(NoParams());
    result.fold(
      (failure) => state = AuthError(message: _mapFailureToMessage(failure)),
      (user) {
        sharedPreferences.setBool('is_guest_mode', true);
        NotificationService.registerToken(user.id);
        state = AuthAuthenticated(user: user);
      },
    );
  }

  Future<void> signOut() async {
    // Remove token before logging out
    if (state is AuthAuthenticated) {
      final userId = (state as AuthAuthenticated).user.id;
      NotificationService.removeToken(userId);
    }

    final result = await signOutUseCase(NoParams());
    result.fold(
      (failure) => state = AuthError(message: _mapFailureToMessage(failure)),
      (_) {
        sharedPreferences.setBool('is_guest_mode', false);
        state = AuthUnauthenticated();
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Failure';
    } else if (failure is CacheFailure) {
      return 'Cache Failure';
    } else {
      return 'Unexpected Error';
    }
  }

  Future<bool> updateUsername(String username) async {
    if (state is! AuthAuthenticated) return false;
    final userId = (state as AuthAuthenticated).user.id;

    final result = await updateProfileUseCase(
      UpdateProfileParams(userId: userId, username: username),
    );
    return result.fold(
      (failure) {
        state = AuthError(message: _mapFailureToMessage(failure));
        return false;
      },
      (user) {
        state = AuthAuthenticated(user: user);
        return true;
      },
    );
  }
}
