import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SimpleFcmScheduler {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initializationSettings);
  }

  static Future<void> scheduleLocalNotification(TimeOfDay time, {String? message}) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _localNotifications.zonedSchedule(
      time.hour * 100 + time.minute,
      'Blissed Reminder',
      message ?? 'This is your scheduled reminder!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'simple_channel',
          'Simple Reminders',
          channelDescription: 'Simple scheduled reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> sendFcmNotification(String token, String title, String body) async {
    // This is a placeholder. FCM notifications must be sent from a backend server or cloud function.
    // Here, you would call your backend API to trigger an FCM push notification.
    debugPrint('Would send FCM notification to $token: $title - $body');
  }
} 