import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/reminder_feedback.dart';
import 'package:hydrion/l10n/app_localizations_en.dart';
import 'package:hydrion/l10n/app_localizations_es.dart';
import 'package:hydrion/l10n/app_localizations_fr.dart';
import 'package:hydrion/ui/presentation/reminder_feedback_presenter.dart';

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

    expect(status, ReminderFeedbackCode.timePassed);
  });

  test('schedule result maps technical failure to recovery guidance', () {
    const result = NotificationScheduleResult(
      reminder: null,
      state: ReminderScheduleState.schedulingFailed,
    );

    expect(
        ReminderFeedback.result(result), ReminderFeedbackCode.schedulingFailed);
  });

  test('typed reminder feedback localizes without leaking diagnostics', () {
    for (final l10n in [
      AppLocalizationsEn(),
      AppLocalizationsFr(),
      AppLocalizationsEs(),
    ]) {
      final text = reminderFeedbackText(
        l10n,
        ReminderFeedbackCode.schedulingFailed,
      );
      expect(text, isNot(contains('ArgumentError')));
      expect(text, isNot(contains('reminder-internal-id')));
      if (l10n.localeName != 'en') {
        expect(text,
            isNot('This reminder could not be scheduled. Please try again.'));
      }
    }
  });
}
