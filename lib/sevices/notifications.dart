import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'policy_service.dart';

/// NotificationService — schedules reminders using ReminderPolicy’s triggerTime.
/// Expects that the app has already created the notification channel on Android.
/// This respects the `triggerTime` set by the policy and uses zoned scheduling.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final ReminderPolicy _policy;
  bool _tzReady = false;

  NotificationService({
    required FlutterLocalNotificationsPlugin notifications,
    required ReminderPolicy reminderPolicy,
  })  : _notifications = notifications,
        _policy = reminderPolicy;

  Future<void> _ensureTz() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();

    // Try to use the current system location; fall back to UTC if unknown.
    final String localName = DateTime.now().timeZoneName;
    final hasLocal = tz.timeZoneDatabase.locations.containsKey(localName);
    final tz.Location location =
        hasLocal ? tz.getLocation(localName) : tz.getLocation('UTC');
    tz.setLocalLocation(location);

    _tzReady = true;
  }

  Future<void> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
    int remindersSentToday = 0,
  }) async {
    try {
      if (!_policy.shouldSendReminder(remindersSentToday)) return;

      final result = await _policy.scheduleReminder(
        shortfallMl: shortfallMl,
        lastDrinkHoursAgo: lastDrinkHoursAgo.toDouble(),
        hydrationPercent: hydrationPercent.toDouble(),
        isActiveTime: isActiveTime,
      );

      final reminder = result.getOrElse((_) => null);
      if (reminder == null) return;

      await _ensureTz();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final whenMs =
          reminder.triggerTime <= nowMs ? nowMs + 500 : reminder.triggerTime;

      final scheduleDate =
          tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, whenMs);

      await _notifications.zonedSchedule(
        reminder.hashCode,
        'Hydrion Reminder',
        reminder.message,
        scheduleDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
              'hydration_channel', 'Hydration Reminders',
              priority: reminder.priority == 3
                  ? Priority.high
                  : Priority.defaultPriority,
              importance: reminder.priority == 3
                  ? Importance.high
                  : Importance.defaultImportance), 
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: 'hydration_reminder',
      );
    } catch (e) {
      // ignore: avoid_print 
      print('Failed to schedule notification: $e');
    }
  }
}
