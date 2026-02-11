import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for checking mosque-specific permissions
class MosquePermissions {
  final SupabaseClient _supabase;

  MosquePermissions(this._supabase);

  /// Check if current user is a super admin (global admin)
  Future<bool> isSuperAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check the profile for role 'admin'
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return profile?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is admin of a specific mosque
  Future<bool> isAdmin(String mosqueId) async {
    try {
      // Super admins are admins of all mosques
      if (await isSuperAdmin()) return true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('mosques')
          .select('admin_id')
          .eq('id', mosqueId)
          .maybeSingle();

      return result?['admin_id'] == userId;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is a publisher for a specific mosque
  Future<bool> isPublisher(String mosqueId) async {
    try {
      // Super admins are publishers for all mosques
      if (await isSuperAdmin()) return true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('mosque_publishers')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('publisher_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can upload to a specific mosque
  Future<bool> canUpload(String mosqueId) async {
    // Super admin check is already done inside isAdmin
    final admin = await isAdmin(mosqueId);
    if (admin) return true;

    return await isPublisher(mosqueId);
  }

  /// Check if current user can delete a specific recording
  Future<bool> canDelete(String recordingId, String mosqueId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if user is admin of the mosque (includes super admin)
      final admin = await isAdmin(mosqueId);
      if (admin) return true;

      // Check if user is the publisher who created the recording
      final result = await _supabase
          .from('recordings')
          .select('publisher_id')
          .eq('id', recordingId)
          .maybeSingle();

      return result?['publisher_id'] == userId;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can manage publishers for a mosque
  Future<bool> canManagePublishers(String mosqueId) async {
    return await isAdmin(mosqueId);
  }
}
