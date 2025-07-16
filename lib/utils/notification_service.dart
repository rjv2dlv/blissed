import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import '../screens/reminder_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e, s) {
        debugPrint('Timezone init failed: $e');
        FirebaseCrashlytics.instance.recordError(e, s);
    }
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Safe no-op or actual navigation
        debugPrint('Notification clicked: ${details.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground, // Optional for background support
    );
  }

  static Future<void> scheduleDailyReflectionReminder(TimeOfDay time) async {
    await _notificationsPlugin.zonedSchedule(
      1001,
      'Blissed: Time to Reflect!',
      'Don\'t forget to complete your self-reflection and set your intentions.',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reflection_channel',
          'Reflection Reminders',
          channelDescription: 'Reminders for daily self-reflection',
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

  static Future<void> scheduleDailyActionsReminder(TimeOfDay time) async {
    await _notificationsPlugin.zonedSchedule(
      1002,
      'Blissed: Complete Your Actions!',
      'You have actions pending for today. Take a step forward!',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'actions_channel',
          'Actions Reminders',
          channelDescription: 'Reminders for daily actions',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> scheduleSmartReminder(TimeOfDay time) async {
    final int id = time.hour * 100 + time.minute;
    String title = 'Blissed Reminder';
    String body = '';

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}_${now.month}_${now.day}';
    final notifiedKey = 'reminder_types_notified_$dateKey';
    final notifiedTasksKey = 'reminder_tasks_notified_$dateKey';

    // Reset tracking if new day
    final lastTrackedDay = prefs.getString('reminder_last_tracked_day');
    if (lastTrackedDay != dateKey) {
      await prefs.setString('reminder_last_tracked_day', dateKey);
      await prefs.remove(notifiedKey);
      await prefs.remove(notifiedTasksKey);
    }

    // Get which types have been notified today
    final notifiedTypes = prefs.getStringList(notifiedKey) ?? [];
    final notifiedTasks = prefs.getStringList(notifiedTasksKey) ?? [];
    final List<String> possibleTypes = ['pendingTask', 'reflection', 'missingActivity'];
    // Track last notified type to avoid consecutive repeats
    final lastTypeKey = 'reminder_last_type_$dateKey';
    final lastType = prefs.getString(lastTypeKey);
    List<String> availableTypes = possibleTypes.where((t) => !notifiedTypes.contains(t)).toList();

    // Always prioritize pending tasks if any exist and not all have been notified
    final actionsString = prefs.getString('daily_actions_$dateKey');
    List<String> allPendingTasks = [];
    if (actionsString != null) {
      final actions = List<Map<String, dynamic>>.from(json.decode(actionsString));
      allPendingTasks = actions.where((a) => a['status'] == 'pending').map((a) => a['text'] as String).toList();
    }
    final hasPendingTasks = allPendingTasks.isNotEmpty;

    // Remove lastType from availableTypes to avoid consecutive repeats
    if (lastType != null && availableTypes.length > 1) {
      availableTypes = availableTypes.where((t) => t != lastType).toList();
    }

    // If all types have been notified, but there are still pending tasks, allow pendingTask again
    if (availableTypes.isEmpty && hasPendingTasks) {
      availableTypes = ['pendingTask'];
    }

    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    print('[Reminder] Scheduling smart reminder for $timeStr');
    print('[Reminder] Notified types today: ' + (notifiedTypes.isEmpty ? 'none' : notifiedTypes.join(', ')));
    print('[Reminder] Notified tasks today: ' + (notifiedTasks.isEmpty ? 'none' : notifiedTasks.join(', ')));
    print('[Reminder] All pending tasks: ' + (allPendingTasks.isEmpty ? 'none' : allPendingTasks.join(', ')));
    print('[Reminder] Last type: $lastType');
    print('[Reminder] Available types: ' + (availableTypes.isEmpty ? 'none' : availableTypes.join(', ')));

    if (availableTypes.isEmpty) {
      if (hasPendingTasks) {
        print('[Reminder] Skipping reminder: all types notified but pending tasks remain.');
        return;
      } else {
        print('[Reminder] Skipping reminder: all types notified and no pending tasks.');
        return;
      }
    } else {
      final type = availableTypes.first;
      print('[Reminder] Selected type: $type');
      if (type == 'pendingTask') {
        String? pendingTaskText;
        final unnotifiedPendingTasks = allPendingTasks.where((t) => !notifiedTasks.contains(t)).toList();
        print('[Reminder] Unnotified pending tasks: ' + (unnotifiedPendingTasks.isEmpty ? 'none' : unnotifiedPendingTasks.join(', ')));
        if (unnotifiedPendingTasks.isNotEmpty) {
          final random = Random();
          pendingTaskText = unnotifiedPendingTasks[random.nextInt(unnotifiedPendingTasks.length)];
        }
        if (pendingTaskText != null && pendingTaskText.isNotEmpty) {
          print('[Reminder] Scheduling pending task notification: $pendingTaskText');
          title = 'Pending Task Reminder';
          body = 'Don\'t forget: $pendingTaskText';
          notifiedTypes.add('pendingTask');
          notifiedTasks.add(pendingTaskText);
          await prefs.setStringList(notifiedTasksKey, notifiedTasks);
          await prefs.setString(lastTypeKey, 'pendingTask');
        } else {
          print('[Reminder] Skipping: no new pending task to notify.');
          return;
        }
      } else if (type == 'reflection') {
        final reflection = prefs.getStringList('self_reflection_$dateKey');
        if (reflection == null) {
          print('[Reminder] Scheduling reflection notification.');
          title = 'Reflection Reminder';
          body = 'Don\'t forget to complete your self-reflection today!';
          notifiedTypes.add('reflection');
          await prefs.setString(lastTypeKey, 'reflection');
        } else {
          print('[Reminder] Skipping: reflection already completed.');
          return;
        }
      } else if (type == 'missingActivity') {
        final reflection = prefs.getStringList('self_reflection_$dateKey');
        bool hasActions = false;
        if (actionsString != null) {
          final actions = List<Map<String, dynamic>>.from(json.decode(actionsString));
          hasActions = actions.isNotEmpty;
        }
        if (reflection == null || !hasActions) {
          print('[Reminder] Scheduling missing activity notification.');
          title = 'Set Your Daily Actions & Reflection';
          body = 'Plan your day by setting your actions and reflection!';
          notifiedTypes.add('missingActivity');
          await prefs.setString(lastTypeKey, 'missingActivity');
        } else {
          print('[Reminder] Skipping: both actions and reflection are set.');
          return;
        }
      }
      await prefs.setStringList(notifiedKey, notifiedTypes);
    }

    print('[Reminder] Notification scheduled: $title - $body');

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_channel',
          'Smart Reminders',
          channelDescription: 'Context-aware reminders for Blissed',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
} 

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification tap: ${response.payload}');
}

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');
  if (userId == null) {
    userId = Uuid().v4();
    await prefs.setString('user_id', userId);
  }
  return userId;
}