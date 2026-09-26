import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/core/network/network_info.dart';
import 'package:sout_salah/core/di/riverpod_providers.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';
import 'package:sout_salah/features/mosques/domain/repositories/mosque_repository.dart';
import 'package:sout_salah/features/mosques/presentation/providers/mosque_controller.dart';
import 'package:sout_salah/features/mosques/presentation/providers/mosque_data_providers.dart';

class MockMosqueRepository extends Mock implements MosqueRepository {}

/// Fake NetworkInfo — connectivity_plus has no platform channel in unit tests.
class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({this.connected = true});
  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

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
        networkInfoProvider.overrideWithValue(FakeNetworkInfo()),
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

      // Start listening so the notifier builds, then check the error state.
      container.read(mosqueProvider);
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
