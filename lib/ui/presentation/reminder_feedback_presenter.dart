import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';
import '../../services/reminder_feedback.dart';

String reminderFeedbackText(
  AppLocalizations l10n,
  ReminderFeedbackCode code,
) =>
    l10n.challengeText(switch (code) {
      ReminderFeedbackCode.scheduled => 'Reminder scheduled.',
      ReminderFeedbackCode.approximate =>
        'Reminder active. Android may deliver it slightly later.',
      ReminderFeedbackCode.pending => 'Waiting to be scheduled.',
      ReminderFeedbackCode.paused => 'Paused.',
      ReminderFeedbackCode.permissionRequired =>
        'Notifications are disabled. Allow them in Android settings.',
      ReminderFeedbackCode.unsupported =>
        'Reminders are unavailable on this device.',
      ReminderFeedbackCode.timePassed =>
        'Choose a new time. The time has passed.',
      ReminderFeedbackCode.schedulingFailed =>
        'This reminder could not be scheduled. Please try again.',
      ReminderFeedbackCode.duplicate => 'This reminder is already saved.',
      ReminderFeedbackCode.savedPaused => 'Reminder saved but paused.',
    });
