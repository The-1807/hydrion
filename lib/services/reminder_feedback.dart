import '../repositories/reminder_repository.dart';
import 'notifications.dart';

class ReminderFeedback {
  const ReminderFeedback._();

  static String status(
    ScheduledReminder reminder, {
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toLocal();
    final timeHasPassed = !reminder.triggerTime.toLocal().isAfter(currentTime);
    if (timeHasPassed && reminder.enabled) {
      return 'Choose a new time. The time has passed.';
    }

    return switch (reminder.scheduleState) {
      ReminderScheduleState.scheduledExactly =>
        'Reminder active. Scheduled for the selected time.',
      ReminderScheduleState.scheduledApproximately =>
        'Reminder active. Android may deliver it slightly later.',
      ReminderScheduleState.pending => 'Waiting to be scheduled.',
      ReminderScheduleState.disabled => 'Paused.',
      ReminderScheduleState.permissionRequired =>
        'Notifications are disabled. Allow them in Android settings.',
      ReminderScheduleState.unsupported =>
        'Reminders are unavailable on this device.',
      ReminderScheduleState.needsRescheduling =>
        'Choose a new time. The time has passed.',
      ReminderScheduleState.schedulingFailed =>
        'Reminder could not be scheduled. Edit the time or try again.',
    };
  }

  static String result(NotificationScheduleResult result) {
    if (result.scheduled) {
      return 'Reminder scheduled.';
    }
    if (result.duplicatePrevented) {
      return 'This reminder is already saved.';
    }
    if (result.message != null && result.message!.trim().isNotEmpty) {
      return result.message!;
    }
    return switch (result.state) {
      ReminderScheduleState.permissionRequired =>
        'Notifications are disabled. Allow notifications in Android settings.',
      ReminderScheduleState.disabled => 'Reminder saved but paused.',
      ReminderScheduleState.unsupported =>
        'Reminders are unavailable on this device.',
      ReminderScheduleState.needsRescheduling =>
        'Choose a new time. The time has passed.',
      _ => 'This reminder could not be scheduled. Please try again.',
    };
  }
}
