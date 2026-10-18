import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs when a push arrives while the app is closed or in the background.
/// Android shows "notification" messages by itself; nothing else to do.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Firebase Cloud Messaging (Android only for now).
///
/// Every phone joins the topic "all", plus "customers" / "agents" for the
/// signed-in role, so pushes can be sent from the Firebase console
/// (Messaging → New campaign → Topic) without any server change.
/// The device token is kept in [token] (and saved as "fcm_token") for when
/// the server starts sending to single phones.
class PushService {
  static String? token;
  static bool _started = false;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (!_supported || _started) return;
    _started = true;
    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();

      token = await fm.getToken();
      debugPrint("=== [push] FCM token: $token");
      await _saveToken(token);
      fm.onTokenRefresh.listen((t) {
        token = t;
        _saveToken(t);
      });

      await fm.subscribeToTopic("all");

      // While the app is open Android doesn't show the push itself, so
      // show it the same way as the app's other notifications.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        final title = n?.title ?? m.data['title']?.toString();
        final body = n?.body ?? m.data['body']?.toString() ?? m.data['message']?.toString();
        if (title == null && body == null) return;
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'basic_channel',
            title: title ?? "FlexiPhones",
            body: body ?? "",
            bigPicture: n?.android?.imageUrl,
            notificationLayout:
                n?.android?.imageUrl != null
                    ? NotificationLayout.BigPicture
                    : NotificationLayout.Default,
          ),
        );
      });
    } catch (e) {
      debugPrint("!!! [push] init failed: $e");
    }
  }

  /// Keeps the role topics in step with who is signed in.
  static Future<void> setRoles({required bool customer, required bool agent}) async {
    if (!_supported || !_started) return;
    try {
      final fm = FirebaseMessaging.instance;
      customer
          ? await fm.subscribeToTopic("customers")
          : await fm.unsubscribeFromTopic("customers");
      agent
          ? await fm.subscribeToTopic("agents")
          : await fm.unsubscribeFromTopic("agents");
    } catch (_) {}
  }

  static Future<void> _saveToken(String? t) async {
    if (t == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm_token", t);
    } catch (_) {}
  }
}
