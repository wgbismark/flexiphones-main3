import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';

mixin Notify {
  Future<void> initializeNotifications() async {
    // Initialize plugin
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Simple notification channel',
        defaultColor: const Color(0xFF9D50DD),
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ]);

    // Request required permissions
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Optionally show rationale UI before asking
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
    }
 
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
      ),
    );
  }
}
