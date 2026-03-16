import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
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

      _logger.i('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize NotificationService', e, stackTrace);
    }
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

  /// Register the FCM token with Supabase for the given user
  static Future<void> registerToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        _logger.w('Failed to get FCM token');
        return;
      }

      _logger.i('FCM Token: $token');

      // Check if token already exists for this user to avoid unnecessary writes
      final existingTokens = await _supabase
          .from('fcm_tokens')
          .select()
          .eq('user_id', userId)
          .eq('token', token);

      if (existingTokens.isEmpty) {
        await _supabase.from('fcm_tokens').insert({
          'user_id': userId,
          'token': token,
          'platform': 'android', // Assuming Android for now
        });
        _logger.i('FCM token registered in Supabase');
      } else {
        _logger.i('FCM token already registered for this user');
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          // If the old token isn't easily accessible, we just insert the new one
          // The old one will eventually become invalid and can be cleaned up
          final existing = await _supabase
              .from('fcm_tokens')
              .select()
              .eq('user_id', userId)
              .eq('token', newToken);

          if (existing.isEmpty) {
            await _supabase.from('fcm_tokens').insert({
              'user_id': userId,
              'token': newToken,
              'platform': 'android',
            });
            _logger.i('Refreshed FCM token registered in Supabase');
          }
        } catch (e) {
          _logger.e('Error updating refreshed FCM token', e);
        }
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to register FCM token', e, stackTrace);
    }
  }

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
