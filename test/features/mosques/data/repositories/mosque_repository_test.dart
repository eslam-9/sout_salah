import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sout_salah/core/error/exceptions.dart';
import 'package:sout_salah/core/error/failures.dart';
import 'package:sout_salah/features/mosques/data/datasources/mosque_remote_data_source.dart';
import 'package:sout_salah/features/mosques/data/repositories/mosque_repository_impl.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';
import 'package:sout_salah/features/mosques/data/models/mosque_model.dart';

class MockMosqueRemoteDataSource extends Mock implements MosqueRemoteDataSource {}

void main() {
  late MosqueRepositoryImpl repository;
  late MockMosqueRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockMosqueRemoteDataSource();
    repository = MosqueRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tMosqueModel = MosqueModel(
    id: '123',
    name: 'Test Mosque',
    location: 'Test Location',
    adminId: 'admin123',
  );
  const tMosque = tMosqueModel;

  group('getMosques', () {
    test('should return list of Mosques when successful', () async {
      when(() => mockRemoteDataSource.getMosques(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => const [tMosqueModel]);

      final result = await repository.getMosques();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (r) => expect(r, equals([tMosque])),
      );
      verify(() => mockRemoteDataSource.getMosques()).called(1);
    });

    test('should return ServerFailure when an exception occurs', () async {
      when(() => mockRemoteDataSource.getMosques(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenThrow(ServerException('Database error'));

      final result = await repository.getMosques();

      expect(result, const Left(ServerFailure(message: 'Database error')));
    });
  });

  group('addMosque', () {
    test('should return added Mosque when successful', () async {
      when(() => mockRemoteDataSource.addMosque(
            name: 'Test Mosque',
            location: 'Test Location',
            description: null,
          )).thenAnswer((_) async => tMosqueModel);

      final result = await repository.addMosque(
        name: 'Test Mosque',
        location: 'Test Location',
      );

      expect(result, const Right(tMosque));
    });
  });
}
