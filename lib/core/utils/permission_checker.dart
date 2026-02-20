import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mosque_permissions.dart';

/// Provider for MosquePermissions utility
final mosquePermissionsProvider = Provider<MosquePermissions>((ref) {
  return MosquePermissions(Supabase.instance.client);
});

/// Permission checker for UI components
class PermissionChecker {
  final MosquePermissions _permissions;

  PermissionChecker(this._permissions);

  /// Check if user can see upload button
  Future<bool> canShowUploadButton(String mosqueId) async {
    return await _permissions.canUpload(mosqueId);
  }

  /// Check if user can see delete button for a recording
  Future<bool> canShowDeleteButton(String recordingId, String mosqueId) async {
    return await _permissions.canDelete(recordingId, mosqueId);
  }

  /// Check if user can see manage publishers button
  Future<bool> canShowManagePublishersButton(String mosqueId) async {
    return await _permissions.canManagePublishers(mosqueId);
  }

  /// Check if user is admin (for showing admin badge)
  Future<bool> isAdminOfMosque(String mosqueId) async {
    return await _permissions.isAdmin(mosqueId);
  }

  /// Check if user can add a new mosque (Super Admin only)
  Future<bool> canAddMosque() async {
    return await _permissions.isSuperAdmin();
  }
}

/// Provider for PermissionChecker
final permissionCheckerProvider = Provider<PermissionChecker>((ref) {
  final permissions = ref.watch(mosquePermissionsProvider);
  return PermissionChecker(permissions);
});
