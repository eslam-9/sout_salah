import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sout_salah/core/di/riverpod_providers.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/usecases/usecase.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:sout_salah/features/auth/domain/entities/user.dart';
import 'package:sout_salah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sout_salah/features/auth/domain/usecases/auth_usecases.dart';
import 'package:sout_salah/features/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:sout_salah/features/auth/domain/usecases/sign_up_params.dart';
import 'package:sout_salah/features/auth/presentation/bloc/auth_state.dart';
import 'package:sout_salah/features/auth/presentation/providers/auth_controller.dart';
import 'package:sout_salah/features/auth/presentation/providers/auth_data_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    if (!GetIt.I.isRegistered<AppLogger>()) {
      GetIt.I.registerSingleton<AppLogger>(MockAppLogger());
    }
  });

  setUp(() async {
    mockAuthRepository = MockAuthRepository();
    final sharedPrefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const tUser = User(id: '123', email: 'test@test.com', username: 'Test');
  const tEmail = 'test@test.com';
  const tPassword = 'password123';

  group('AuthNotifier', () {
    test('initial state should be AuthInitial', () {
      final state = container.read(authProvider);
      expect(state, isA<AuthInitial>());
    });

    test('signIn should update state to AuthLoading then AuthAuthenticated on success', () async {
      when(() => mockAuthRepository.signInWithEmailAndPassword(tEmail, tPassword))
          .thenAnswer((_) async => const Right(tUser));

      final notifier = container.read(authProvider.notifier);

      expect(container.read(authProvider), isA<AuthInitial>());

      final future = notifier.signIn(tEmail, tPassword);
      
      // Right after calling, state should be loading
      expect(container.read(authProvider), isA<AuthLoading>());

      await future;

      // After completion, state should be authenticated
      expect(container.read(authProvider), isA<AuthAuthenticated>());
      final authState = container.read(authProvider) as AuthAuthenticated;
      expect(authState.user, tUser);
    });

    test('signIn should update state to AuthError on failure', () async {
      when(() => mockAuthRepository.signInWithEmailAndPassword(tEmail, tPassword))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid credentials')));

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn(tEmail, tPassword);

      expect(container.read(authProvider), isA<AuthError>());
      final authState = container.read(authProvider) as AuthError;
      expect(authState.message, 'Invalid credentials');
    });

    test('signOut should update state to AuthUnauthenticated', () async {
      when(() => mockAuthRepository.signOut())
          .thenAnswer((_) async => const Right(null));

      final notifier = container.read(authProvider.notifier);
      await notifier.signOut();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });
  });
}
