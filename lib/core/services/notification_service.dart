import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import '../utils/app_logger.dart';

/// Handles background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // ignore: avoid_print
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final _logger = GetIt.I<AppLogger>();
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  // Token expiration check interval (24 hours)
  static const Duration _tokenCheckInterval = Duration(hours: 24);
  static DateTime? _lastTokenCheck;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permissions for iOS and newer Android versions
      await requestPermissions();

      // Handle foreground messages
      setupForegroundHandler();

      // Listen for token refreshes once, globally (not per-user call)
      _setupTokenRefreshListener();

      // Perform initial token check
      await _checkAndRefreshTokenIfNeeded();

      _logger.i('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize NotificationService', e, stackTrace);
    }
  }

  /// Sets up a single global listener for FCM token refreshes.
  ///
  /// Re-registers the new token for the currently authenticated user.
  /// Guards against unauthenticated writes that would violate RLS.
  static void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _logger.w(
          'Token refreshed but no authenticated user — skipping registration.',
        );
        return;
      }
      try {
        await _upsertToken(userId: userId, token: newToken);
        _logger.i('Refreshed FCM token registered in Supabase');
      } catch (e) {
        _logger.e('Error updating refreshed FCM token', e);
      }
    });
  }

  /// Request notification permissions
  static Future<void> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _logger.i('User granted permission: ${settings.authorizationStatus}');
  }

  /// Setup handler for when the app is in the foreground
  static void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Got a message whilst in the foreground!');
      _logger.i('Message data: ${message.data}');

      if (message.notification != null) {
        _logger.i(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });
  }

  /// Check if token needs refresh and refresh if needed
  static Future<void> _checkAndRefreshTokenIfNeeded() async {
    final now = DateTime.now();

    // Check if we need to refresh the token (based on interval or if never checked)
    if (_lastTokenCheck == null ||
        now.difference(_lastTokenCheck!) > _tokenCheckInterval) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          _logger.i('Token check: FCM token is $token');
          // We could send this to our backend to validate/update if needed
          // For now, we just update our last check time
          _lastTokenCheck = now;
        }
      } catch (e) {
        _logger.e('Error checking FCM token', e);
      }
    }
  }

  /// Register the FCM token with Supabase for the given user.
  ///
  /// Safe to call multiple times — uses upsert to avoid duplicate entries.
  static Future<void> registerToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        _logger.w('Failed to get FCM token');
        return;
      }

      _logger.i('FCM Token: $token');
      await _upsertToken(userId: userId, token: token);
      _logger.i('FCM token registered in Supabase');
    } catch (e, stackTrace) {
      _logger.e('Failed to register FCM token', e, stackTrace);
    }
  }

  /// Upserts an FCM token row for the given user.
  ///
  /// Uses Supabase upsert with `onConflict` so a single DB round-trip
  /// handles both insert and update without a preceding SELECT.
  static Future<void> _upsertToken({
    required String userId,
    required String token,
  }) => _supabase.from('fcm_tokens').upsert({
    'user_id': userId,
    'token': token,
    'platform': Platform.isAndroid ? 'android' : 'ios',
    'updated_at': DateTime.now().toIso8601String(),
  }, onConflict: 'user_id,token');

  /// Remove FCM token from Supabase on logout
  static Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _supabase
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);

        await _messaging.deleteToken();
        _logger.i('FCM token removed from Supabase and deleted locally');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to remove FCM token', e, stackTrace);
    }
  }

  /// Send a notification via Supabase Edge Function
  static Future<void> sendNotification({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.i('Invoking send-notification Edge Function for type: $type');

      final response = await _supabase.functions.invoke(
        'send-notification',
        body: {'type': type, 'data': data},
      );

      if (response.status >= 200 && response.status < 300) {
        _logger.i('Notification sent successfully: ${response.data}');
      } else {
        _logger.e(
          'Failed to send notification: ${response.status} - ${response.data}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Exception invoking send-notification Edge Function',
        e,
        stackTrace,
      );
    }
  }
}
