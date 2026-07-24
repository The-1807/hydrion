import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/reminder_repository.dart';
import '../../services/notifications.dart';
import '../../services/reminder_feedback.dart';
import '../components/hydrion_viewport.dart';

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
        key: const Key('reminders-scroll-view'),
        padding: HydrionViewport.scrollPadding(
          context,
          bottom: 104,
        ),
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
                    ? 'Local notifications available'
                    : l10n.osNotificationsDisabledTitle,
              ),
              subtitle: Text(
                notificationsEnabled
                    ? 'Hydrion schedules local, on-device reminders after you allow notification permission. Delivery still depends on OS settings, reboot handling, and battery policy.'
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderCard(
                  reminder: reminder,
                  timestamp: _formatTimestamp(context, reminder.triggerTime),
                  status: ReminderFeedback.status(reminder),
                  onEdit: () => _showReminderDialog(
                    context,
                    existing: reminder,
                  ),
                  onDelete: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context
                        .read<NotificationService>()
                        .deleteReminder(reminder.id);
                    if (!context.mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.localReminderDeleted),
                      ),
                    );
                  },
                  deleteTooltip: l10n.deleteLocalReminderTooltip,
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-reminder-button'),
        onPressed: () => _showReminderDialog(context),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Add reminder'),
      ),
    );
  }

  Future<void> _showReminderDialog(
    BuildContext context, {
    ScheduledReminder? existing,
  }) async {
    final messageController = TextEditingController(
      text: existing?.message ?? 'Time for a gentle hydration check-in.',
    );
    final minutesController = TextEditingController(
      text: existing == null
          ? '60'
          : existing.triggerTime
              .difference(DateTime.now())
              .inMinutes
              .clamp(5, 1440)
              .toString(),
    );
    final priorityController = TextEditingController(
      text: (existing?.priority ?? 1).toString(),
    );
    var enabled = existing?.enabled ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: HydrionViewport.dialogInsetPadding(dialogContext),
              scrollable: true,
              title: Text(existing == null ? 'Add reminder' : 'Edit reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('reminder-message-field'),
                    controller: messageController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Message',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('reminder-minutes-field'),
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Minutes from now',
                      helperText: 'Use 5 to 1440 minutes.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('reminder-priority-field'),
                    controller: priorityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Priority',
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    onChanged: (value) {
                      setDialogState(() => enabled = value);
                    },
                    title: const Text('Enabled'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) {
      messageController.dispose();
      minutesController.dispose();
      priorityController.dispose();
      return;
    }

    final minutes = int.tryParse(minutesController.text.trim());
    final priority = int.tryParse(priorityController.text.trim()) ?? 1;
    final message = messageController.text.trim();
    messageController.dispose();
    minutesController.dispose();
    priorityController.dispose();

    if (minutes == null || minutes < 5 || minutes > 1440 || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check reminder details and try again.')),
      );
      return;
    }

    final triggerTime = DateTime.now().add(Duration(minutes: minutes));
    final notifications = context.read<NotificationService>();
    final result = existing == null
        ? await notifications.createReminder(
            triggerTime: triggerTime,
            message: message,
            priority: priority,
            enabled: enabled,
            requestPermissionIfNeeded: true,
          )
        : await notifications.updateReminder(
            id: existing.id,
            triggerTime: triggerTime,
            message: message,
            priority: priority,
            enabled: enabled,
            requestPermissionIfNeeded: true,
          );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ReminderFeedback.result(result),
        ),
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

class _ReminderCard extends StatelessWidget {
  final ScheduledReminder reminder;
  final String timestamp;
  final String status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String deleteTooltip;

  const _ReminderCard({
    required this.reminder,
    required this.timestamp,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    required this.deleteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.message,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          timestamp,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
    final actions = <Widget>[
      IconButton(
        key: Key('edit-reminder-${reminder.id}'),
        tooltip: 'Edit reminder',
        icon: const Icon(Icons.edit_outlined),
        onPressed: onEdit,
      ),
      IconButton(
        key: Key('delete-reminder-${reminder.id}'),
        tooltip: deleteTooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    ];

    return Card(
      key: Key('reminder-card-${reminder.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = HydrionViewport.stackActions(
              context,
              availableWidth: constraints.maxWidth,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(child: copy),
                const SizedBox(width: 8),
                ...actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
