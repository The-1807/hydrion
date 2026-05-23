import 'policy_service.dart';

class ScheduledReminder {
  final DateTime triggerTime;
  final String message;
  final int priority;

  const ScheduledReminder({
    required this.triggerTime,
    required this.message,
    required this.priority,
  });
}

class NotificationService {
  final ReminderPolicy _policy;
  final List<ScheduledReminder> _scheduled = <ScheduledReminder>[];

  NotificationService({required ReminderPolicy reminderPolicy})
      : _policy = reminderPolicy;

  List<ScheduledReminder> get scheduledReminders =>
      List.unmodifiable(_scheduled);

  Future<ScheduledReminder?> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
    int remindersSentToday = 0,
  }) async {
    if (!_policy.shouldSendReminder(remindersSentToday)) {
      return null;
    }

    final result = await _policy.scheduleReminder(
      shortfallMl: shortfallMl,
      lastDrinkHoursAgo: lastDrinkHoursAgo,
      hydrationPercent: hydrationPercent,
      isActiveTime: isActiveTime,
    );
    final reminder = result.getOrElse((_) => null);

    if (reminder == null) {
      return null;
    }

    final scheduled = ScheduledReminder(
      triggerTime: DateTime.fromMillisecondsSinceEpoch(reminder.triggerTime),
      message: reminder.message,
      priority: reminder.priority,
    );
    _scheduled.add(scheduled);
    return scheduled;
  }
}
