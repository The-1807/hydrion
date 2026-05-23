import '../repositories/reminder_repository.dart';
import 'policy_service.dart';

class NotificationService {
  final ReminderPolicy _policy;
  final ReminderRepository _reminderRepository;

  NotificationService({
    required ReminderPolicy reminderPolicy,
    ReminderRepository? reminderRepository,
  })  : _policy = reminderPolicy,
        _reminderRepository = reminderRepository ?? ReminderRepository.memory();

  List<ScheduledReminder> get scheduledReminders =>
      _reminderRepository.reminders;

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

    final scheduled = await _reminderRepository.save(
      triggerTime: DateTime.fromMillisecondsSinceEpoch(reminder.triggerTime),
      message: reminder.message,
      priority: reminder.priority,
    );
    return scheduled;
  }
}
