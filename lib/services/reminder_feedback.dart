import '../repositories/reminder_repository.dart';
import 'notifications.dart';

class ReminderFeedback {
  const ReminderFeedback._();

  static ReminderFeedbackCode status(
    ScheduledReminder reminder, {
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toLocal();
    final timeHasPassed = !reminder.triggerTime.toLocal().isAfter(currentTime);
    if (timeHasPassed && reminder.enabled) {
      return ReminderFeedbackCode.timePassed;
    }

    return switch (reminder.scheduleState) {
      ReminderScheduleState.scheduledExactly => ReminderFeedbackCode.scheduled,
      ReminderScheduleState.scheduledApproximately =>
        ReminderFeedbackCode.approximate,
      ReminderScheduleState.pending => ReminderFeedbackCode.pending,
      ReminderScheduleState.disabled => ReminderFeedbackCode.paused,
      ReminderScheduleState.permissionRequired =>
        ReminderFeedbackCode.permissionRequired,
      ReminderScheduleState.unsupported => ReminderFeedbackCode.unsupported,
      ReminderScheduleState.needsRescheduling =>
        ReminderFeedbackCode.timePassed,
      ReminderScheduleState.schedulingFailed =>
        ReminderFeedbackCode.schedulingFailed,
    };
  }

  static ReminderFeedbackCode result(NotificationScheduleResult result) {
    if (result.scheduled) {
      return ReminderFeedbackCode.scheduled;
    }
    if (result.duplicatePrevented) {
      return ReminderFeedbackCode.duplicate;
    }
    return switch (result.state) {
      ReminderScheduleState.permissionRequired =>
        ReminderFeedbackCode.permissionRequired,
      ReminderScheduleState.disabled => ReminderFeedbackCode.savedPaused,
      ReminderScheduleState.unsupported => ReminderFeedbackCode.unsupported,
      ReminderScheduleState.needsRescheduling =>
        ReminderFeedbackCode.timePassed,
      _ => ReminderFeedbackCode.schedulingFailed,
    };
  }
}

enum ReminderFeedbackCode {
  scheduled,
  approximate,
  pending,
  paused,
  permissionRequired,
  unsupported,
  timePassed,
  schedulingFailed,
  duplicate,
  savedPaused,
}
