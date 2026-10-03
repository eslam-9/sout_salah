import 'package:sout_salah/features/auth/domain/entities/user.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';

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

  /// Is this user a system admin (can review mosque requests)?
  /// Covers both 'admin' and 'super_admin' roles.
  bool isAdmin(User user) => _isAdmin(user) || _isSuperAdmin(user);

  bool _isAdmin(User user) => user.role == _adminRole;
  bool _isSuperAdmin(User user) => user.role == _superAdminRole;
  bool _isPublisher(User user) => user.role == _publisherRole;
}
