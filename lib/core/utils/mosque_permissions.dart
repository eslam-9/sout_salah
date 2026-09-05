import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for checking mosque-specific permissions
class MosquePermissions {
  final SupabaseClient _supabase;
  
  // Cache to store permission results to avoid redundant DB calls
  final Map<String, bool> _cache = {};

  MosquePermissions(this._supabase) {
    // Clear cache when auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut || data.event == AuthChangeEvent.signedIn) {
        _cache.clear();
      }
    });
  }

  /// Check if current user is a super admin (global admin)
  Future<bool> isSuperAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final cacheKey = 'super_admin_$userId';
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

      // Check the profile for role 'admin'
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final isSuper = profile?['role'] == 'admin';
      _cache[cacheKey] = isSuper;
      return isSuper;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is admin of a specific mosque
  Future<bool> isAdmin(String mosqueId) async {
    try {
      if (await isSuperAdmin()) return true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final cacheKey = 'admin_${userId}_$mosqueId';
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

      final result = await _supabase
          .from('mosques')
          .select('admin_id')
          .eq('id', mosqueId)
          .maybeSingle();

      final isMosqueAdmin = result?['admin_id'] == userId;
      _cache[cacheKey] = isMosqueAdmin;
      return isMosqueAdmin;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is a publisher for a specific mosque
  Future<bool> isPublisher(String mosqueId) async {
    try {
      if (await isSuperAdmin()) return true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final cacheKey = 'publisher_${userId}_$mosqueId';
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

      final result = await _supabase
          .from('mosque_publishers')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('publisher_id', userId)
          .maybeSingle();

      final isMosquePublisher = result != null;
      _cache[cacheKey] = isMosquePublisher;
      return isMosquePublisher;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can upload to a specific mosque
  Future<bool> canUpload(String mosqueId) async {
    final admin = await isAdmin(mosqueId);
    if (admin) return true;

    return await isPublisher(mosqueId);
  }

  /// Check if current user can delete a specific recording
  Future<bool> canDelete(String recordingId, String mosqueId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final admin = await isAdmin(mosqueId);
      if (admin) return true;
      
      final cacheKey = 'delete_${userId}_$recordingId';
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

      final result = await _supabase
          .from('recordings')
          .select('publisher_id')
          .eq('id', recordingId)
          .maybeSingle();

      final canDeleteRecording = result?['publisher_id'] == userId;
      _cache[cacheKey] = canDeleteRecording;
      return canDeleteRecording;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can manage publishers for a mosque
  Future<bool> canManagePublishers(String mosqueId) async {
    return await isAdmin(mosqueId);
  }
}
