import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/reminder_repository.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.watch<ReminderRepository>();
    final reminders = repository.reminders;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final notificationsEnabled = capabilities.osNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remindersTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(
                notificationsEnabled
                    ? l10n.osNotificationsCapabilityReported
                    : l10n.osNotificationsDisabledTitle,
              ),
              subtitle: Text(
                notificationsEnabled
                    ? l10n.notificationsAdapterNotWired
                    : l10n.standaloneRemindersLocalOnly,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (reminders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noLocalRemindersSaved,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.remindersEmptyDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            ...reminders.map((reminder) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(reminder.message),
                  subtitle: Text(
                    l10n.reminderSubtitle(
                      timestamp:
                          _formatTimestamp(context, reminder.triggerTime),
                      priority: reminder.priority,
                    ),
                  ),
                  trailing: IconButton(
                    key: Key('delete-reminder-${reminder.id}'),
                    tooltip: l10n.deleteLocalReminderTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await repository.delete(reminder.id);
                      if (!context.mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.localReminderDeleted),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  static String _formatTimestamp(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final dayLabel = day == today
        ? l10n.today
        : day == today.subtract(const Duration(days: 1))
            ? l10n.yesterday
            : material.formatMediumDate(local);
    final timeLabel = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return l10n.relativeDateTime(date: dayLabel, time: timeLabel);
  }
}
