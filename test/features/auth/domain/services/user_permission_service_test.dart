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
