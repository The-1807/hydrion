import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/reminder_feedback.dart';

void main() {
  test('reminder feedback never exposes internal scheduling diagnostics', () {
    final now = DateTime(2026, 7, 23, 17, 46);
    final failed = ScheduledReminder(
      id: 'reminder-internal-id',
      triggerTime: now.subtract(const Duration(minutes: 8)),
      message: 'Hydration check-in',
      priority: 1,
      scheduleState: ReminderScheduleState.schedulingFailed,
      scheduleError: 'ArgumentError',
    );

    final status = ReminderFeedback.status(failed, now: now);

    expect(status, contains('time has passed'));
    expect(status, isNot(contains('ArgumentError')));
    expect(status, isNot(contains('failed')));
    expect(status, isNot(contains('reminder-internal-id')));
  });

  test('schedule result maps technical failure to recovery guidance', () {
    const result = NotificationScheduleResult(
      reminder: null,
      state: ReminderScheduleState.schedulingFailed,
      message: 'This reminder could not be scheduled. Please try again.',
    );

    expect(
      ReminderFeedback.result(result),
      'This reminder could not be scheduled. Please try again.',
    );
  });
}
